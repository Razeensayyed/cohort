package com.oneplustvlauncher;

import android.animation.ObjectAnimator;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.hardware.display.DisplayManager;
import android.media.tv.TvInputInfo;
import android.media.tv.TvInputManager;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.palette.graphics.Palette;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.oneplustvlauncher.utils.AppInfo;
import com.oneplustvlauncher.utils.AppLoader;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class MainActivity extends AppCompatActivity {

    public static final String ACTION_REFRESH_APPS = "com.oneplustvlauncher.REFRESH_APPS";

    private Handler mClockHandler;
    private Runnable mClockRunnable;

    private TextView mTvClock, mTvDate, mTvGreeting, mTvFocusedApp;
    private TextView mBtnWifi, mBtnInputs, mBtnSettings;
    private RecyclerView mGridRecycler, mDockRecycler;
    private LinearLayout mInputsDropdown;
    private View mGlassHighlight;

    private AppGridAdapter mGridAdapter;
    private DockAdapter mDockAdapter;

    private List<AppInfo> mAllApps = new ArrayList<>();
    private List<AppInfo> mDockApps = new ArrayList<>();

    private final BroadcastReceiver mAppChangeReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            reloadApps();
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        bindViews();
        loadFont();
        startClock();
        updateWifi();
        loadApps();
        setupInputsDropdown();

        IntentFilter filter = new IntentFilter(ACTION_REFRESH_APPS);
        registerReceiver(mAppChangeReceiver, filter);
    }

    private void bindViews() {
        mTvClock       = findViewById(R.id.tv_clock);
        mTvDate        = findViewById(R.id.tv_date);
        mTvGreeting    = findViewById(R.id.tv_greeting);
        mTvFocusedApp  = findViewById(R.id.tv_focused_app);
        mBtnWifi       = findViewById(R.id.btn_wifi);
        mBtnInputs     = findViewById(R.id.btn_inputs);
        mBtnSettings   = findViewById(R.id.btn_settings);
        mGridRecycler  = findViewById(R.id.grid_recycler);
        mDockRecycler  = findViewById(R.id.dock_recycler);
        mInputsDropdown = findViewById(R.id.inputs_dropdown);
        mGlassHighlight = findViewById(R.id.glass_highlight);

        mBtnSettings.setOnClickListener(v -> openSettings());
        mBtnInputs.setOnClickListener(v -> toggleInputsDropdown());

        // Track focus on pill buttons
        View.OnFocusChangeListener pillFocus = (v, hasFocus) -> {
            v.setBackgroundResource(hasFocus ? R.drawable.bg_pill_focused : R.drawable.bg_pill);
        };
        mBtnWifi.setOnFocusChangeListener(pillFocus);
        mBtnInputs.setOnFocusChangeListener(pillFocus);
        mBtnSettings.setOnFocusChangeListener(pillFocus);
    }

    private void loadFont() {
        // Outfit font is declared in res/font/; XML references handle the assignment.
        // Nothing to do here at runtime.
    }

    // ── Clock ─────────────────────────────────────────────────────────────────

    private void startClock() {
        mClockHandler = new Handler(Looper.getMainLooper());
        mClockRunnable = new Runnable() {
            @Override
            public void run() {
                updateClock();
                mClockHandler.postDelayed(this, 1000);
            }
        };
        mClockHandler.post(mClockRunnable);
    }

    private void updateClock() {
        Date now = new Date();
        mTvClock.setText(new SimpleDateFormat("HH:mm", Locale.getDefault()).format(now));
        mTvDate.setText(new SimpleDateFormat("EEEE, d MMMM", Locale.getDefault()).format(now));

        int hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY);
        String greeting;
        if (hour < 12)      greeting = getString(R.string.greeting_morning);
        else if (hour < 17) greeting = getString(R.string.greeting_afternoon);
        else if (hour < 21) greeting = getString(R.string.greeting_evening);
        else                greeting = getString(R.string.greeting_night);
        mTvGreeting.setText(greeting);
    }

    // ── Wi-Fi ─────────────────────────────────────────────────────────────────

    private void updateWifi() {
        WifiManager wm = (WifiManager) getApplicationContext().getSystemService(WIFI_SERVICE);
        if (wm != null && wm.isWifiEnabled()) {
            WifiInfo info = wm.getConnectionInfo();
            String ssid = info.getSSID();
            if (ssid != null) {
                ssid = ssid.replace("\"", "");
                mBtnWifi.setText(ssid);
            } else {
                mBtnWifi.setText("Wi-Fi");
            }
        } else {
            mBtnWifi.setText("Wi-Fi");
        }
    }

    // ── App loading ───────────────────────────────────────────────────────────

    private void loadApps() {
        new Thread(() -> {
            List<AppInfo> all = AppLoader.loadAll(this);
            String[] dockPkgs = getResources().getStringArray(R.array.dock_apps);
            List<AppInfo> dock = new ArrayList<>();

            for (String pkg : dockPkgs) {
                AppInfo found = null;
                for (AppInfo a : all) {
                    if (a.packageName.equals(pkg)) { found = a; break; }
                }
                if (found != null) {
                    dock.add(found);
                } else {
                    // App not installed – show placeholder
                    dock.add(makePlaceholder(pkg));
                }
            }

            // Grid = everything except dock apps
            List<AppInfo> grid = new ArrayList<>();
            java.util.Set<String> dockSet = new java.util.HashSet<>();
            for (AppInfo a : dock) dockSet.add(a.packageName);
            for (AppInfo a : all) {
                if (!dockSet.contains(a.packageName)) grid.add(a);
            }

            mAllApps = all;
            mDockApps = dock;

            runOnUiThread(() -> setupAdapters(grid, dock));
        }).start();
    }

    private AppInfo makePlaceholder(String pkg) {
        return new AppInfo(pkg, getString(R.string.not_installed), null, null);
    }

    private void reloadApps() {
        loadApps();
    }

    private void setupAdapters(List<AppInfo> grid, List<AppInfo> dock) {
        int columns = getResources().getInteger(R.integer.columns);

        // Grid
        mGridAdapter = new AppGridAdapter(grid);
        mGridAdapter.setFocusListener((app, view) -> onAppFocused(app, view, false));
        mGridAdapter.setClickListener(this::launchApp);
        mGridRecycler.setLayoutManager(new GridLayoutManager(this, columns));
        mGridRecycler.setAdapter(mGridAdapter);

        // Dock
        mDockAdapter = new DockAdapter(dock);
        mDockAdapter.setFocusListener((app, view, pos) -> {
            onAppFocused(app, view, true);
            animateHighlight(view);
        });
        mDockAdapter.setClickListener(this::launchApp);
        mDockRecycler.setLayoutManager(
                new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        mDockRecycler.setAdapter(mDockAdapter);
    }

    // ── Focus & glow ──────────────────────────────────────────────────────────

    private void onAppFocused(AppInfo app, View tileView, boolean isDock) {
        mTvFocusedApp.setText(app.label);
        mTvFocusedApp.animate().alpha(isDock ? 1f : 0f).setDuration(200).start();

        // Sample dominant colour from the banner/icon for the glow
        if (app.banner instanceof android.graphics.drawable.BitmapDrawable) {
            android.graphics.Bitmap bmp =
                    ((android.graphics.drawable.BitmapDrawable) app.banner).getBitmap();
            if (bmp != null) {
                Palette.from(bmp).generate(palette -> {
                    int color = palette.getVibrantColor(
                            getColor(R.color.glow_default));
                    applyGlow(color);
                });
            }
        }
    }

    private void applyGlow(int color) {
        // Simple: tint the focused-app label with the sampled colour
        mTvFocusedApp.setTextColor(color | 0xFF000000);
    }

    private void animateHighlight(View targetView) {
        if (mGlassHighlight.getVisibility() != View.VISIBLE) {
            mGlassHighlight.setVisibility(View.VISIBLE);
            mGlassHighlight.setAlpha(0f);
        }

        // Position the highlight over the target tile
        int[] loc = new int[2];
        targetView.getLocationInWindow(loc);
        int[] dockLoc = new int[2];
        mDockRecycler.getLocationInWindow(dockLoc);

        float targetX = loc[0] - dockLoc[0];
        float targetY = loc[1] - dockLoc[1];

        if (mGlassHighlight.getWidth() == 0) {
            mGlassHighlight.getLayoutParams().width  = targetView.getWidth();
            mGlassHighlight.getLayoutParams().height = targetView.getHeight();
            mGlassHighlight.requestLayout();
        }

        ObjectAnimator.ofFloat(mGlassHighlight, View.TRANSLATION_X, targetX)
                .setDuration(180).start();
        ObjectAnimator.ofFloat(mGlassHighlight, View.TRANSLATION_Y, targetY)
                .setDuration(180).start();
        ObjectAnimator.ofFloat(mGlassHighlight, View.ALPHA, 1f)
                .setDuration(180).start();
    }

    // ── Inputs dropdown ───────────────────────────────────────────────────────

    private void setupInputsDropdown() {
        mInputsDropdown.removeAllViews();
        TvInputManager tim = (TvInputManager) getSystemService(TV_INPUT_SERVICE);
        if (tim == null) return;

        List<TvInputInfo> inputs = tim.getTvInputList();
        if (inputs.isEmpty()) {
            addInputItem("HDMI 1", null);
            addInputItem("HDMI 2", null);
            addInputItem("Live TV", null);
            return;
        }

        for (TvInputInfo info : inputs) {
            String label = info.loadLabel(this).toString();
            addInputItem(label, info.getId());
        }
    }

    private void addInputItem(String label, String inputId) {
        View item = LayoutInflater.from(this).inflate(R.layout.item_input, mInputsDropdown, false);
        ((TextView) item.findViewById(R.id.input_label)).setText(label);
        item.setOnClickListener(v -> {
            switchInput(inputId);
            mInputsDropdown.setVisibility(View.GONE);
        });
        mInputsDropdown.addView(item);
    }

    private void toggleInputsDropdown() {
        if (mInputsDropdown.getVisibility() == View.GONE) {
            setupInputsDropdown();
            mInputsDropdown.setVisibility(View.VISIBLE);
        } else {
            mInputsDropdown.setVisibility(View.GONE);
        }
    }

    private void switchInput(String inputId) {
        if (inputId == null) return;
        Intent i = new Intent(Intent.ACTION_VIEW);
        i.setData(android.media.tv.TvContract.buildChannelUri(0));
        i.putExtra("input_id", inputId);
        i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        try { startActivity(i); } catch (Exception ignored) {}
    }

    // ── App launch & Settings ─────────────────────────────────────────────────

    private void launchApp(AppInfo app) {
        PackageManager pm = getPackageManager();
        Intent i = pm.getLeanbackLaunchIntentForPackage(app.packageName);
        if (i == null) i = pm.getLaunchIntentForPackage(app.packageName);
        if (i != null) {
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(i);
        }
    }

    private void openSettings() {
        startActivity(new Intent(android.provider.Settings.ACTION_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
    }

    // ── D-pad: dismiss dropdown on Back ──────────────────────────────────────

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            if (mInputsDropdown.getVisibility() == View.VISIBLE) {
                mInputsDropdown.setVisibility(View.GONE);
                return true;
            }
        }
        return super.onKeyDown(keyCode, event);
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    @Override
    protected void onResume() {
        super.onResume();
        updateWifi();
        mDockRecycler.requestFocus();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (mClockHandler != null) mClockHandler.removeCallbacks(mClockRunnable);
        try { unregisterReceiver(mAppChangeReceiver); } catch (Exception ignored) {}
    }
}
