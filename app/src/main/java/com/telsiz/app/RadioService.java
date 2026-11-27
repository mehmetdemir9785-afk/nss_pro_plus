package com.telsiz.app;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.graphics.drawable.Icon;
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioRecord;
import android.media.AudioTrack;
import android.media.MediaRecorder;
import android.media.ToneGenerator;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.net.wifi.WifiManager;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.os.PowerManager;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.InterfaceAddress;
import java.net.NetworkInterface;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

/**
 * İnternetsiz telsiz motoru.
 * Aynı Wi-Fi / hotspot ağındaki telefonlar UDP ile birbirini bulur (ping yayını)
 * ve bas-konuş sesi 16 kHz PCM olarak gönderilir.
 */
public class RadioService extends Service {

    public static final int PORT = 50505;
    private static final int SAMPLE_RATE = 16000;
    private static final int FRAME_BYTES = 320 * 2;          // 20 ms, 16-bit mono
    private static final int HEADER = 26;
    private static final byte T_AUDIO = 0, T_END = 1, T_PING = 2;
    private static final long PING_MS = 1500, PEER_TIMEOUT_MS = 6000, RX_TIMEOUT_MS = 600;
    private static final String NOTIF_CH = "telsiz";
    private static final String ACTION_STOP = "com.telsiz.app.STOP";

    public interface Listener {
        void onUpdate();
        void onStopped();
    }

    public class LocalBinder extends Binder {
        RadioService get() { return RadioService.this; }
    }

    private static class Peer {
        volatile String name;
        volatile int channel;
        volatile InetAddress addr;
        volatile long lastSeen;
    }

    private final IBinder binder = new LocalBinder();
    private final int senderId = new Random().nextInt() | 1;
    private final Map<Integer, Peer> peers = new ConcurrentHashMap<>();
    private final Map<Integer, Integer> lastSeq = new ConcurrentHashMap<>();
    private final LinkedBlockingQueue<byte[]> playQueue = new LinkedBlockingQueue<>();

    private volatile boolean running;
    private volatile DatagramSocket socket;
    private volatile Network wifiNet;
    private volatile List<InetAddress> broadcastAddrs = new ArrayList<>();
    private volatile String netInfo = "";
    private volatile int channel = 1;
    private volatile String name = "Telsiz";
    private volatile boolean transmitting;
    private volatile int txGen;
    private volatile int rxId;
    private volatile String rxName;
    private volatile long lastRxTime;
    private volatile Listener listener;
    private int seq;

    private ConnectivityManager cm;
    private ConnectivityManager.NetworkCallback netCallback;
    private PowerManager.WakeLock wakeLock;
    private WifiManager.WifiLock wifiLock;
    private WifiManager.MulticastLock multicastLock;
    private ToneGenerator tone;

    // ---------------- Yaşam döngüsü ----------------

    @Override
    public void onCreate() {
        super.onCreate();
        running = true;

        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "telsiz:cpu");
        wakeLock.acquire();

        WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        if (wm != null) {
            @SuppressWarnings("deprecation")
            int mode = Build.VERSION.SDK_INT >= 29
                    ? WifiManager.WIFI_MODE_FULL_LOW_LATENCY
                    : WifiManager.WIFI_MODE_FULL_HIGH_PERF;
            wifiLock = wm.createWifiLock(mode, "telsiz:wifi");
            wifiLock.setReferenceCounted(false);
            wifiLock.acquire();
            multicastLock = wm.createMulticastLock("telsiz:mc");
            multicastLock.setReferenceCounted(false);
            multicastLock.acquire();
        }

        try {
            tone = new ToneGenerator(AudioManager.STREAM_MUSIC, 70);
        } catch (RuntimeException e) {
            tone = null;
        }

        refreshInterfaces();
        reopenSocket();
        watchWifi();

