package com.cohort.launcher;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ObjectAnimator;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.palette.graphics.Palette;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class MainActivity extends Activity {

    private TextView tvGreeting, tvClock, tvDate, tvDockLabel;
    private RecyclerView rvGrid, rvDock;
    private View highlight;
    private LinearLayout inputsDropdown;
    private TextView pillInputs, pillWifi, pillSettings;

    private AppAdapter gridAdapter, dockAdapter;
    private List<AppInfo> gridApps  = new ArrayList<>();
    private List<AppInfo> dockApps  = new ArrayList<>();

    private final Handler clockHandler = new Handler(Looper.getMainLooper());
    private final Handler uiHandler    = new Handler(Looper.getMainLooper());

    // Last focused positions for memory-across-row navigation
    private int lastGridPos = 0;
    private int lastDockPos = 0;
    private enum Focus { TOP_BAR, GRID, DOCK }
    private Focus currentFocus = Focus.DOCK;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        tvGreeting    = findViewById(R.id.tv_greeting);
        tvClock       = findViewById(R.id.tv_clock);
        tvDate        = findViewById(R.id.tv_date);
        tvDockLabel   = findViewById(R.id.tv_dock_label);
        rvGrid        = findViewById(R.id.rv_grid);
        rvDock        = findViewById(R.id.rv_dock);
        highlight     = findViewById(R.id.highlight);
        inputsDropdown = findViewById(R.id.inputs_dropdown);
        pillInputs    = findViewById(R.id.pill_inputs);
        pillWifi      = findViewById(R.id.pill_wifi);
        pillSettings  = findViewById(R.id.pill_settings);

        int columns = getResources().getInteger(R.integer.columns);

        setupClock();
        loadApps(columns);
        setupPills();
        setupInputsDropdown();
        updateWifiLabel();
    }

    // ── Clock ────────────────────────────────────────────────────────
    private void setupClock() {
        Runnable tick = new Runnable() {
            @Override public void run() {
                updateTime();
                clockHandler.postDelayed(this, 30_000);
            }
        };
        tick.run();
    }

    private void updateTime() {
        Calendar cal = Calendar.getInstance();
        int hour = cal.get(Calendar.HOUR_OF_DAY);

        String greeting;
        if (hour < 12)       greeting = getString(R.string.greeting_morning);
        else if (hour < 17)  greeting = getString(R.string.greeting_afternoon);
        else                 greeting = getString(R.string.greeting_evening);

        tvGreeting.setText(greeting);
        tvClock.setText(new SimpleDateFormat("h:mm", Locale.getDefault()).format(new Date()));
        tvDate.setText(new SimpleDateFormat("EEEE, MMMM d", Locale.getDefault()).format(new Date()));
    }

    // ── App loading ──────────────────────────────────────────────────
    private void loadApps(int columns) {
        uiHandler.post(() -> {
            Map<String, AppInfo> all = queryAllApps();
            String[] dockPkgs = getResources().getStringArray(R.array.dock_apps);

            // dock list (ordered, only installed apps)
            for (String pkg : dockPkgs) {
                if (all.containsKey(pkg)) dockApps.add(all.get(pkg));
            }

            // grid: everything NOT in dock
            List<String> dockSet = Arrays.asList(dockPkgs);
            for (Map.Entry<String, AppInfo> e : all.entrySet()) {
                if (!dockSet.contains(e.getKey())) gridApps.add(e.getValue());
            }

            setupGrid(columns);
            setupDock(columns);
        });
    }

    private Map<String, AppInfo> queryAllApps() {
        PackageManager pm = getPackageManager();
        Intent leanback = new Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER);
        Intent regular = new Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_LAUNCHER);

        Map<String, AppInfo> result = new LinkedHashMap<>();
        List<ResolveInfo> lbApps = pm.queryIntentActivities(leanback, 0);
        List<ResolveInfo> rgApps = pm.queryIntentActivities(regular, 0);

        // prefer leanback, fall back to regular launcher entries
        List<ResolveInfo> combined = new ArrayList<>(lbApps);
        outer:
        for (ResolveInfo ri : rgApps) {
            String pkg = ri.activityInfo.packageName;
            if (pkg.equals(getPackageName())) continue;
            for (ResolveInfo lb : lbApps) {
                if (lb.activityInfo.packageName.equals(pkg)) continue outer;
            }
            combined.add(ri);
        }

        for (ResolveInfo ri : combined) {
            String pkg = ri.activityInfo.packageName;
            if (pkg.equals(getPackageName())) continue;
            String label = ri.loadLabel(pm).toString();
            Drawable banner = ri.activityInfo.loadBanner(pm);
            if (banner == null) {
                try { banner = pm.getApplicationBanner(pkg); } catch (Exception ignored) {}
            }
            Drawable icon = ri.loadIcon(pm);
            result.put(pkg, new AppInfo(pkg, label, banner, icon));
        }
        return result;
    }

    private void setupGrid(int columns) {
        gridAdapter = new AppAdapter(this, gridApps, true);
        rvGrid.setLayoutManager(new GridLayoutManager(this, columns));
        rvGrid.setAdapter(gridAdapter);
        gridAdapter.setOnAppClicked(app -> launchApp(app.packageName));
        gridAdapter.setOnAppFocused((app, tile) -> {
            currentFocus = Focus.GRID;
            animateHighlight(tile);
            updateDockLabelForApp(app);
        });
    }

    private void setupDock(int columns) {
        dockAdapter = new AppAdapter(this, dockApps, false);
        LinearLayoutManager llm = new LinearLayoutManager(this,
                LinearLayoutManager.HORIZONTAL, false);
        rvDock.setLayoutManager(llm);
        rvDock.setAdapter(dockAdapter);
        dockAdapter.setOnAppClicked(app -> launchApp(app.packageName));
        dockAdapter.setOnAppFocused((app, tile) -> {
            currentFocus = Focus.DOCK;
            animateHighlight(tile);
            tvDockLabel.setText(app.label);
            applyAmbientGlow(app);
        });

        // Start focus on dock
        rvDock.requestFocus();
    }

    // ── Highlight animation ──────────────────────────────────────────
    private View lastHighlightTarget = null;

    private void animateHighlight(View target) {
        if (target == null) return;
        highlight.setVisibility(View.VISIBLE);

        int[] loc = new int[2];
        target.getLocationInWindow(loc);

        float destX = loc[0];
        float destY = loc[1];

        if (lastHighlightTarget == null) {
            highlight.setX(destX);
            highlight.setY(destY);
            ViewGroup.LayoutParams lp = highlight.getLayoutParams();
            lp.width = target.getWidth();
            lp.height = target.getHeight();
            highlight.setLayoutParams(lp);
        } else {
            ObjectAnimator.ofFloat(highlight, "x", highlight.getX(), destX)
                    .setDuration(180).start();
            ObjectAnimator.ofFloat(highlight, "y", highlight.getY(), destY)
                    .setDuration(180).start();
            ViewGroup.LayoutParams lp = highlight.getLayoutParams();
            lp.width  = target.getWidth();
            lp.height = target.getHeight();
            highlight.setLayoutParams(lp);
        }
        lastHighlightTarget = target;
    }

    // ── Ambient glow (Palette from banner) ──────────────────────────
    private void applyAmbientGlow(AppInfo app) {
        // Nothing heavy: just set dock label color based on the banner/icon dominant colour
        Drawable d = app.banner != null ? app.banner : app.icon;
        if (d == null) return;
        // Run palette on a small bitmap asynchronously
        uiHandler.post(() -> {
            android.graphics.Bitmap bmp;
            try {
                bmp = android.graphics.Bitmap.createBitmap(
                        d.getIntrinsicWidth() > 0 ? Math.min(d.getIntrinsicWidth(), 100) : 100,
                        d.getIntrinsicHeight() > 0 ? Math.min(d.getIntrinsicHeight(), 100) : 100,
                        android.graphics.Bitmap.Config.ARGB_8888);
                android.graphics.Canvas c = new android.graphics.Canvas(bmp);
                d.setBounds(0, 0, bmp.getWidth(), bmp.getHeight());
                d.draw(c);
            } catch (Exception e) { return; }
            Palette.from(bmp).generate(p -> {
                int swatch = p.getLightVibrantColor(
                            p.getVibrantColor(Color.WHITE));
                tvDockLabel.setTextColor(swatch);
                // simple shadow to simulate glow
                tvDockLabel.setShadowLayer(24f, 0, 0, swatch & 0x88FFFFFF);
            });
        });
    }

    private void updateDockLabelForApp(AppInfo app) {
        tvDockLabel.setText(app.label);
    }

    // ── Pills ────────────────────────────────────────────────────────
    private void setupPills() {
        View.OnFocusChangeListener pillFocus = (v, hasFocus) -> {
            if (hasFocus) currentFocus = Focus.TOP_BAR;
            v.setBackground(hasFocus
                    ? getDrawable(R.drawable.bg_pill_focused)
                    : getDrawable(R.drawable.bg_pill));
        };
        pillInputs.setOnFocusChangeListener(pillFocus);
        pillWifi.setOnFocusChangeListener(pillFocus);
        pillSettings.setOnFocusChangeListener(pillFocus);

        pillSettings.setOnClickListener(v -> startActivity(
                new Intent(Settings.ACTION_SETTINGS)));
        pillInputs.setOnClickListener(v -> toggleInputsDropdown());
        pillWifi.setOnClickListener(v -> startActivity(
                new Intent(Settings.ACTION_WIFI_SETTINGS)));
    }

    private void updateWifiLabel() {
        try {
            WifiManager wm = (WifiManager) getApplicationContext()
                    .getSystemService(Context.WIFI_SERVICE);
            WifiInfo info = wm.getConnectionInfo();
            String ssid = info.getSSID().replace("\"", "");
            pillWifi.setText(ssid.isEmpty() ? getString(R.string.wifi) : ssid);
        } catch (Exception ignored) {
            pillWifi.setText(getString(R.string.wifi));
        }
    }

    // ── Inputs dropdown ──────────────────────────────────────────────
    private void setupInputsDropdown() {
        String[] sources = {"HDMI 1", "HDMI 2", "HDMI 3", "AV", "Live TV"};
        for (String src : sources) {
            TextView tv = new TextView(this);
            tv.setText(src);
            tv.setTextColor(Color.WHITE);
            tv.setTextSize(14);
            tv.setPadding(24, 16, 24, 16);
            tv.setFocusable(true);
            tv.setOnClickListener(v -> {
                Intent intent = new Intent("android.intent.action.MAIN");
                intent.addCategory("android.intent.category.TV_INPUT");
                try { startActivity(intent); } catch (Exception ignored) {}
                inputsDropdown.setVisibility(View.GONE);
            });
            inputsDropdown.addView(tv);
        }
    }

    private void toggleInputsDropdown() {
        if (inputsDropdown.getVisibility() == View.VISIBLE) {
            inputsDropdown.setVisibility(View.GONE);
        } else {
            inputsDropdown.setVisibility(View.VISIBLE);
        }
    }

    // ── Launch ───────────────────────────────────────────────────────
    private void launchApp(String pkg) {
        PackageManager pm = getPackageManager();
        Intent i = pm.getLeanbackLaunchIntentForPackage(pkg);
        if (i == null) i = pm.getLaunchIntentForPackage(pkg);
        if (i != null) startActivity(i);
    }

    // ── D-pad routing ────────────────────────────────────────────────
    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        switch (keyCode) {
            case KeyEvent.KEYCODE_DPAD_UP:
                if (currentFocus == Focus.DOCK) {
                    currentFocus = Focus.GRID;
                    rvGrid.requestFocus();
                    return true;
                } else if (currentFocus == Focus.GRID) {
                    // If we're in the first row of the grid, go to top bar
                    GridLayoutManager glm = (GridLayoutManager) rvGrid.getLayoutManager();
                    if (glm != null && gridAdapter.getFocusedPos() < getResources().getInteger(R.integer.columns)) {
                        currentFocus = Focus.TOP_BAR;
                        pillSettings.requestFocus();
                        return true;
                    }
                }
                break;
            case KeyEvent.KEYCODE_DPAD_DOWN:
                if (currentFocus == Focus.TOP_BAR) {
                    currentFocus = Focus.GRID;
                    rvGrid.requestFocus();
                    return true;
                } else if (currentFocus == Focus.GRID) {
                    // Near bottom of grid → go to dock
                    GridLayoutManager glm = (GridLayoutManager) rvGrid.getLayoutManager();
                    if (glm != null) {
                        int last = gridApps.size() - 1;
                        int cols = getResources().getInteger(R.integer.columns);
                        if (gridAdapter.getFocusedPos() >= last - cols) {
                            currentFocus = Focus.DOCK;
                            rvDock.requestFocus();
                            return true;
                        }
                    }
                }
                break;
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateWifiLabel();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        clockHandler.removeCallbacksAndMessages(null);
        uiHandler.removeCallbacksAndMessages(null);
    }
}
