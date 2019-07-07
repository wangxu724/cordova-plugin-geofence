# Cordova Geofence Plugin

[![version](https://badge.fury.io/js/cordova-plugin-geofence.png)](https://badge.fury.io/js/cordova-plugin-geofence)

Plugin to monitor circular geofences using mobile devices. The purpose is to notify user if crossing the boundary of the monitored geofence.

Plugin support geofence CRUD operation via javascript code, and support geofence transition handling via native code.

*Geofences persist after device reboot. You do not have to open your app first to monitor added geofences*

<!-- ## Example applications

Check out our example applications:

* https://github.com/cowbell/ionic-geofence built with [Ionic](http://ionic.io/) framework
* https://github.com/tsubik/ionic2-geofence built with [Ionic 2](http://ionic.io/2) framework
* https://github.com/cowbell/ember-geofence built with [Ember.js](http://emberjs.com/), [Cordova](https://cordova.apache.org/), [Material Design](https://www.google.com/design/spec/material-design/introduction.html) -->

# Setup
## Installation

```
cordova plugin add https://github.com/wangxu724/cordova-plugin-geofence
```

### Android quirks
Plugin uses Google Play Services so you need to have it installed on your device.


### iOS quirks

Since iOS 11, iOS need `NSLocationAlwaysAndWhenInUseUsageDescription` and `NSLocationWhenInUseUsageDescription` entries in the info.plist.

`NSLocationWhenInUseUsageDescription` describes the reason that the app accesses the user's location.
`NSLocationAlwaysAndWhenInUseUsageDescription` describes the reason that the app accesses the user's location when not in use (in the background).

When the system prompts the user to allow access, this string is displayed as part of the dialog box. To add this entry you can pass the variable `GEOFENCE_IN_USE_USAGE_DESCRIPTION` and `GEOFENCE_ALWAYS_USAGE_DESCRIPTION` on plugin install.

Example:
`cordova plugin add cordova-plugin-geofence --variable GEOFENCE_IN_USE_USAGE_DESCRIPTION="your usage message" --variable GEOFENCE_ALWAYS_USAGE_DESCRIPTION="your usage message"`

If you don't pass the variable, the plugin will add a default string as value.

Plugin is written in Swift. All xcode project options to enable swift support are set up automatically after plugin is installed thanks to
[cordova-plugin-add-swift-support](https://github.com/akofman/cordova-plugin-add-swift-support).

## Removing the Plugin from project

Using cordova CLI

```
cordova plugin rm cordova-plugin-geofence
```

## Supported Platforms

- Android
- iOS >=7.0

# Known Limitations

**This plugin is a wrapper on devices' native APIs** which mean it comes with **limitations of those APIs**.

## Geofence Limit

There are certain limits of geofences that you can set in your application depends on the platform of use.

- iOS - 20 geofences
- Android - 100 geofences

# Using the plugin
## Geofence CRUD operation
Geofence CRUD operation is done on the javascript side when the app is fully launched.

Cordova initialize plugin to `window.geofence` object.

### Methods

All methods returning promises, but you can also use standard callback functions.

- `window.geofence.initialize(onSuccess, onError)`
- `window.geofence.addOrUpdate(geofences, onSuccess, onError)`
- `window.geofence.remove(geofenceId, onSuccess, onError)`
- `window.geofence.removeAll(onSuccess, onError)`
- `window.geofence.getWatched(onSuccess, onError)`

<!-- For listening of geofence transistion you can override onTransitionReceived method
- `window.geofence.onTransitionReceived(geofences)` -->

### Constants

- `TransitionType.ENTER` = 1
- `TransitionType.EXIT` = 2
- `TransitionType.BOTH` = 3

### Geofence structure
```javascript
{
    id:             String, // A unique identifier of geofence
    latitude:       Number, // Geo latitude of geofence
    longitude:      Number, // Geo longitude of geofence
    radius:         Number, // Radius of geofence in meters
    transitionType: Number // Type of transition 1 - Enter, 2 - Exit, 3 - Both
}
```

### Error codes

Both `onError` function handler and promise rejection take `error` object as an argument.

```javascript
error: {
    code: String,
    message: String
}
```

Error codes:

- `UNKNOWN`
- `PERMISSION_DENIED`
- `GEOFENCE_NOT_AVAILABLE`
- `GEOFENCE_LIMIT_EXCEEDED`

### Plugin initialization

The plugin is not available until `deviceready` event is fired.

```javascript
document.addEventListener('deviceready', function () {
    // window.geofence is now available
    window.geofence.initialize().then(function () {
        console.log("Successful initialization");
    }, function (error) {
        console.log("Error", error);
    });
}, false);
```

Initialization process is responsible for requesting neccessary permissions.
If required permissions are not granted then initialization fails with error message.

### Adding new geofence to monitor

```javascript
window.geofence.addOrUpdate({
    id:             String, // A unique identifier of geofence
    latitude:       Number, // Geo latitude of geofence
    longitude:      Number, // Geo longitude of geofence
    radius:         Number, // Radius of geofence in meters
    transitionType: Number // Type of transition 1 - Enter, 2 - Exit, 3 - Both
}).then(function () {
    console.log('Geofence successfully added');
}, function (error) {
    console.log('Adding geofence failed', error);
});
```
Adding more geofences at once
```javascript
window.geofence.addOrUpdate([geofence1, geofence2, geofence3]);
```

Geofence overrides the previously one with the same `id`.

*All geofences are stored on the device and restored to monitor after device reboot.*

### Removing

Removing single geofence
```javascript
window.geofence.remove(geofenceId)
    .then(function () {
        console.log('Geofence sucessfully removed');
    }
    , function (error){
        console.log('Removing geofence failed', error);
    });
```
Removing more than one geofence at once.
```javascript
window.geofence.remove([geofenceId1, geofenceId2, geofenceId3]);
```

### Removing all geofences

```javascript
window.geofence.removeAll()
    .then(function () {
        console.log('All geofences successfully removed.');
    }
    , function (error) {
        console.log('Removing geofences failed', error);
    });
```

### Getting watched geofences from device

```javascript
window.geofence.getWatched().then(function (geofencesJson) {
    var geofences = JSON.parse(geofencesJson);
});
```

## Handle geofence transition event
Geofence transition event need to be handled in native code. This provide more flexibility than previous version, which only support javascript handling.

### Android

Plugin defines a [signature permission](https://developer.android.com/guide/topics/manifest/permission-element.html#plevel) `com.geofence.permission.GEOFENCE_TRANSITION_BROADCAST`, and will add `<uses-permission android:name="com.geofence.permission.GEOFENCE_TRANSITION_BROADCAST" />` in `AndroidMainifest.xml`

When a geofence transition happens, plugin will broadcast an `com.geofence.GEOFENCE_TRANSITION` intent with this permission.

In order to receive the intent, app need to have its own `BroadcastReceiver` that requires this permission.

When an intent is received, app can call `intent.getStringExtra("transitionData")` to get transition data, which is a json string of an **array(different from ios)** of [geofence structure](#Geofence-structure) with `transitionType` field set to `1`(enter) or `2`(exit) based on current transition event.

#### Example of handling geofence transition intent
First, register receiver in `AndroidManifest.xml`

```xml
<receiver
    android:name="YOUR_APP_PACKAGE_NAME.TransitionReceiver"
    android:permission="com.geofence.permission.GEOFENCE_TRANSITION_BROADCAST">
    <intent-filter>
        <action android:name="com.geofence.GEOFENCE_TRANSITION" />
    </intent-filter>
</receiver>
```

Then, implement a `TransitionReceiver.java` as following

```java
public class TransitionReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        String error = intent.getStringExtra("error");

        if (error != null) {
            //handle error
        } else {
            String geofencesJson = intent.getStringExtra("transitionData");
            //handle geofence here
        }
    }
}
```

### iOS
On iOS, when a geofence transition happends, plugin will post a `didGeofenceTransition` event to NotificationCenter.

App need to have its own observer. User can add the observer in `application(_:didFinishLaunchingWithOptions:)` and start monitoring the geofence transition event right after app launch.

When an event is observed, observer will receive data of type `NSNotification`, the `object` property of which is a json string of [geofence structure](#Geofence-structure) as input parameter with `transitionType` field set to `1`(enter) or `2`(exit) based on current transition event.

#### Example of handling geofence transition
```swift
 NotificationCenter.default.addObserver(
            someObject,
            selector: #selector(someGeofenceTransitionHandling(notification:)),
            name: NSNotification.Name(rawValue: "didGeofenceTransition"),
            object: nil
        )
```

<!-- # Example usage

Adding geofence to monitor entering Gliwice city center area of radius 3km

```javascript
window.geofence.addOrUpdate({
    id:             "69ca1b88-6fbe-4e80-a4d4-ff4d3748acdb",
    latitude:       50.2980049,
    longitude:      18.6593152,
    radius:         3000,
    transitionType: TransitionType.ENTER,
    notification: {
        id:             1,
        title:          "Welcome in Gliwice",
        text:           "You just arrived to Gliwice city center.",
        openAppOnClick: true
    }
}).then(function () {
    console.log('Geofence successfully added');
}, function (reason) {
    console.log('Adding geofence failed', reason);
})
```

# Development

## Installation

- git clone https://github.com/cowbell/cordova-plugin-geofence
- change into the new directory
- `npm install`

## Running tests

- Start emulator
- `cordova-paramedic --platform android --plugin .`

### Testing on iOS

Before you run `cordova-paramedic` install `npm install -g ios-sim`

### Troubleshooting

Add `--verbose` at the end of `cordova-paramedic` command. -->

## License

This software is released under the [Apache 2.0 License](http://opensource.org/licenses/Apache-2.0).

© 2014-2017 Cowbell-labs. All rights reserved
