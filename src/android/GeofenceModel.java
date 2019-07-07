package com.cowbell.cordova.geofence;

import com.google.android.gms.location.Geofence;
import com.google.gson.annotations.Expose;

public class GeofenceModel {
    @Expose public String id;
    @Expose public double latitude;
    @Expose public double longitude;
    @Expose public int radius;
    @Expose public int transitionType;

    public GeofenceModel() {
    }

    public Geofence toGeofence() {
        return new Geofence.Builder()
            .setRequestId(id)
            .setTransitionTypes(transitionType)
            .setCircularRegion(latitude, longitude, radius)
            .setExpirationDuration(Long.MAX_VALUE).build();
    }

    public String toJson() {
        return Gson.get().toJson(this);
    }

    public static GeofenceModel fromJson(String json) {
        if (json == null) return null;
        return Gson.get().fromJson(json, GeofenceModel.class);
    }
}
