#
# Be sure to run `pod lib lint HLFMapViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "HLFMapViewController"
  s.version          = "0.1.1"
  s.summary          = "Map modal for searching and selecting a nearby location."
  s.description      = <<-DESC
                       A generic implementation of a common feature: searching
                       and selecting a nearby location from an MKMapView.
                       DESC

  s.homepage         = "https://github.com/hlfcoding/HLFMapViewController"
  s.license          = 'MIT'
  s.author           = { "Peng Wang" => "peng@pengxwang.com" }
  s.source           = { :git => "https://github.com/hlfcoding/HLFMapViewController.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/hlfcoding'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resources = 'Pod/Assets/**/*'

  s.frameworks = 'UIKit', 'Contacts', 'CoreLocation', 'MapKit'
end
