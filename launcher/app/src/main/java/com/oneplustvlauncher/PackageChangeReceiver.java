package com.oneplustvlauncher;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class PackageChangeReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        // MainActivity listens for this locally; the broadcast is just a signal.
        Intent refresh = new Intent(MainActivity.ACTION_REFRESH_APPS);
        context.sendBroadcast(refresh);
    }
}
