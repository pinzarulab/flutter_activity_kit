Pod::Spec.new do |s|
  s.name             = 'flutter_activity_kit'
  s.version          = '0.1.0'
  s.summary          = 'Declarative iOS Live Activities and Android Ongoing Notifications for Flutter.'
  s.description      = <<-DESC
Unified API for iOS Live Activities, Dynamic Island widgets, push token synchronization, and Android Ongoing Notifications.
                       DESC
  s.homepage         = 'https://github.com/flutteractivitykit/flutter_activity_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter ActivityKit' => 'contact@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
