package com.oneplustvlauncher.utils;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class AppLoader {

    public static List<AppInfo> loadAll(Context ctx) {
        PackageManager pm = ctx.getPackageManager();
        List<AppInfo> result = new ArrayList<>();

        // Query LEANBACK_LAUNCHER first (TV apps), then fall back to standard LAUNCHER
        Intent leanback = new Intent(Intent.ACTION_MAIN);
        leanback.addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER);
        List<ResolveInfo> leanbackApps = pm.queryIntentActivities(leanback, 0);

        Intent launcher = new Intent(Intent.ACTION_MAIN);
        launcher.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> launcherApps = pm.queryIntentActivities(launcher, 0);

        // Merge: prefer leanback entries, add launcher-only entries not already in the set
        java.util.Set<String> seen = new java.util.HashSet<>();
        List<ResolveInfo> combined = new ArrayList<>(leanbackApps);
        for (ResolveInfo r : launcherApps) {
            String pkg = r.activityInfo.packageName;
            boolean inLeanback = false;
            for (ResolveInfo lb : leanbackApps) {
                if (lb.activityInfo.packageName.equals(pkg)) { inLeanback = true; break; }
            }
            if (!inLeanback) combined.add(r);
        }

        for (ResolveInfo ri : combined) {
            String pkg = ri.activityInfo.packageName;
            if (seen.contains(pkg)) continue;
            seen.add(pkg);

            // Skip ourselves
            if (pkg.equals(ctx.getPackageName())) continue;

            String label = ri.loadLabel(pm).toString();
            android.graphics.drawable.Drawable icon = ri.loadIcon(pm);
            android.graphics.drawable.Drawable banner = null;
            try {
                banner = pm.getApplicationBanner(pkg);
            } catch (PackageManager.NameNotFoundException ignored) {}
            if (banner == null) banner = icon;

            result.add(new AppInfo(pkg, label, icon, banner));
        }

        Collections.sort(result, (a, b) -> a.label.compareToIgnoreCase(b.label));
        return result;
    }
}
