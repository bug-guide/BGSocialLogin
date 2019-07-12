#
# Be sure to run `pod lib lint BGSocialLogin.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BGSocialLogin'
  s.version          = '0.1.2'
  s.summary          = '한국에서 사용하는 소셜로그인 집합'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://gitlab.com/wisewood/bgsociallogin.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'bugguide@gmail.com' => 'bugguide@gmail.com' }
  s.source           = { :git => 'https://github.com/bug-guide/BGSocialLogin.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'BGSocialLogin/Classes/**/*'
  
  # s.resource_bundles = {
  #   'BGSocialLogin' => ['BGSocialLogin/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

  s.static_framework = true  

  s.dependency 'SnapKit', '5.0.0' #auto layout support
  s.dependency 'naveridlogin-sdk-ios', '4.0.12' #naver sdk
  s.dependency 'FBSDKLoginKit', '5.1.1' #faceBook sdk
  s.dependency 'Alamofire', '4.8.2' #network
  s.dependency 'Firebase/Auth', '6.3.0'
  s.dependency 'GoogleSignIn', '4.4.0'
  s.dependency 'KakaoOpenSDK', '1.12.1'
end
