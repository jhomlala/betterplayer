#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'better_player'
  s.version          = '0.4.2'
  s.summary          = 'Advanced video player with HLS, DASH and caching support.'
  s.description      = <<-DESC
Advanced video player for Flutter with HLS, DASH and caching support.
                       DESC
  s.homepage         = 'https://github.com/jhomlala/betterplayer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'jhomlala' => 'jhomlala@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'better_player/Sources/**/*'
  s.public_header_files = 'better_player/Sources/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'Cache', '~> 6.0.0'
  s.dependency 'GCDWebServer'
  s.dependency 'HLSCachingReverseProxyServer'
  s.dependency 'PINCache'
  
  s.platform = :ios, '11.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
