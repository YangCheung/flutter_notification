#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flnotification'
  s.version          = '0.0.1'
  s.summary          = 'Firebase Cloud Messaging plugin for Flutter.'
  s.description      = <<-DESC
Firebase Cloud Messaging plugin for Flutter.
                       DESC
  s.homepage         = 'https://github.com/flutter/plugins/tree/master/packages/firebase_messaging'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'UMCPush'
  s.static_framework = true
  s.ios.deployment_target = '8.0'
end
