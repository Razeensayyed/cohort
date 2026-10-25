package com.cohort.launcher;

import android.graphics.drawable.Drawable;

public class AppInfo {
    public final String packageName;
    public final String label;
    public final Drawable banner;   // may be null → falls back to icon
    public final Drawable icon;

    public AppInfo(String packageName, String label, Drawable banner, Drawable icon) {
        this.packageName = packageName;
        this.label = label;
        this.banner = banner;
        this.icon = icon;
    }
}
