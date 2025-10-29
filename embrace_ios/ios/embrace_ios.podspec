#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'embrace_ios'
  s.version          = '0.0.1'
  s.summary          = "Visibility into your users that you didn't have before"
  s.description      = <<-DESC
  An iOS implementation of the embrace plugin.
                       DESC
  s.homepage         = 'https://embrace.io'
  s.license          = { :type => "Commercial", :text => "Copyright 2022 Embrace.io" }
  s.author                = "Embrace.io"
  s.documentation_url     = "https://embrace.io/docs/"
  s.source           = { :path => '.' }  
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'EmbraceIO', '6.13.2'
  s.dependency 'OpenTelemetry-Swift-Api'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
