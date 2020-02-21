Pod::Spec.new do |s|
  s.name         = 'NabtoAPI'
  s.platform     = :ios, "11.0"
  s.version      = "1.1.1"
  s.summary      = "Nabto Client API (core library files)"
  s.description  = <<-DESC
This pod installs the iOS version of the cross-platform ANSI C based Nabto Client API library. You should probably use the Nabto Client pod instead as it provides a higher level Objective C wrapper. Any suggestions on how to cleanly combine source files (the Objective C wrapper) with an external dependency (not in github - the large Nabto library files are deployed on CDN) are appreciated :-).

The Nabto communication platform enables you to establish direct connections from a client to even the most resource constrained devices, regardless of the firewall configuration of each peer - a P2P middleware that supports IoT well. 

The platform has been designed from the ground and up with strong security as a focal point. All in all, it enables vendors to create simple, high performant and secure solutions for their Internet connected products with very little effort.
DESC
  s.homepage         = 'https://www.nabto.com'
  s.license      =   { :type => "Commercial", :file => "nabto-libs-ios-static/ios/LICENSE.txt" }
  s.author       = { "Nabto" => "apps@nabto.com" }

  s.source           = { :http => "https://downloads.nabto.com/assets/nabto-ios-client-static/4.5.2/nabto-libs-ios-static.zip" }

  s.source_files = "nabto-libs-ios-static/ios/lib", "nabto-libs-ios-static/ios/include/*.h"
  s.public_header_files = "**/*.h"
  s.ios.libraries = "c++", "stdc++"
  s.vendored_libraries = "nabto-libs-ios-static/ios/lib/libnabto_client_api_static.a", "nabto-libs-ios-static/ios/lib/libnabto_static_external.a"
  s.static_framework = true
  
end

