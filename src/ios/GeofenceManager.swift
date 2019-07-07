//
//  GeofenceManager.swift
//
//  Created by XuWang on 7/9/19.
//

import Foundation

struct Command {
    var geofenceModel: JSON
    var callback: Callback
}

let GEOFENCE_TRANSITION_EVENT = "didGeofenceTransition";

@available(iOS 8.0, *)
class GeofenceManager : NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    let store = GeofenceModelStore()
    var addOrUpdateCallbacks = [CLCircularRegion:Command]()

    override init() {
        log(message: "GeofenceManager init")
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func registerPermissions() {
        if iOS8 {
            locationManager.requestAlwaysAuthorization()
        }
    }

    func addOrUpdate(geofenceModel: JSON, completion: @escaping Callback) {
        log(message: "GeofenceManager addOrUpdate")

        let (ok, warnings, errors) = checkRequirements()

        log(messages: warnings)
        log(errors: errors)

        if (!ok) {
            return completion(errors)
        }

        let location = CLLocationCoordinate2DMake(
            geofenceModel["latitude"].doubleValue,
            geofenceModel["longitude"].doubleValue
        )
        log(message: "AddOrUpdate geofenceModel: \(geofenceModel)")
        let radius = geofenceModel["radius"].doubleValue as CLLocationDistance
        let id = geofenceModel["id"].stringValue

        let region = CLCircularRegion(center: location, radius: radius, identifier: id)

        var transitionType = 0
        if let i = geofenceModel["transitionType"].int {
            transitionType = i
        }
        region.notifyOnEntry = 0 != transitionType & 1
        region.notifyOnExit = 0 != transitionType & 2

        let command = Command(geofenceModel: geofenceModel, callback: completion)
        addOrUpdateCallbacks[region] = command
        locationManager.startMonitoring(for: region)
    }

    func getWatched() -> [JSON]? {
        return store.getAll()
    }

    func getMonitoredRegion(id: String) -> CLRegion? {
        for object in locationManager.monitoredRegions {
            let region = object

            if (region.identifier == id) {
                return region
            }
        }
        return nil
    }

    func remove(id: String) {
        store.remove(id: id)
        let region = getMonitoredRegion(id: id)
        if (region != nil) {
            log(message: "Stop monitoring region \(id)")
            locationManager.stopMonitoring(for: region!)
        }
    }

    func removeAll() {
        store.clear()
        for object in locationManager.monitoredRegions {
            let region = object
            log(message: "Stop monitoring region \(region.identifier)")
            locationManager.stopMonitoring(for: region)
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        log(message: "Entering region \(region.identifier)")
        handleTransition(region: region, transitionType: 1)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        log(message: "Exiting region \(region.identifier)")
        handleTransition(region: region, transitionType: 2)
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if let clRegion = region as? CLCircularRegion {
            if let command = self.addOrUpdateCallbacks[clRegion] {
                store.addOrUpdate(geofenceModel: command.geofenceModel)
                log(message: "Starting monitoring for region \(region.identifier)")
                command.callback(nil)
                self.addOrUpdateCallbacks.removeValue(forKey: clRegion)
            }
        }
    }

    private func locationManager(_ manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        log(message: "Monitoring region \(region!.identifier) failed. Reson: \(error.description)")
        if let clRegion = region as? CLCircularRegion {
            if let command = self.addOrUpdateCallbacks[clRegion] {
                var errors = [[String:String]]()
                if locationManager.monitoredRegions.count >= 20 {
                    errors.append([
                        "code": GeofencePlugin.ERROR_GEOFENCE_LIMIT_EXCEEDED,
                        "message": error.description
                        ])
                } else {
                    errors.append([
                        "code": GeofencePlugin.ERROR_UNKNOWN,
                        "message": error.description
                        ])
                }

                command.callback(errors)
                self.addOrUpdateCallbacks.removeValue(forKey: clRegion)
            }
        }
    }

    func handleTransition(region: CLRegion!, transitionType: Int) {
        if var geofenceModel = store.findById(id: region.identifier) {
            geofenceModel["transitionType"].int = transitionType

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: GEOFENCE_TRANSITION_EVENT), object: geofenceModel.rawString(String.Encoding.utf8, options: []))
        }
    }
}
