Pod::Spec.new do |s|
  s.name             = 'HLFMapViewController'
  s.version          = '0.4.0'
  s.summary          = 'Map modal for searching and selecting a location.'
  s.description      = <<-DESC
                       A generic implementation of a common feature: searching
                       and selecting a nearby location from an MKMapView.
                       DESC
  s.screenshots      = [ 'https://dl.dropboxusercontent.com/u/305699/hlf-map-view-controller-1-2.png',
                         'https://dl.dropboxusercontent.com/u/305699/hlf-map-view-controller-2-2.png' ]
  s.homepage         = 'https://github.com/hlfcoding/HLFMapViewController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Peng Wang' => 'peng@pengxwang.com' }
  s.source           = { :git => 'https://github.com/hlfcoding/HLFMapViewController.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/hlfcoding'

  s.ios.deployment_target = '9.0'

  s.source_files = 'Pod/Classes/**/*'
  s.resources = 'Pod/Assets/**/*'

  s.frameworks = 'UIKit', 'CoreLocation', 'MapKit'
end
