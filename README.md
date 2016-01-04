# HLFMapViewController

[![Version](https://img.shields.io/cocoapods/v/HLFMapViewController.svg?style=flat)](http://cocoapods.org/pods/HLFMapViewController)
[![License](https://img.shields.io/cocoapods/l/HLFMapViewController.svg?style=flat)](http://cocoapods.org/pods/HLFMapViewController)
[![Platform](https://img.shields.io/cocoapods/p/HLFMapViewController.svg?style=flat)](http://cocoapods.org/pods/HLFMapViewController)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

In addition to turning on the 'Maps' capability, you'll need to add `location-services` to `UIRequiredDeviceCapabilities`and fill in `NSLocationAlwaysUsageDescription` in your Info.plist.

Other than that just set up the view controller and implement the delegate method:

```swift
// ...
let mapViewController = MapViewController(nibName: "HLFMapViewController", bundle: MapViewController.bundle)
mapViewController.delegate = self
// ...

func mapViewController(mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem) {
mapViewController.dismissViewControllerAnimated(true, completion: nil)
}
```

## Installation

HLFMapViewController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "HLFMapViewController"
```

## License

HLFMapViewController is available under the MIT license. See the LICENSE file for more info.
