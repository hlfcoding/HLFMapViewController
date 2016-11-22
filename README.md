# HLFMapViewController

[![Version](https://img.shields.io/cocoapods/v/HLFMapViewController.svg?style=flat)](http://cocoapods.org/pods/HLFMapViewController)
[![License](https://img.shields.io/cocoapods/l/HLFMapViewController.svg?style=flat)](http://cocoapods.org/pods/HLFMapViewController)
[![Platform](https://img.shields.io/cocoapods/p/HLFMapViewController.svg?style=flat)](http://cocoapods.org/pods/HLFMapViewController)
[![Code Climate](https://codeclimate.com/github/hlfcoding/HLFMapViewController/badges/gpa.svg)](https://codeclimate.com/github/hlfcoding/HLFMapViewController)

> A generic implementation of a common feature: searching and selecting a nearby location from an `MKMapView`.

![screenshot-1](https://dl.dropboxusercontent.com/u/305699/hlf-map-view-controller-1-2.png) &emsp;&emsp;![screenshot-2](https://dl.dropboxusercontent.com/u/305699/hlf-map-view-controller-2-2.png)

## Usage

This version uses Swift 3 and Cocoapods 0.1.0+. The final Swift 2 version is 0.2.5.

To run the example project, clone the repo, and run `pod install` from the Example directory first.

In addition to turning on the 'Maps' capability, you'll need to add `location-services` to `UIRequiredDeviceCapabilities`and fill in `NSLocationAlwaysUsageDescription` in your Info.plist.

Other than that just set up the view controller and implement the delegate method:

```swift
// ...
let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
mapViewController.delegate = self
mapViewController.selectedMapItem = self.selectedMapItem // Optional.
// ...

func mapViewController(_ mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem) {
    self.selectedMapItem = mapItem // Save, submit, etc.
    mapViewController.dismissViewController(animated: true, completion: nil)
}
```

See [example app](//github.com/hlfcoding/HLFMapViewController/blob/master/Example/HLFMapViewController/ViewController.swift) for more details.

## Installation

HLFMapViewController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "HLFMapViewController"
```

## License

HLFMapViewController is available under the MIT license. See the LICENSE file for more info.