        new Thread(this::receiveLoop, "rx").start();
        new Thread(this::playLoop, "play").start();
        new Thread(this::housekeepingLoop, "house").start();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACTION_STOP.equals(intent.getAction())) {
            stopSelf();
            return START_NOT_STICKY;
        }
        Notification n = buildNotification();
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(1, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK);
        } else {
            startForeground(1, n);
        }
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) { return binder; }

    @Override
    public void onDestroy() {
        running = false;
        transmitting = false;
        DatagramSocket s = socket;
        socket = null;
        if (s != null) s.close();
        if (cm != null && netCallback != null) {
            try { cm.unregisterNetworkCallback(netCallback); } catch (RuntimeException ignored) { }
        }
        if (wakeLock != null && wakeLock.isHeld()) wakeLock.release();
        if (wifiLock != null && wifiLock.isHeld()) wifiLock.release();
        if (multicastLock != null && multicastLock.isHeld()) multicastLock.release();
        if (tone != null) tone.release();
        Listener l = listener;
        if (l != null) l.onStopped();
        super.onDestroy();
    }

    // ---------------- Arayüz için ----------------

    public void setListener(Listener l) { listener = l; }

    public void setName(String n) {
        String t = n == null ? "" : n.trim();
        name = t.isEmpty() ? "Telsiz" : t;
    }

    public void setChannel(int c) {
        if (c == channel) return;
        channel = c;
        endRx(false);
        playQueue.clear();
        sendPing();
        NotificationManager nm = getSystemService(NotificationManager.class);
        if (nm != null) nm.notify(1, buildNotification());
        notifyUi();
    }

    public int getChannel() { return channel; }
    public boolean isTransmitting() { return transmitting; }
    public String getRxName() { return rxName; }
    public String getNetInfo() { return netInfo; }

    public List<String> getPeerNamesOnChannel() {
        List<String> out = new ArrayList<>();
        for (Peer p : peers.values()) if (p.channel == channel) out.add(p.name);
        Collections.sort(out);
        return out;
    }

    public int getPeerCountOtherChannels() {
        int c = 0;
        for (Peer p : peers.values()) if (p.channel != channel) c++;
        return c;
    }

    public synchronized void startTx() {
        if (transmitting) return;
        transmitting = true;
        final int gen = ++txGen;
        playQueue.clear();
        beep(ToneGenerator.TONE_PROP_BEEP, 90);
        new Thread(() -> txLoop(gen), "tx").start();
        notifyUi();
    }

    public synchronized void stopTx() {
        if (!transmitting) return;
        transmitting = false;
        notifyUi();
    }

    // ---------------- Ağ ----------------

    private void watchWifi() {
        cm = getSystemService(ConnectivityManager.class);
        if (cm == null) return;
        NetworkRequest req = new NetworkRequest.Builder()
                .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build();
        netCallback = new ConnectivityManager.NetworkCallback() {
            @Override public void onAvailable(Network network) {
                wifiNet = network;
                refreshInterfaces();
                reopenSocket();
                sendPing();
            }
            @Override public void onLost(Network network) {
                if (network.equals(wifiNet)) {
                    wifiNet = null;
                    refreshInterfaces();
                    reopenSocket();
                }
            }
        };
        try {
            cm.requestNetwork(req, netCallback);
        } catch (RuntimeException e) {
            netCallback = null;
        }
    }

    /** Soketi açar; telefon bir Wi-Fi'ye bağlıysa soketi o ağa bağlar (mobil veri açık olsa bile ses Wi-Fi'den gitsin). */
    private synchronized void reopenSocket() {
        DatagramSocket old = socket;
        socket = null;
        if (old != null) old.close();
        if (!running) return;
        try {
            DatagramSocket s = new DatagramSocket(null);
            s.setReuseAddress(true);
            s.setBroadcast(true);
            s.bind(new InetSocketAddress(PORT));
            Network n = wifiNet;
            if (n != null) {
                try { n.bindSocket(s); } catch (IOException | RuntimeException ignored) { }
            }
            socket = s;
        } catch (IOException e) {
            netInfo = "Soket açılamadı: " + e.getMessage();
        }
    }

    private void refreshInterfaces() {
        List<InetAddress> bcast = new ArrayList<>();
        List<String> mine = new ArrayList<>();
        try {
            Enumeration<NetworkInterface> en = NetworkInterface.getNetworkInterfaces();
            while (en != null && en.hasMoreElements()) {
                NetworkInterface ni = en.nextElement();
                if (!ni.isUp() || ni.isLoopback()) continue;
                for (InterfaceAddress ia : ni.getInterfaceAddresses()) {
                    InetAddress a = ia.getAddress();
                    InetAddress b = ia.getBroadcast();
                    if (a instanceof Inet4Address && b != null) {
                        bcast.add(b);
                        mine.add(a.getHostAddress());
                    }
                }
            }
        } catch (IOException ignored) { }
        String info;
        if (mine.isEmpty()) {
            info = "Wi-Fi / hotspot bağlantısı yok";
            try { bcast.add(InetAddress.getByName("255.255.255.255")); } catch (IOException ignored) { }
        } else {
            info = "Ağ adresin: " + String.join(", ", mine);
        }
        if (!info.equals(netInfo)) {
            netInfo = info;
            notifyUi();
        }
        broadcastAddrs = bcast;
    }

    private byte[] packet(byte type, byte[] payload, int len) {
        byte[] p = new byte[HEADER + len];
        p[0] = 'T';
        p[1] = 'K';
        p[2] = (byte) channel;
        p[3] = type;
        int id = senderId;
        p[4] = (byte) (id >>> 24);
        p[5] = (byte) (id >>> 16);
        p[6] = (byte) (id >>> 8);
        p[7] = (byte) id;
        int s;
        synchronized (this) { s = (seq++) & 0xFFFF; }
        p[8] = (byte) (s >>> 8);
        p[9] = (byte) s;
        byte[] nb = name.getBytes(StandardCharsets.UTF_8);
        System.arraycopy(nb, 0, p, 10, Math.min(16, nb.length));
        if (len > 0) System.arraycopy(payload, 0, p, HEADER, len);
        return p;
    }

    private void sendTo(byte[] p, List<InetAddress> targets) {
        DatagramSocket s = socket;
        if (s == null) return;
        for (InetAddress a : targets) {
            try { s.send(new DatagramPacket(p, p.length, a, PORT)); } catch (IOException | RuntimeException ignored) { }
        }
    }

    /** Ses: kanaldaki bilinen kişilere doğrudan (daha güvenilir), kimse bilinmiyorsa yayın olarak. */
    private void sendVoice(byte[] p) {
        List<InetAddress> t = new ArrayList<>();
        for (Peer peer : peers.values()) if (peer.channel == channel && peer.addr != null) t.add(peer.addr);
        sendTo(p, t.isEmpty() ? broadcastAddrs : t);
    }

    private void sendPing() {
        sendTo(packet(T_PING, null, 0), broadcastAddrs);
    }

    private void receiveLoop() {
        byte[] buf = new byte[4096];
        while (running) {
            DatagramSocket s = socket;
            if (s == null) { sleep(200); continue; }
            DatagramPacket dp = new DatagramPacket(buf, buf.length);
            try {
                s.receive(dp);
            } catch (IOException | RuntimeException e) {
                if (!running) break;
                sleep(100);
                continue;
            }
            try { handle(dp); } catch (RuntimeException ignored) { }
        }
    }

    private void handle(DatagramPacket dp) {
        byte[] d = dp.getData();
        int len = dp.getLength();
        if (len < HEADER || d[0] != 'T' || d[1] != 'K') return;
        int ch = d[2] & 0xFF;
        byte type = d[3];
        int id = ((d[4] & 0xFF) << 24) | ((d[5] & 0xFF) << 16) | ((d[6] & 0xFF) << 8) | (d[7] & 0xFF);
        if (id == senderId) return;
        int sq = ((d[8] & 0xFF) << 8) | (d[9] & 0xFF);
        int nl = 0;
        while (nl < 16 && d[10 + nl] != 0) nl++;
        String who = new String(d, 10, nl, StandardCharsets.UTF_8);

        // kişi listesini güncelle
        Peer p = peers.get(id);
        boolean changed = false;
        if (p == null) { p = new Peer(); peers.put(id, p); changed = true; }
        if (p.channel != ch || !who.equals(p.name)) changed = true;
        p.name = who;
        p.channel = ch;
        p.addr = dp.getAddress();
        p.lastSeen = System.currentTimeMillis();
        if (changed) notifyUi();

        if (type == T_PING || ch != channel) return;

        // çift gelen paketleri ele
        Integer last = lastSeq.get(id);
        if (last != null && (short) (sq - last) <= 0) return;
        lastSeq.put(id, sq);

        if (type == T_AUDIO) {
            if (transmitting) return;                 // telsiz gibi: konuşurken dinlenmez
            int plen = len - HEADER;
            if (plen <= 0) return;
            byte[] pcm = new byte[plen];
            System.arraycopy(d, HEADER, pcm, 0, plen);
            lastRxTime = System.currentTimeMillis();
            if (rxId != id) {
                rxId = id;
                rxName = who.isEmpty() ? "Biri" : who;
                notifyUi();
            }
            playQueue.offer(pcm);
        } else if (type == T_END) {
            if (rxId == id) endRx(true);
        }
    }

    private synchronized void endRx(boolean withBeep) {
        if (rxId == 0) return;
        rxId = 0;
        rxName = null;
        if (withBeep) beep(ToneGenerator.TONE_PROP_ACK, 120);
        notifyUi();
    }

    private void housekeepingLoop() {
        long lastPing = 0, lastIf = 0;
        while (running) {
            long now = System.currentTimeMillis();
            if (now - lastIf > 3000) { refreshInterfaces(); lastIf = now; }
            if (now - lastPing > PING_MS) { sendPing(); lastPing = now; }
            if (rxId != 0 && now - lastRxTime > RX_TIMEOUT_MS) endRx(true);
            boolean removed = false;
            for (Map.Entry<Integer, Peer> e : peers.entrySet()) {
                if (now - e.getValue().lastSeen > PEER_TIMEOUT_MS) {
                    peers.remove(e.getKey());
                    removed = true;
                }
            }
            if (removed) notifyUi();
            sleep(200);
        }
    }

    // ---------------- Ses ----------------

    @SuppressLint("MissingPermission")
    private void txLoop(int gen) {
        int min = AudioRecord.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT);
        int size = Math.max(min, FRAME_BYTES * 8);
        AudioRecord rec = null;
        try {
            rec = new AudioRecord(MediaRecorder.AudioSource.VOICE_COMMUNICATION, SAMPLE_RATE,
                    AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, size);
            if (rec.getState() != AudioRecord.STATE_INITIALIZED) {
                rec.release();
                rec = new AudioRecord(MediaRecorder.AudioSource.MIC, SAMPLE_RATE,
                        AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, size);
            }
            if (rec.getState() != AudioRecord.STATE_INITIALIZED) throw new IllegalStateException();
            rec.startRecording();
            byte[] frame = new byte[FRAME_BYTES];
            while (transmitting && gen == txGen && running) {
                int n = 0;
                while (n < FRAME_BYTES) {
                    int r = rec.read(frame, n, FRAME_BYTES - n);
                    if (r <= 0) break;
                    n += r;
                }
                if (n == FRAME_BYTES) sendVoice(packet(T_AUDIO, frame, FRAME_BYTES));
                else sleep(5);
            }
        } catch (RuntimeException e) {
            transmitting = false;
            notifyUi();
        } finally {
            if (rec != null) {
                try { rec.stop(); } catch (RuntimeException ignored) { }
                rec.release();
            }
        }
        for (int i = 0; i < 3; i++) sendVoice(packet(T_END, null, 0));
    }

    private void playLoop() {
        int min = AudioTrack.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT);
        AudioTrack track = new AudioTrack.Builder()
                .setAudioAttributes(new AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build())
                .setAudioFormat(new AudioFormat.Builder()
                        .setSampleRate(SAMPLE_RATE)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build())
                .setBufferSizeInBytes(Math.max(min, FRAME_BYTES * 6))
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build();
        boolean playing = false;
        try {
            while (running) {
                byte[] f;
                if (!playing) {
                    f = playQueue.poll(200, TimeUnit.MILLISECONDS);
                    if (f == null) continue;
                    long t0 = System.currentTimeMillis();
                    while (playQueue.size() < 3 && System.currentTimeMillis() - t0 < 100) sleep(10); // küçük tampon
                    track.play();
                    playing = true;
                    track.write(f, 0, f.length);
                } else {
                    f = playQueue.poll(80, TimeUnit.MILLISECONDS);
                    if (f != null) {
                        while (playQueue.size() > 10) playQueue.poll();         // gecikme birikmesin
                        track.write(f, 0, f.length);
                    } else if (rxId == 0 || System.currentTimeMillis() - lastRxTime > RX_TIMEOUT_MS) {
                        track.pause();
                        track.flush();
                        playing = false;
                    }
                }
            }
        } catch (InterruptedException ignored) {
        } finally {
            try { track.stop(); } catch (RuntimeException ignored) { }
            track.release();
        }
    }

    // ---------------- Yardımcılar ----------------

    private void beep(int toneType, int ms) {
        ToneGenerator t = tone;
        if (t != null) {
            try { t.startTone(toneType, ms); } catch (RuntimeException ignored) { }
        }
    }

    private void notifyUi() {
        Listener l = listener;
        if (l != null) l.onUpdate();
    }

    private static void sleep(long ms) {
        try { Thread.sleep(ms); } catch (InterruptedException ignored) { }
    }

    private Notification buildNotification() {
        NotificationManager nm = getSystemService(NotificationManager.class);
        if (nm != null && nm.getNotificationChannel(NOTIF_CH) == null) {
            nm.createNotificationChannel(new NotificationChannel(NOTIF_CH, "Telsiz", NotificationManager.IMPORTANCE_LOW));
        }
        PendingIntent open = PendingIntent.getActivity(this, 0,
                new Intent(this, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
        PendingIntent stop = PendingIntent.getService(this, 1,
                new Intent(this, RadioService.class).setAction(ACTION_STOP),
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
        return new Notification.Builder(this, NOTIF_CH)
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .setContentTitle("Telsiz açık")
                .setContentText("Kanal " + channel + " dinleniyor")
                .setContentIntent(open)
                .setOngoing(true)
                .addAction(new Notification.Action.Builder(
                        Icon.createWithResource(this, android.R.drawable.ic_menu_close_clear_cancel),
                        "Kapat", stop).build())
                .build();
    }
}
