package com.cowbell.cordova.geofence;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class BootReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        GeofenceManager manager = new GeofenceManager(context);
        manager.loadFromStorageAndInitializeGeofences();

        Log.d("geofence", "Geofences added after device booted");
    }
}