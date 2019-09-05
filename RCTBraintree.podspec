#
# Be sure to run `pod lib lint react-native-braintree-xplat.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RCTBraintree'
  s.version          = '2.0.0'
  s.summary          = 'Braintree SDK'

  s.homepage         = 'https://github.com/vtolochk/react-native-braintree-xplat'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { 'Valentin Tolochko' => 'vtolochk@gmail.com' }
  s.source           = { :git => 'https://github.com/vtolochk/react-native-braintree-xplat.git', :tag => s.version.to_s }


  s.source_files = 'ios/RCTBraintree/*.{h,m}'

  s.frameworks = 'CardinalMobile'
  s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '$(SRCROOT)/../node_modules/react-native-braintree-xplat/ios/RCTBraintree/Braintree/Frameworks', 'HEADER_SEARCH_PATHS' => '"$(SRCROOT)/../node_modules/react-native-braintree-xplat/ios/RCTBraintree/Braintree"/**' }

  s.module_name = 'RCTBraintree'
  s.requires_arc   = true
  # s.static_framework = true
  s.platform       = :ios, '9.0'

  # s.preserve_paths = '*.js'

  s.dependency "React"
  s.dependency "Braintree"
  s.dependency "Braintree/Core"
  s.dependency "Braintree/3D-Secure"
  s.dependency "Braintree/Card"
  s.dependency "Braintree/DataCollector"
  s.dependency "Braintree/PaymentFlow"

end
