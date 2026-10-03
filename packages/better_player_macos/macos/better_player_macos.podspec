Pod::Spec.new do |s|
  s.name             = 'better_player_macos'
  s.version          = '1.1.0'
  s.summary          = 'macOS implementation of the better_player plugin.'
  s.description      = <<-DESC
macOS implementation of the better_player plugin.
                       DESC
  s.homepage         = 'https://github.com/jhomlala/betterplayer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'BetterPlayer' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'better_player_macos/Sources/**/*.{swift,m,h}'
  s.resource_bundles = {
    'better_player_macos_privacy' => ['better_player_macos/Sources/better_player_macos/PrivacyInfo.xcprivacy']
  }
  s.dependency 'FlutterMacOS'
  s.dependency 'Cache', '~> 6.0.0'
  s.platform = :osx, '10.15'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
