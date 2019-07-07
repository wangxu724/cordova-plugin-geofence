package com.cowbell.cordova.geofence;

import android.content.Context;

import java.util.ArrayList;
import java.util.List;

public class GeofenceModelStore {
    private LocalStorage storage;

    public GeofenceModelStore(Context context) {
        storage = new LocalStorage(context);
    }

    public void setGeofenceModel(GeofenceModel geofenceModel) {
        storage.setItem(geofenceModel.id, Gson.get().toJson(geofenceModel));
    }

    public GeofenceModel getGeofenceModel(String id) {
        String objectJson = storage.getItem(id);
        return GeofenceModel.fromJson(objectJson);
    }

    public List<GeofenceModel> getAll() {
        List<String> objectJsonList = storage.getAllItems();
        List<GeofenceModel> result = new ArrayList<GeofenceModel>();
        for (String json : objectJsonList) {
            result.add(GeofenceModel.fromJson(json));
        }
        return result;
    }

    public void remove(String id) {
        storage.removeItem(id);
    }

    public void clear() {
        storage.clear();
    }
}
