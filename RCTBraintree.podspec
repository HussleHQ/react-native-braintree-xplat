#
# Be sure to run `pod lib lint react-native-braintree-xplat.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RCTBraintree'
  s.version          = '2.1.0'
  s.summary          = 'Braintree SDK'

  s.homepage         = 'https://github.com/vtolochk/react-native-braintree-xplat'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { 'Valentin Tolochko' => 'vtolochk@gmail.com' }
  s.source           = { :git => 'https://github.com/vtolochk/react-native-braintree-xplat.git', :tag => s.version.to_s }


  s.source_files = 'ios/RCTBraintree/*.{h,m}'

  s.module_name = 'RCTBraintree'
  s.requires_arc   = true
  s.platform       = :ios, "8.0"

  s.dependency "React"
  s.dependency "Braintree"
  s.dependency "Braintree/UI"
  s.dependency "Braintree/Core"
  s.dependency "Braintree/3D-Secure"
  s.dependency "Braintree/Card"
  s.dependency "Braintree/DataCollector"
  s.dependency "Braintree/PaymentFlow"

end
