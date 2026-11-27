package com.telsiz.app;

import android.Manifest;
import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.text.Editable;
import android.text.InputFilter;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends Activity implements RadioService.Listener {

    private static final int MAX_CHANNEL = 16;
    private static final int C_BG = 0xFF0F1A24, C_CARD = 0xFF1B2A38, C_IDLE = 0xFF2D6CDF,
            C_TX = 0xFFE53935, C_RX = 0xFF2E9E5B, C_TEXT = 0xFFECEFF1, C_DIM = 0xFF90A4AE;

    private RadioService radio;
    private boolean bound;
    private SharedPreferences prefs;
    private int channel;
    private String lastRx;

    private TextView netText, channelText, peersText, pttText, hintText;
    private EditText nameEdit;
    private CheckBox toggleMode;
    private GradientDrawable pttBg;

    private final ServiceConnection conn = new ServiceConnection() {
        @Override public void onServiceConnected(ComponentName n, IBinder b) {
            radio = ((RadioService.LocalBinder) b).get();
            radio.setName(nameEdit.getText().toString());
            radio.setChannel(channel);
            radio.setListener(MainActivity.this);
            refresh();
        }
        @Override public void onServiceDisconnected(ComponentName n) {
            radio = null;
            refresh();
        }
    };

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        prefs = getSharedPreferences("telsiz", MODE_PRIVATE);
        channel = prefs.getInt("channel", 1);
        buildUi();
        if (hasMic()) startRadio();
        else askPermissions();
    }

    @Override
    protected void onDestroy() {
        if (radio != null) radio.setListener(null);
        if (bound) { unbindService(conn); bound = false; }
        super.onDestroy();
    }

    // ---------------- İzinler / servis ----------------

    private boolean hasMic() {
        return checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED;
    }

    private void askPermissions() {
        List<String> p = new ArrayList<>();
        p.add(Manifest.permission.RECORD_AUDIO);
        if (Build.VERSION.SDK_INT >= 33) p.add(Manifest.permission.POST_NOTIFICATIONS);
        requestPermissions(p.toArray(new String[0]), 1);
    }

    @Override
    public void onRequestPermissionsResult(int code, String[] perms, int[] results) {
        if (hasMic()) startRadio();
        else hintText.setText("Telsizin çalışması için mikrofon izni gerekli. Uygulamayı yeniden açıp izin ver.");
    }

    private void startRadio() {
        Intent i = new Intent(this, RadioService.class);
        startForegroundService(i);
        bound = bindService(i, conn, Context.BIND_AUTO_CREATE);
    }

    // ---------------- Servisten gelen olaylar ----------------

    @Override public void onUpdate() { runOnUiThread(this::refresh); }

    @Override public void onStopped() { runOnUiThread(this::finish); }

    private void refresh() {
        channelText.setText("Kanal " + channel);
        if (radio == null) {
            netText.setText("Başlatılıyor…");
            return;
        }
        netText.setText(radio.getNetInfo());

        List<String> names = radio.getPeerNamesOnChannel();
        int others = radio.getPeerCountOtherChannels();
        String s = names.isEmpty()
                ? "Bu kanalda henüz kimse yok"
                : "Bu kanalda (" + names.size() + "): " + String.join(", ", names);
        if (others > 0) s += "\nDiğer kanallarda " + others + " kişi var";
        peersText.setText(s);

        String rx = radio.getRxName();
        if (radio.isTransmitting()) {
            pttBg.setColor(C_TX);
            pttText.setText("KONUŞUYORSUN");
        } else if (rx != null) {
            pttBg.setColor(C_RX);
            pttText.setText(rx + "\nkonuşuyor");
        } else {
            pttBg.setColor(C_IDLE);
            pttText.setText(toggleMode.isChecked() ? "DOKUN\nKONUŞ" : "BASILI TUT\nKONUŞ");
        }
        if (rx != null && !rx.equals(lastRx)) vibrate(40);
        lastRx = rx;
    }

    // ---------------- Arayüz ----------------

    private int dp(int v) { return Math.round(v * getResources().getDisplayMetrics().density); }

    private TextView text(String s, int sp, int color) {
        TextView t = new TextView(this);
        t.setText(s);
        t.setTextSize(sp);
        t.setTextColor(color);
        return t;
    }

    private Button smallButton(String s) {
        Button b = new Button(this);
        b.setText(s);
        b.setTextSize(22);
        b.setTextColor(C_TEXT);
        GradientDrawable g = new GradientDrawable();
        g.setColor(C_CARD);
        g.setCornerRadius(dp(14));
        b.setBackground(g);
        return b;
    }

    private void buildUi() {
        getWindow().setStatusBarColor(C_BG);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(20), dp(20), dp(20), dp(24));
        root.setGravity(Gravity.CENTER_HORIZONTAL);

        TextView title = text("📻 Telsiz", 28, C_TEXT);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        root.addView(title);

        netText = text("", 13, C_DIM);
        netText.setGravity(Gravity.CENTER);
        root.addView(netText);

        // İsim
        nameEdit = new EditText(this);
        nameEdit.setSingleLine(true);
        nameEdit.setHint("Adın");
        nameEdit.setHintTextColor(C_DIM);
        nameEdit.setTextColor(C_TEXT);
        nameEdit.setGravity(Gravity.CENTER);
        nameEdit.setFilters(new InputFilter[]{new InputFilter.LengthFilter(14)});
        nameEdit.setText(prefs.getString("name", Build.MODEL));
        nameEdit.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int a, int b, int c) { }
            @Override public void onTextChanged(CharSequence s, int a, int b, int c) { }
            @Override public void afterTextChanged(Editable e) {
                prefs.edit().putString("name", e.toString()).apply();
                if (radio != null) radio.setName(e.toString());
            }
        });
        LinearLayout.LayoutParams nlp = new LinearLayout.LayoutParams(dp(240), LinearLayout.LayoutParams.WRAP_CONTENT);
        nlp.topMargin = dp(16);
        root.addView(nameEdit, nlp);

        // Kanal seçici
        LinearLayout chRow = new LinearLayout(this);
        chRow.setOrientation(LinearLayout.HORIZONTAL);
        chRow.setGravity(Gravity.CENTER_VERTICAL);
        Button minus = smallButton("−");
        Button plus = smallButton("+");
        channelText = text("", 24, C_TEXT);
        channelText.setTypeface(Typeface.DEFAULT_BOLD);
        channelText.setGravity(Gravity.CENTER);
        minus.setOnClickListener(v -> changeChannel(-1));
        plus.setOnClickListener(v -> changeChannel(+1));
        chRow.addView(minus, new LinearLayout.LayoutParams(dp(64), dp(56)));
        chRow.addView(channelText, new LinearLayout.LayoutParams(dp(150), LinearLayout.LayoutParams.WRAP_CONTENT));
        chRow.addView(plus, new LinearLayout.LayoutParams(dp(64), dp(56)));
        LinearLayout.LayoutParams clp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        clp.topMargin = dp(12);
        root.addView(chRow, clp);

        peersText = text("", 15, C_TEXT);
        peersText.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams plp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        plp.topMargin = dp(14);
        root.addView(peersText, plp);

        // Bas-konuş düğmesi
        pttBg = new GradientDrawable();
        pttBg.setShape(GradientDrawable.OVAL);
        pttBg.setColor(C_IDLE);
        pttBg.setStroke(dp(6), 0x33FFFFFF);
        pttText = text("", 24, Color.WHITE);
        pttText.setTypeface(Typeface.DEFAULT_BOLD);
        pttText.setGravity(Gravity.CENTER);
        pttText.setBackground(pttBg);
        pttText.setOnTouchListener(this::onPttTouch);
        LinearLayout.LayoutParams blp = new LinearLayout.LayoutParams(dp(250), dp(250));
        blp.topMargin = dp(22);
        root.addView(pttText, blp);

        toggleMode = new CheckBox(this);
        toggleMode.setText("Eller serbest (dokun: aç / tekrar dokun: kapat)");
        toggleMode.setTextColor(C_DIM);
        toggleMode.setChecked(prefs.getBoolean("toggle", false));
        toggleMode.setOnCheckedChangeListener((b, on) -> {
            prefs.edit().putBoolean("toggle", on).apply();
            if (!on && radio != null) radio.stopTx();
            refresh();
        });
        LinearLayout.LayoutParams tlp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        tlp.topMargin = dp(14);
        root.addView(toggleMode, tlp);

        hintText = text(
                "Nasıl kullanılır?\n" +
                "1) Bir telefon Ayarlar'dan Mobil Erişim Noktası (hotspot) açsın. İnternet/mobil veri gerekmez.\n" +
                "2) Diğerleri o Wi-Fi'ye bağlansın. \"İnternet yok\" uyarısı çıkarsa \"Yine de bağlı kal\" deyin.\n" +
                "3) Herkes bu uygulamayı açıp aynı kanalı seçsin.\n" +
                "Uygulamayı arka plana atınca da dinlemeye devam eder. Kapatmak için aşağıdaki düğmeyi ya da bildirimdeki \"Kapat\"ı kullan.\n" +
                "Menzil: hotspot telefonundan açık alanda yaklaşık 50–100 m.",
                13, C_DIM);
        LinearLayout.LayoutParams hlp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        hlp.topMargin = dp(18);
        root.addView(hintText, hlp);

        Button quit = smallButton("Telsizi kapat");
        quit.setTextSize(16);
        quit.setOnClickListener(v -> {
            if (radio != null) radio.setListener(null);
            if (bound) { unbindService(conn); bound = false; }
            stopService(new Intent(this, RadioService.class));
            finish();
        });
        LinearLayout.LayoutParams qlp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, dp(48));
        qlp.topMargin = dp(16);
        root.addView(quit, qlp);

        ScrollView sv = new ScrollView(this);
        sv.setBackgroundColor(C_BG);
        sv.setFillViewport(true);
        sv.addView(root);
        setContentView(sv);
        refresh();
    }

    private boolean onPttTouch(View v, MotionEvent e) {
        if (radio == null) return true;
        int a = e.getActionMasked();
        if (toggleMode.isChecked()) {
            if (a == MotionEvent.ACTION_DOWN) {
                if (radio.isTransmitting()) radio.stopTx(); else radio.startTx();
                vibrate(25);
            }
        } else {
            if (a == MotionEvent.ACTION_DOWN) {
                v.getParent().requestDisallowInterceptTouchEvent(true);  // kaydırma düğmeyi bırakmasın
                radio.startTx();
                vibrate(25);
            } else if (a == MotionEvent.ACTION_UP || a == MotionEvent.ACTION_CANCEL) {
                radio.stopTx();
            }
        }
        return true;
    }

    private void changeChannel(int d) {
        channel = ((channel - 1 + d + MAX_CHANNEL) % MAX_CHANNEL) + 1;
        prefs.edit().putInt("channel", channel).apply();
        if (radio != null) radio.setChannel(channel);
        refresh();
    }

    @SuppressWarnings("deprecation")
    private void vibrate(int ms) {
        Vibrator vib = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);
        if (vib == null || !vib.hasVibrator()) return;
        vib.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE));
    }
}
