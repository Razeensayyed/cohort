package com.oneplustvlauncher;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.media.tv.TvInputInfo;
import android.media.tv.TvInputManager;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
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
    private Handler mHideHandler;
    private Runnable mHidePanel;

    private TextView mTvClock, mTvAmPm, mTvDate, mTvGreeting, mTvFocusedApp;
    private ImageView mBtnWifi, mBtnInputs, mBtnSettings;
    private RecyclerView mDockRecycler, mMoreRecycler;
    private LinearLayout mInputsDropdown;
    private View mMoreBtn, mMorePanel;

    private DockAdapter mDockAdapter;
    private NavAdapter mNavAdapter;

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
        setupHideHandler();

        IntentFilter filter = new IntentFilter(ACTION_REFRESH_APPS);
        registerReceiver(mAppChangeReceiver, filter);
    }

    private void bindViews() {
        mTvClock       = findViewById(R.id.tv_clock);
        mTvAmPm        = findViewById(R.id.tv_ampm);
        mTvDate        = findViewById(R.id.tv_date);
        mTvGreeting    = findViewById(R.id.tv_greeting);

        // Force Latin digit rendering regardless of system locale
        mTvClock.setTextLocale(java.util.Locale.ENGLISH);
        mTvAmPm.setTextLocale(java.util.Locale.ENGLISH);
        mTvDate.setTextLocale(java.util.Locale.ENGLISH);
        mTvGreeting.setTextLocale(java.util.Locale.ENGLISH);
        mTvClock.setTypeface(android.graphics.Typeface.DEFAULT);
        mTvFocusedApp  = findViewById(R.id.tv_focused_app);
        mBtnWifi       = (ImageView) findViewById(R.id.btn_wifi);
        mBtnInputs     = (ImageView) findViewById(R.id.btn_inputs);
        mBtnSettings   = (ImageView) findViewById(R.id.btn_settings);
        mDockRecycler  = findViewById(R.id.dock_recycler);
        mMoreRecycler  = findViewById(R.id.more_recycler);
        mMoreBtn       = findViewById(R.id.more_btn);
        mMorePanel     = findViewById(R.id.more_panel);
        mInputsDropdown = findViewById(R.id.inputs_dropdown);

        mBtnSettings.setOnClickListener(v -> openSettings());
        mBtnInputs.setOnClickListener(v -> toggleInputsDropdown());
        mMoreBtn.setOnClickListener(v -> toggleMorePanel());

        View.OnFocusChangeListener pillFocus = (v, hasFocus) -> {
            v.setBackgroundResource(hasFocus ? R.drawable.bg_pill_focused : R.drawable.bg_pill);
        };
        mBtnWifi.setOnFocusChangeListener(pillFocus);
        mBtnInputs.setOnFocusChangeListener(pillFocus);
        mBtnSettings.setOnFocusChangeListener(pillFocus);

        mMoreBtn.setOnFocusChangeListener((v, hasFocus) -> {
            v.setBackgroundResource(hasFocus ? R.drawable.bg_pill_focused : R.drawable.bg_pill);
            if (!hasFocus && mMorePanel.getVisibility() == View.VISIBLE) {
                scheduleHidePanel();
            }
        });
    }

    private void loadFont() {
        // Outfit font is declared in res/font/; XML references handle the assignment.
    }

    // ── More panel ────────────────────────────────────────────────────────────

    private void setupHideHandler() {
        mHideHandler = new Handler(Looper.getMainLooper());
        mHidePanel = () -> mMorePanel.setVisibility(View.GONE);
    }

    private void showMorePanel() {
        cancelHidePanel();
        mMorePanel.setVisibility(View.VISIBLE);
    }

    private void toggleMorePanel() {
        if (mMorePanel.getVisibility() == View.VISIBLE) {
            mMorePanel.setVisibility(View.GONE);
        } else {
            showMorePanel();
        }
    }

    private void scheduleHidePanel() {
        mHideHandler.removeCallbacks(mHidePanel);
        mHideHandler.postDelayed(mHidePanel, 500);
    }

    private void cancelHidePanel() {
        mHideHandler.removeCallbacks(mHidePanel);
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
        Calendar cal = Calendar.getInstance();
        int hour24 = cal.get(Calendar.HOUR_OF_DAY);
        int hour12 = cal.get(Calendar.HOUR);
        if (hour12 == 0) hour12 = 12;
        int minute = cal.get(Calendar.MINUTE);
        boolean isAm = cal.get(Calendar.AM_PM) == Calendar.AM;

        // String.format with Locale.ENGLISH guarantees ASCII digits regardless of system locale
        mTvClock.setText(String.format(Locale.ENGLISH, "%d:%02d", hour12, minute));
        mTvAmPm.setText(isAm ? "AM" : "PM");
        mTvDate.setText(new SimpleDateFormat("EEEE, d MMMM", Locale.ENGLISH)
                .format(cal.getTime()).toUpperCase(Locale.ENGLISH));

        String greeting;
        if (hour24 < 12)      greeting = getString(R.string.greeting_morning);
        else if (hour24 < 17) greeting = getString(R.string.greeting_afternoon);
        else if (hour24 < 21) greeting = getString(R.string.greeting_evening);
        else                  greeting = getString(R.string.greeting_night);
        mTvGreeting.setText(greeting.toUpperCase(Locale.ENGLISH));
    }

    // ── Wi-Fi ─────────────────────────────────────────────────────────────────

    private void updateWifi() {
        WifiManager wm = (WifiManager) getApplicationContext().getSystemService(WIFI_SERVICE);
        boolean connected = wm != null && wm.isWifiEnabled();
        mBtnWifi.setImageResource(connected ? R.drawable.ic_wifi_on : R.drawable.ic_wifi_off);
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
        // Dock
        mDockAdapter = new DockAdapter(dock);
        mDockAdapter.setFocusListener((app, view, pos) -> onAppFocused(app, view, true));
        mDockAdapter.setClickListener(this::launchApp);
        mDockRecycler.setLayoutManager(
                new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        mDockRecycler.setAdapter(mDockAdapter);

        // More panel (all non-dock apps)
        mNavAdapter = new NavAdapter(grid);
        mNavAdapter.setClickListener(app -> {
            mMorePanel.setVisibility(View.GONE);
            launchApp(app);
        });
        mNavAdapter.setFocusListener(hasFocus -> {
            if (hasFocus) {
                cancelHidePanel();
            } else {
                scheduleHidePanel();
            }
        });
        mMoreRecycler.setLayoutManager(
                new GridLayoutManager(this, 6));
        mMoreRecycler.setAdapter(mNavAdapter);
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
        // glass highlight removed; no-op
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
            if (mMorePanel.getVisibility() == View.VISIBLE) {
                mMorePanel.setVisibility(View.GONE);
                return true;
            }
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
