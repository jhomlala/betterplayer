#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint better_player_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'better_player_ios'
  s.version          = '1.0.0'
  s.summary          = 'iOS implementation of the better_player plugin.'
  s.description      = <<-DESC
iOS implementation of the better_player plugin.
                       DESC
  s.homepage         = 'https://github.com/jhomlala/betterplayer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'BetterPlayer' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'ios/Sources/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
