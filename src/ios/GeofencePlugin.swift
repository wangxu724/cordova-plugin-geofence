//
//  GeofencePlugin.swift
//  ionic-geofence
//
//  Created by tomasz on 07/10/14.
//
//

import Foundation
import AudioToolbox
import WebKit

let TAG = "GeofencePlugin"
let iOS8 = floor(NSFoundationVersionNumber) > floor(NSFoundationVersionNumber_iOS_7_1)
let iOS7 = floor(NSFoundationVersionNumber) <= floor(NSFoundationVersionNumber_iOS_7_1)

typealias Callback = ([[String:String]]?) -> Void

func log(message: String){
    NSLog("%@ - %@", TAG, message)
}

func log(messages: [String]) {
    for message in messages {
        log(message: message);
    }
}

func log(errors: [[String:String]]) {
    for error in errors {
        log(message: "\(String(describing: error["code"])) - \(String(describing: error["message"]))");
    }
}

func checkRequirements() -> (Bool, [String], [[String:String]]) {
    var errors = [[String:String]]()
    let warnings = [String]()

    if (!CLLocationManager.isMonitoringAvailable(for: CLRegion.self)) {
        errors.append([
            "code": GeofencePlugin.ERROR_GEOFENCE_NOT_AVAILABLE,
            "message": "Geofencing not available"
        ])
    }

    if (!CLLocationManager.locationServicesEnabled()) {
        errors.append([
            "code": GeofencePlugin.ERROR_LOCATION_SERVICES_DISABLED,
            "message": "Locationservices disabled"
        ])
    }

    let authStatus = CLLocationManager.authorizationStatus()

    if (authStatus != CLAuthorizationStatus.authorizedAlways) {
        errors.append([
            "code": GeofencePlugin.ERROR_PERMISSION_DENIED,
            "message": "Location always permissions not granted"
        ])
    }

    let ok = (errors.count == 0)

    return (ok, warnings, errors)
}

@available(iOS 8.0, *)
@objc(GeofencePlugin) class GeofencePlugin : CDVPlugin {
    static let ERROR_GEOFENCE_LIMIT_EXCEEDED = "GEOFENCE_LIMIT_EXCEEDED"
    static let ERROR_GEOFENCE_NOT_AVAILABLE = "GEOFENCE_NOT_AVAILABLE"
    static let ERROR_LOCATION_SERVICES_DISABLED = "LOCATION_SERVICES_DISABLED"
    static let ERROR_PERMISSION_DENIED = "PERMISSION_DENIED"
    static let ERROR_UNKNOWN = "UNKNOWN"

    lazy var geofenceManager = GeofenceManager()
//    let priority = DispatchQueue.GlobalQueuePriority.default

//    override func pluginInitialize () {
//        // NotificationCenter.default.addObserver(
//        //     self,
//        //     selector: #selector(GeofencePlugin.didReceiveLocalNotification(notification:)),
//        //     name: NSNotification.Name(rawValue: "CDVLocalNotification"),
//        //     object: nil
//        // )
//
////        NotificationCenter.default.addObserver(
////            self,
////            selector: #selector(GeofencePlugin.didReceiveTransition(notification:)),
////            name: NSNotification.Name(rawValue: "handleTransition"),
////            object: nil
////        )
//    }

    @objc(initialize:)
    func initialize(command: CDVInvokedUrlCommand) {
        log(message: "Plugin initialization")

        geofenceManager = GeofenceManager()
        geofenceManager.registerPermissions()

        commandDelegate!.run() {
            let (ok, warnings, errors) = checkRequirements()

            log(messages: warnings)
            log(errors: errors)

            let result: CDVPluginResult

            if ok {
                result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: warnings.joined(separator: "\n"))
            } else {
                result = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: errors.first
                )
            }

            self.commandDelegate!.send(result, callbackId: command.callbackId)
        }
    }

    @objc(deviceReady:)
    func deviceReady(command: CDVInvokedUrlCommand) {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(ping:)
    func ping(command: CDVInvokedUrlCommand) {
        log(message: "Ping")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(addOrUpdate:)
    func addOrUpdate(command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .default).async {
            let geo = command.arguments[0]
            self.geofenceManager.addOrUpdate(geofenceModel: JSON(geo), completion: {
                (errors: [[String:String]]?) -> Void in

                DispatchQueue.main.async {
                    var pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                    if (errors != nil) {
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_ERROR,
                            messageAs: errors!.first
                        )
                    }
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                }
            })
        }
    }

    @objc(getWatched:)
    func getWatched(command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .default).async {
            let watched = self.geofenceManager.getWatched()!
            let watchedJsonString = watched.description
            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: watchedJsonString)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }

    @objc(remove:)
    func remove(command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .default).async {
            for id in command.arguments {
                self.geofenceManager.remove(id: id as! String)
            }
            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }

    @objc(removeAll:)
    func removeAll(command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: .default).async {
            self.geofenceManager.removeAll()
            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }

    @objc static func didReceiveTransition (notification: NSNotification) {
        log(message: "didReceiveTransition")
//        notifyAbout()

        // Below is the example of register observer of geofence triggering event

        //    [[NSNotificationCenter defaultCenter] addObserver:[HWPGeofencePlugin class]
        //    selector:@selector(didReceiveTransitionWithNotification:)
        //    name:@"handleTransition"
        //    object:nil];
        //
        //    self.viewController = [[MainViewController alloc] init];
        //    return [super application:application didFinishLaunchingWithOptions:launchOptions];


        // if let geoNotificationString = notification.object as? String {

        //     let js = "setTimeout('geofence.onTransitionReceived([" + geoNotificationString + "])',0)"

        //     evaluateJs(script: js)
        // }
    }



//    //// tmp
//    static func notifyAbout() {
//        UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(
//            types: [UIUserNotificationType.sound, UIUserNotificationType.alert, UIUserNotificationType.badge],
//            categories: nil
//            )
//        )
//
//        let notification = UILocalNotification()
//        notification.timeZone = NSTimeZone.default
//        let dateTime = NSDate()
//        notification.fireDate = dateTime as Date
//        notification.soundName = UILocalNotificationDefaultSoundName
//        notification.alertBody = "This is a test local notification body"
//        UIApplication.shared.scheduleLocalNotification(notification)
//    }

    // @objc func didReceiveLocalNotification (notification: NSNotification) {
    //     log(message: "didReceiveLocalNotification")
    //     if UIApplication.shared.applicationState != UIApplicationState.active {
    //         var data = "undefined"

    //     }
    // }

    // func evaluateJs (script: String) {
    //     if let webView = webView {
    //         if let uiWebView = webView as? UIWebView {
    //             uiWebView.stringByEvaluatingJavaScript(from: script)
    //         } else if let wkWebView = webView as? WKWebView {
    //             wkWebView.evaluateJavaScript(script, completionHandler: nil)
    //         }
    //     } else {
    //         log(message: "webView is nil")
    //     }
    // }
}
