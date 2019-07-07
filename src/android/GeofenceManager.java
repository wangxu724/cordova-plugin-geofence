package com.cowbell.cordova.geofence;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

import com.google.android.gms.location.Geofence;
import com.google.android.gms.location.GeofencingClient;
import com.google.android.gms.location.GeofencingRequest;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;

import org.apache.cordova.CallbackContext;

import java.util.ArrayList;
import java.util.List;

public class GeofenceManager {
    private Context context;
    private GeofenceModelStore geofenceModelStore;
    private List<Geofence> geoFences;
    private PendingIntent pendingIntent;
    private GeofencingClient geofencingClient;

    public GeofenceManager(Context context) {
        this.context = context;
        geofenceModelStore = new GeofenceModelStore(context);
        pendingIntent = getGeofencePendingIntent();
        geofencingClient = LocationServices.getGeofencingClient(context);
    }

    public void loadFromStorageAndInitializeGeofences() {
        List<GeofenceModel> geofenceModels = geofenceModelStore.getAll();

        if (!geofenceModels.isEmpty()) {
            addOrUpdate(geofenceModels, null);
        }
    }

    public List<GeofenceModel> getWatched() {
        List<GeofenceModel> geofenceModels = geofenceModelStore.getAll();
        return geofenceModels;
    }

    public void addOrUpdate(List<GeofenceModel> geofenceModels,
                                    @Nullable final CallbackContext callback) {
        try {
            geofencingClient.addGeofences(getGeofencingRequest(geofenceModels), pendingIntent)
                .addOnSuccessListener(new OnSuccessListener<Void>() {
                    @Override
                    public void onSuccess(Void aVoid) {
                        for (GeofenceModel geo : geofenceModels) {
                            geofenceModelStore.setGeofenceModel(geo);
                        }
                        if (callback != null) {
                            callback.success();
                        }
                    }
                })
                .addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception ex) {
                        if (callback != null) {
                            callback.error(ex.getMessage());
                        }
                    }
                });
        }
        catch (SecurityException ex) {
            if (callback != null) {
                callback.error(ex.getMessage());
            }
        }
    }

    public void remove(List<String> ids, final CallbackContext callback) {
        if (ids != null && !ids.isEmpty()) {
            try {
                 geofencingClient.removeGeofences(ids)
                        .addOnSuccessListener(new OnSuccessListener<Void>() {
                            @Override
                            public void onSuccess(Void aVoid) {
                                for (String id : ids) {
                                    geofenceModelStore.remove(id);
                                }
                                if (callback != null) {
                                    callback.success();
                                }
                            }
                        })
                        .addOnFailureListener(new OnFailureListener() {
                            @Override
                            public void onFailure(@NonNull Exception ex) {
                                if (callback != null) {
                                    callback.error(ex.getMessage());
                                }
                            }
                        });
            }
            catch (SecurityException ex) {
                if (callback != null) {
                    callback.error(ex.getMessage());
                }
            }
        }
    }

    public void removeAll(final CallbackContext callback) {
        List<GeofenceModel> geofenceModels = geofenceModelStore.getAll();
        List<String> geofenceIds = new ArrayList<String>();
        for (GeofenceModel geo : geofenceModels) {
            geofenceIds.add(geo.id);
        }
        remove(geofenceIds, callback);
    }

    private PendingIntent getGeofencePendingIntent() {
        Intent intent = new Intent(context, GeofencingEventIntentReceiver.class);
        return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);
    }

    private GeofencingRequest getGeofencingRequest(List<GeofenceModel> geofenceModels) {
        List<Geofence> newGeofences = new ArrayList<Geofence>();
        for (GeofenceModel geo : geofenceModels) {
            newGeofences.add(geo.toGeofence());
        }

        GeofencingRequest.Builder builder = new GeofencingRequest.Builder();
        builder.setInitialTrigger(0);
        builder.addGeofences(newGeofences);
        return builder.build();
    }
}
