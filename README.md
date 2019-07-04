# BGSocialLogin

[![CI Status](https://img.shields.io/travis/bugguide@gmail.com/BGSocialLogin.svg?style=flat)](https://travis-ci.org/bugguide@gmail.com/BGSocialLogin)
[![Version](https://img.shields.io/cocoapods/v/BGSocialLogin.svg?style=flat)](https://cocoapods.org/pods/BGSocialLogin)
[![License](https://img.shields.io/cocoapods/l/BGSocialLogin.svg?style=flat)](https://cocoapods.org/pods/BGSocialLogin)
[![Platform](https://img.shields.io/cocoapods/p/BGSocialLogin.svg?style=flat)](https://cocoapods.org/pods/BGSocialLogin)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- Xcode 10.2.1
- iOS 10



## Dependency

- 'SnapKit', '5.0.0' *#auto layout support*
- 'naveridlogin-sdk-ios', '4.0.12' *#naver sdk*
- 'FBSDKLoginKit', '5.1.1' *#faceBook sdk*
- 'Alamofire', '4.8.2' *#network*
- 'Firebase/Auth', '6.3.0' #google
- 'GoogleSignIn', '4.4.0' #google
- 'KakaoOpenSDK', '1.12.1' #kakao
  - 비공식으로 나온 Cocoapod SDK. pod 'KakaoOpenSDK'



## Installation

BGSocialLogin is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BGSocialLogin'
```



## Use

적용된 모든 소셜 플랫폼은 미리 만들어둔 뷰를 지정해주면 해당 뷰 안으로 소셜로그인이 사용하는 버튼을 add한다. 로그인 이벤트가 동작한 이후엔 1차적으로 모듈이 가공하여 BGSocialLoginUser 라는 형태로 반환된다.

각 로그인이 동작하기 위해서 필요한 기본적 프로잭트 셋팅은 아래와 같이 수동으로 설정해야하며, 자세한 내용은 각 플랫폼의 개발자 가이드에 따른다.

#### Base Response

사용하려는 view controller 에 BGSocialLogin을 import. presenter 를 생성해주고, viewdidload 에 attachview를 작성한다. 작성 후 SocialLogin의 이벤트가 발생하면 정해진 BGLoginContract_View 의 규약에 따라 공통된 BGSocialLoginUser의 형태로 결과가 반환된다.

```swift
import BGSocialLogin

class ViewController: UIViewController {
		var presenter = BGLoginPresenter.init(model: BGLoginModel())
  
		override func viewDidLoad() {
			super.viewDidLoad()
			presenter.attachView(view: self)
		}
}

extension ViewController: BGLoginContract_View {
    func responseSosialLogin(_ loginUser: BGSocialLoginUser) {
        let message = "loginUser : \(loginUser)"
        Toast.init(text: message).show()
    }
}
```

#### Response Result

```swift
public struct BGSocialLoginUser {
    public var sosial:BGSocial? = .none
    public var name:String?
    public var email:String?
    public var phone:String?
    public var imageUrlStr:String?
    public var token:String?
    public var error:Error?
}

public enum BGSocial: String {
    case kakao = "Kakao"
    case naver = "Naver"
    case facebook = "Facebook"
    case google = "Google"
}
```



#### Use Kakao Social Login

- Project Info.plist 에 **KAKAO_APP_KEY = 발급받은 api_key** 를 셋팅한다.

- Project Info.plist 에 아래와같은 **LSApplicationQueriesSchemes 를 추가**한다.

  ```xml
  <key>LSApplicationQueriesSchemes</key>
  <array>
    <string>kakao0123456789abcdefghijklmn</string>
    <string>kakaokompassauth</string>
    <string>storykompassauth</string>
    <string>kakaolink</string>
    <string>kakaotalk-5.9.7</string>
    <string>storylink</string>
  </array>
  ```

- Project Target -> Info -> UrlTypes 에 Url Schemes 를 추가한다.

  - Ex > kakaoXXXXXX000000XXXXXX000000XXXXXX77

- appDelegate Code 작성

  ```swift
  import BGSocialLogin
  
  @UIApplicationMain
  class AppDelegate: UIResponder, UIApplicationDelegate {		
    
  		func applicationDidBecomeActive(_ application: UIApplication) {
  		  BGLoginModel.setAppDelegateKakaoHandleDidBecomeActive()
  		}
  
      func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
          if BGLoginModel.setAppDelegateKakaoCallback(openURL: url) {
              return true
          }
          return false
      }
  }
  ```

- View Controller Code 작성

  ```swift
  import BGSocialLogin
  
  class ViewController: UIViewController {
      var presenter = BGLoginPresenter.init(model: BGLoginModel())
  		@IBOutlet weak var vWrapper: UIView!
    
      override func viewDidLoad() {
          super.viewDidLoad()
          presenter.attachView(view: self)
          presenter.addKakaoLoginButton(wrapperView: vWrapper)
      }
  }
  
  extension ViewController: BGLoginContract_View {
      func responseSosialLogin(_ loginUser: BGSocialLoginUser) {
          let message = "loginUser : \(loginUser)"
      }
  }
  ```

  

#### Use Google Social Login





## Author

bugguide@gmail.com, bugguide@gmail.com

## License

BGSocialLogin is available under the MIT license. See the LICENSE file for more info.
