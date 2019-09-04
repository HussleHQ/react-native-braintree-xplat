#
# Be sure to run `pod lib lint react-native-braintree-xplat.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'react-native-braintree-xplat'
  s.version          = '2.0.0'
  s.summary          = 'Braintree SDK'

  s.homepage         = 'https://github.com/vtolochk/react-native-braintree-xplat'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { 'Valentin Tolochko' => 'vtolochk@gmail.com' }
  s.source           = { :git => 'https://github.com/vtolochk/react-native-braintree-xplat.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'ios/RCTBraintree/**/*'

  s.module_name = 'react-native-braintree-xplat'

end
