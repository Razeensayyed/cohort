package com.oneplustvlauncher;

import android.app.Application;

public class LauncherApplication extends Application {

    private static LauncherApplication sInstance;

    @Override
    public void onCreate() {
        super.onCreate();
        sInstance = this;
    }

    public static LauncherApplication getInstance() {
        return sInstance;
    }
}
