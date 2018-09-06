Pod::Spec.new do |s|

  s.name         = "LQFlexLayoutKit"
  s.version      = "0.0.1"
  s.summary      = "An iOS flex layout kit based on facebook's Yoga framework."
  s.description  = "LQFlexLayoutKit is based on facebook's Yoga framework, it expand YogaKit's function, such as async layout and dynamic tableview cell height etc."
  s.homepage     = "https://github.com/chy305chy/LQFlexLayoutKit"
  s.license      = { :type => "BSD", :file => "LICENSE" }
  s.author       = { "cuilanqing" => "cuilanqing1990@163.com" }
  s.social_media_url   = "https://chy305chy.github.io/"
  s.platform           = :ios, "9.0"
  s.ios.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/chy305chy/LQFlexLayoutKit.git", :tag => "v0.0.1" }
  s.source_files  = "LQFlexLayoutKit/*.{h,m}"
  s.public_header_files = "LQFlexLayoutKit/*.h"
  s.requires_arc = true
  s.dependency "Yoga", "~> 1.9.0"

end
