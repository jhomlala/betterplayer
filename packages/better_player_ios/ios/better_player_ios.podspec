#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'better_player_ios'
  s.version          = '1.0.0'
  s.summary          = 'iOS implementation of the better_player plugin.'
  s.description      = <<-DESC
iOS implementation of the better_player plugin.
                       DESC
  s.homepage         = 'https://github.com/jhomlala/better_player'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'jhomlala' => 'jhomlala@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Sources/**/*'
  s.dependency 'Flutter'
  s.dependency 'Cache', '~> 6.0.0'

  s.platform = :ios, '13.0'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
