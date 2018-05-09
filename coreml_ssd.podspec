Pod::Spec.new do |s|
  s.name             = 'coreml_ssd'
  s.version          = '0.0.1'
  s.summary          = 'A library for using SSD object detection models with the CoreML framework.'
  s.description      = <<-DESC
This Objective-C library provides support for using SSD object detector models
with CoreML framework. The library provides the required postprocessing support
to generate bounding boxes from the raw predictions. It also provides support
to render these predictions into either UIView or NSView, depending on the platform.
                       DESC

  s.homepage         = 'https://github.com/abamaxa/coreml_ssd'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Chris Morgan' => 'cmorgan@abamaxa.com' }
  s.source           = { :git => 'https://github.com/abamaxa/coreml_ssd.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'

  s.source_files = 'Classes/*.{h,m,mm,cpp}'
  s.ios.source_files = 'Classes/ios/*.{h,m}'
  s.osx.source_files = 'Classes/osx/*.{h,m}'

  s.frameworks = 'CoreML', 'Vision', "CoreMedia"
  s.ios.frameworks = 'UIKit', "QuartzCore", "CoreImage", "CoreGraphics"
  s.osx.frameworks = 'AppKit'
end
