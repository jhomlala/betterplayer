#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'better_player'
  s.version          = '0.7.1'
  s.summary          = 'Advanced video player with HLS, DASH and caching support.'
  s.description      = <<-DESC
Advanced video player for Flutter with HLS, DASH and caching support.
                       DESC
  s.homepage         = 'https://github.com/jhomlala/better_player'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'jhomlala' => 'jhomlala@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'better_player/Sources/**/*'
  s.dependency 'Flutter'
  s.dependency 'Cache', '~> 6.0.0'

  s.platform = :ios, '13.0'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
