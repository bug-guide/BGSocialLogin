//
//  BGLoginModel.swift
//  LastOrder
//
//  Created by HacJune Lee on 26/05/2019.
//  Copyright © 2019 HacJune Lee. All rights reserved.
//

import UIKit
///kakao
import KakaoOpenSDK
///naver
import NaverThirdPartyLogin
///facebook
import FBSDKCoreKit
import FBSDKLoginKit

import SnapKit
import Alamofire

import GoogleSignIn
import FirebaseAuth

public class BGLoginModel: BGBaseModel {
    public override init() {}

    /**
     소셜 모듈에서 로그인이 완료되면 호출한다.
     - Parameters:
     - social : 소셜종류
     - email : 소셜 이메일 계정정보
     - phone : 소셜에 등록된 휴대전화번호. ! 카카오는 휴대전화번호를 가져올 수 없다 !
     - error : 로그인이 실패할경우 에러를 반환한다.
     */
    var loginCompleteHandle:((_ loginUser:BGSocialLoginUser)->Void)?
    var loginStatusHandle:((_ status:BGSocialLoginStatus, _ sosial:BGSocial)->Void)?
}

// MARK: - kakao
/**
 카카오를 통한 로그인이 정상적으로 동작하려면 info.plist에 화이트리스트 등재가 필요하다.
 <key>LSApplicationQueriesSchemes</key>
 <array>
 <!-- 공통 -->
 <string>kakao0123456789abcdefghijklmn</string>
 
 <!-- 간편로그인 -->
 <string>kakaokompassauth</string>
 <string>storykompassauth</string>
 
 <!-- 카카오톡링크 -->
 <string>kakaolink</string>
 <string>kakaotalk-5.9.7</string>
 
 <!-- 카카오스토리링크 -->
 <string>storylink</string>
 </array>
 보다 자세한 설명은 https://developers.kakao.com/docs/ios 을 참고합시다.
 */
extension BGLoginModel {
    
    /**
     카카오의 간편 로그인을 사용하기위해서는 AppDelegate의 2가지 위치에 해당 코드를 삽입해야한다.
     
     func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
     return BGLoginModel.setAppDelegateKakaoCallback(openURL: url)
     }
     
     2번 위치 ===
     func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
     -> Bool {
     return BGLoginModel.setAppDelegateKakaoCallback(openURL: url)
     }
     
     - Parameters:
     - openURL : appdelegate에서 넘어오는 url 정보
     */
    public static func setAppDelegateKakaoCallback(openURL: URL) -> Bool {
        
        if KOSession.isKakaoAccountLoginCallback(openURL) {
            return KOSession.handleOpen(openURL)
        }
        
        return false
    }
    
    /**
     카카오의 간편 로그인을 사용하기위해서는 AppDelegate의 applicationDidBecomeActive 위치에 해당 코드를 삽입해야한다.
     
     func applicationDidBecomeActive(_ application: UIApplication) {
     BGLoginModel.setAppDelegateKakaoHandleDidBecomeActive()
     }
     */
    public static func setAppDelegateKakaoHandleDidBecomeActive(){
        KOSession.handleDidBecomeActive()
    }
    
    /**
     카카오 버튼을 생성하여 지정한 wrapper view 에 삽입한다.
     - Parameters:
     - wrapperView : 카카오 버튼이 들어갈 wrapper view
     */
    func addKakaoLoginButton(wrapperView:UIView) {
        for view in wrapperView.subviews {
            //기존에 래퍼 안에 추가된 뷰들이 있다면 모두 이벤트 잡지 않도록 막는다.
            view.isUserInteractionEnabled = false
        }
        
        let button = KOLoginButton.init(frame: CGRect.init())
        button.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        button.autoresizesSubviews = true
        //제일 뒤에 추가한다.
        wrapperView.insertSubview(button, at: 0)
        button.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(wrapperView)
            //make.height.equalTo(50)
        }

        ///카카오버튼이 눌렸을때 동작할 이벤트.
        button.addTarget(self, action: #selector(invokeLoginWithTarget), for: .touchUpInside)
    }
    
    @objc func invokeLoginWithTarget() {
        
        if let loginStatusHandle = loginStatusHandle {
            loginStatusHandle(.start, .kakao)
        }
        
        if let session = KOSession.shared() {
            //기존 세션을 닫고 재시도.
            session.close()
            
            session.open(completionHandler: { (error) in
                if session.isOpen() {
                    print("kakao invokeLoginWithTarget success \(session.token.accessToken)")
                    self.getKakaoUserInfo(token: session.token.accessToken)
                } else {
                    print("kakao invokeLoginWithTarget false \(String(describing: error))")
                    if let loginStatusHandle = self.loginStatusHandle {
                        loginStatusHandle(.fail, .kakao)
                    }
                    
                    if let loginCompleteHandle = self.loginCompleteHandle {
                        var loginUser = BGSocialLoginUser.init()
                        loginUser.sosial = .kakao
                        loginUser.error = error
                        loginCompleteHandle(loginUser)
                    }
                }
            })
            
        } else {
            print("kakao invokeLoginWithTarget lose")
            if let loginStatusHandle = self.loginStatusHandle {
                loginStatusHandle(.fail, .kakao)
            }
            
            let error = NSError(domain:"", code:999, userInfo:nil)
            if let loginCompleteHandle = self.loginCompleteHandle {
                var loginUser = BGSocialLoginUser.init()
                loginUser.sosial = .kakao
                loginUser.error = error
                loginCompleteHandle(loginUser)
            }
        }
    }
    
    /**
     받아온 카카오 토큰을 가지고 유저의 정보를 가져온다.
     - Parameters:
     - token : session.token.accessToken
     */
    func getKakaoUserInfo(token:String){
        
        //인디 쇼.
        //self.indicatorView.showIndicator()
        //var userInfo = uManager.loadCodableUserInfoValue(key: .user_Info)
        KOSessionTask.userMeTask { (error, me) in
            
            //self.indicatorView.hideIndicator()
            
            if error != nil {
                if let loginStatusHandle = self.loginStatusHandle {
                    loginStatusHandle(.fail, .kakao)
                }
                
                print("kakao userMeTask error \(String(describing: error))")
                let error = NSError(domain:"", code:999, userInfo:nil)
                if let loginCompleteHandle = self.loginCompleteHandle {
                    var loginUser = BGSocialLoginUser.init()
                    loginUser.sosial = .kakao
                    loginUser.error = error
                    loginCompleteHandle(loginUser)
                }
                
            } else {
                
                if let me = me {
                    //print("kakao id \(String(describing: me.id))")
                    //print("kakao nickname \(String(describing: me.nickname))")
                    
                    if let account = me.account {
                        //print("kakao account \(account)")
                        if let email = account.email {
                            //획득성공.
                            print("kakao email \(email)")
                            if let loginStatusHandle = self.loginStatusHandle {
                                loginStatusHandle(.end, .kakao)
                            }
                            
                            if let loginCompleteHandle = self.loginCompleteHandle {
                                var loginUser = BGSocialLoginUser.init()
                                loginUser.sosial = .kakao
                                loginUser.email = email
                                loginCompleteHandle(loginUser)
                            }
                            return
                            
                        } else if account.emailNeedsAgreement {
                            //유저가 이메일은 사용하고있지만 권한이 없다.
                            //이메일 획득 권한 이 필요하다.
                            KOSession.shared()?.updateScopes(["account_email"], completionHandler: { (error) in
                                if error != nil {
                                    //유저가 이메일 획득동의를 하지 않았다.
                                    print("유저가 이메일 획득동의를 하지 않았다.")
                                    if let loginStatusHandle = self.loginStatusHandle {
                                        loginStatusHandle(.fail, .kakao)
                                    }
                                    
                                    let error = NSError(domain:"유저가 이메일 획득동의를 하지 않았다.", code:999, userInfo:nil)
                                    if let loginCompleteHandle = self.loginCompleteHandle {
                                        var loginUser = BGSocialLoginUser.init()
                                        loginUser.sosial = .kakao
                                        loginUser.error = error
                                        loginCompleteHandle(loginUser)
                                    }
                                    
                                } else {
                                    //동의함. userme 재호출시 가져올 수 있음.
                                    self.getKakaoUserInfo(token:token)
                                }
                            })
                            
                        } else {
                            //유저가 이메일을 쓰고있지 않다.(아마도.)
                            print("유저가 이메일을 쓰고있지 않다")
                            if let loginStatusHandle = self.loginStatusHandle {
                                loginStatusHandle(.fail, .kakao)
                            }
                            
                            let error = NSError(domain:"유저가 이메일을 쓰고있지 않다", code:999, userInfo:nil)
                            if let loginCompleteHandle = self.loginCompleteHandle {
                                var loginUser = BGSocialLoginUser.init()
                                loginUser.sosial = .kakao
                                loginUser.error = error
                                loginCompleteHandle(loginUser)
                            }
                        }
                    }
                    
                }
                
            }
        }
    }
}

// MARK: - naver

/**
 카카오를 통한 로그인이 정상적으로 동작하려면 info.plist에 화이트리스트 등재가 필요하다.
 <key>LSApplicationQueriesSchemes</key>
 <array>
 <string>naversearchthirdlogin</string>
 <string>naversearchapp</string>
 </array>
 */
extension BGLoginModel: NaverThirdPartyLoginConnectionDelegate {
    
    /**
     네이버 로그인을 위해 앱 델리게이트에서 다음과 같은 권한을 활성화합니다.
     - Parameters:
     - serviceUrlScheme : 콜백을 받을 URL Scheme
     - consumerKey : 애플리케이션에서 사용하는 클라이언트 아이디
     - consumerSecret : 애플리케이션에서 사용하는 클라이언트 시크릿
     - appName : 애플리케이션 이름
     */
    static func setAppDelegateNaverLogin(serviceUrlScheme:String, consumerKey:String, consumerSecret:String, appName:String) {
        
        if let naverInstance = NaverThirdPartyLoginConnection.getSharedInstance() {
            //네이버앱을 통한 활성
            naverInstance.isNaverAppOauthEnable = true
            //사파리를 통한 활성
            naverInstance.isInAppOauthEnable = true
            
            //로그인 화면의 방향설정.(세로방향)
            naverInstance.isOnlyPortraitSupportedInIphone()
            
            naverInstance.serviceUrlScheme = serviceUrlScheme
            naverInstance.consumerKey = consumerKey
            naverInstance.consumerSecret = consumerSecret
            naverInstance.appName = appName
        }
    }
    
    /**
     앱 델리게이트에 openUrl부분에 구현한다. 해당 코드를 구현하지 않으면
     네이버 앱을 통해 로그인했을경우 관련 코드를 sdk가 인식하지 못히고
     토큰 수신부 델리게이트가 동작하지 않을것이다.(아마도)
     */
    static func setAppDelegateNaverReceive(_ application: UIApplication, _ openUrl:URL, _ options: [UIApplication.OpenURLOptionsKey : Any]) {
        
        if let naverInstance = NaverThirdPartyLoginConnection.getSharedInstance() {
            naverInstance.application(application, open: openUrl, options: options)
            //lastordernaver://thirdPartyLoginResult?version=2&code=0&authCode=uuuba5ItLLsacglzXp
        }
    }
    
    func addNaverLoginButton(wrapperView:UIView) {
        for view in wrapperView.subviews {
            //기존에 래퍼 안에 추가된 뷰들이 있다면 모두 이벤트 잡지 않도록 막는다.
            view.isUserInteractionEnabled = false
        }
        
        let button = UIButton.init()
        //        button.backgroundColor = UIColor.red
        wrapperView.insertSubview(button, at: 0)
        //        wrapperView.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(wrapperView)
            //make.height.equalTo(50)
        }
        
        ///카카오버튼이 눌렸을때 동작할 이벤트.
        button.addTarget(self, action: #selector(requestLoginNaver), for: .touchUpInside)
    }
    
    @objc func requestLoginNaver(){
        if let naverInstance = NaverThirdPartyLoginConnection.getSharedInstance() {
            //네이버 sdk에 로그인 요청.
            naverInstance.delegate = self
            naverInstance.requestThirdPartyLogin()
        }
    }
    
    ////// delegate
    
    public func oauth20ConnectionDidOpenInAppBrowser(forOAuth request: URLRequest!) {
        print("oauth20ConnectionDidOpenInAppBrowser")
    }
    
    public func oauth20ConnectionDidFinishRequestACTokenWithAuthCode() {
        //최초 승인시 들어오는것으로 추측됨.
        print("oauth20ConnectionDidFinishRequestACTokenWithAuthCode")
        if let naverInstance = NaverThirdPartyLoginConnection.getSharedInstance() {
            print("\(naverInstance.accessToken ?? "???")")
            self.requestGetNaverUserInfo(accessToken: naverInstance.accessToken ?? "")
        }
    }
    
    public func oauth20ConnectionDidFinishRequestACTokenWithRefreshToken() {
        //이미 승인한 사용자가 다시 로그인을 눌렀을 경우 호출됨... 으로 추측됨
        print("oauth20ConnectionDidFinishRequestACTokenWithRefreshToken")
        if let naverInstance = NaverThirdPartyLoginConnection.getSharedInstance() {
            print("\(naverInstance.accessToken ?? "???")")
            self.requestGetNaverUserInfo(accessToken: naverInstance.accessToken ?? "")
        }
    }
    
    public func oauth20ConnectionDidFinishDeleteToken() {
        print("oauth20ConnectionDidFinishDeleteToken")
    }
    
    public func oauth20Connection(_ oauthConnection: NaverThirdPartyLoginConnection!, didFinishAuthorizationWithResult recieveType: THIRDPARTYLOGIN_RECEIVE_TYPE) {
        print("oauth20Connection didFinishAuthorizationWithResult")
    }
    
    public func oauth20Connection(_ oauthConnection: NaverThirdPartyLoginConnection!, didFailWithError error: Error!) {
        print("oauth20Connection didFailWithError")
    }
    
    
    func requestGetNaverUserInfo(accessToken:String){
        let urlString = "https://openapi.naver.com/v1/nid/me"
        let url:URL = URL.init(string: urlString)!
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": accessToken
        ]
        
        let request:DataRequest = sessionManager!.request(url, method: .get, parameters: [:], encoding: URLEncoding.default, headers: headers)
        publicRequestJsonData(request: request, complete: { data, error in
            print("requestGetNaverUserInfo")
        })
    }
}

// MARK: - facebook
extension BGLoginModel: LoginButtonDelegate {
    
    static func setAppDelegateFacebookLogin(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        
        let facebookInstance = ApplicationDelegate.shared
        facebookInstance.application(application, didFinishLaunchingWithOptions: launchOptions)
        
    }
    
    static func setAppDelegateFacebookReceive(_ application: UIApplication, _ openUrl:URL, _ options: [UIApplication.OpenURLOptionsKey : Any]) {
        let facebookInstance = ApplicationDelegate.shared
        facebookInstance.application(application, open: openUrl, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        
    }
    
    func addFacebookLoginButton(wrapperView:UIView, superViewController:UIViewController) {
        for view in wrapperView.subviews {
            //기존에 래퍼 안에 추가된 뷰들이 있다면 모두 이벤트 잡지 않도록 막는다.
            view.isUserInteractionEnabled = false
        }
        
        /*
         let button = FBSDKLoginButton()
         button.readPermissions = ["public_profile", "email"]
         button.delegate = self
         */
        
        let button = CustomLoginButton.init()
        //        button.backgroundColor = UIColor.red
        wrapperView.insertSubview(button, at: 0)
        //        wrapperView.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(wrapperView)
            //make.height.equalTo(50)
        }
        button.parentViewController = superViewController
        button.addTarget(self, action: #selector(requestLoginFaceBook(_:)), for: .touchUpInside)
    }
    
    public func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        print("FBLoginButton")
        if let result = result {
            let token = result.token?.tokenString ?? ""
            print("facebook login token : \(token)")
            
            let userId = result.token?.userID ?? ""
            print("facebook login userId : \(userId)")
        } else {
            //error!
            if let loginCompleteHandle = self.loginCompleteHandle {
                let error = NSError(domain:"", code:999, userInfo:nil)
                var loginUser = BGSocialLoginUser.init()
                loginUser.sosial = .facebook
                loginUser.error = error
                loginCompleteHandle(loginUser)
            }
        }
    }
    
    public func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        print("loginButtonDidLogOut")
    }
    
    @objc func requestLoginFaceBook(_ sender: CustomLoginButton) {
        if let vc = sender.parentViewController {
            let manager = LoginManager.init()
            manager.logIn(permissions: ["public_profile", "email"], from: vc) { (result, error) in
                if error != nil {
                    print("facebook error")
                }
                
                if let result = result {
                    if result.isCancelled {
                        //페이스북 로그인 팝업에서 취소 이벤트 팔생.
                        if let loginCompleteHandle = self.loginCompleteHandle {
                            let error = NSError(domain:"", code:999, userInfo:nil)
                            var loginUser = BGSocialLoginUser.init()
                            loginUser.sosial = .facebook
                            loginUser.error = error
                            loginCompleteHandle(loginUser)
                        }
                        return
                    }
                    
                    let token = result.token?.tokenString ?? ""
                    print("facebook login token : \(token)")
                    
                    let userId = result.token?.userID ?? ""
                    print("facebook login userId : \(userId)")
                    
                    self.getFacebookUserProfile(result.token)
                } else {
                    print("facebook error, result nil")
                    
                    //error!
                    if let loginCompleteHandle = self.loginCompleteHandle {
                        let error = NSError(domain:"", code:999, userInfo:nil)
                        var loginUser = BGSocialLoginUser.init()
                        loginUser.sosial = .facebook
                        loginUser.error = error
                        loginCompleteHandle(loginUser)
                    }
                }
            }
        }
    }
    
    /**
     페이스북의 그래프 API를 통해 유저의 기본정보를 가져온다.
     가져오는 정보는 email, name, picture 로 고정.
     이 이외의 데이터들은 권한이 따로 필요하다.
     - Parameters:
     - token : 페이스북 로그인 완료시 가져온다.
     */
    func getFacebookUserProfile(_ token:AccessToken?) {
        
        //let graphPath = "/\(token.userID!)"
        //phone 는 사라진 권한인듯. 페이스북 old doc에서는 확인되지만 신 버전에서는 해당 항목 자체가 없다.
        let graphPath = "/me"
        let parameters = [
            "fields" : "email,name,picture"
        ]
        let request = GraphRequest.init(graphPath: graphPath, parameters: parameters, httpMethod: HTTPMethod(rawValue: "GET"))
        request.start(completionHandler: { (connection, result, error) in
            //print(result)
            
            if let result = result as? [String: AnyObject] {
                
                let email = result["email"] as? String ?? ""
                print("email \(email)")
                let name = result["name"] as? String ?? ""
                print("name \(name)")
                
                var imageUrlStr:String? = nil
                if let picture = result["picture"] as? [String: AnyObject] {
                    if let data = picture["data"] as? [String: AnyObject] {
                        let url = data["url"] as? String ?? ""
                        print("url \(url)")
                        imageUrlStr = url
                    }
                }
                
                if let loginCompleteHandle = self.loginCompleteHandle {
                    var loginUser = BGSocialLoginUser.init()
                    loginUser.sosial = .facebook
                    loginUser.email = email
                    loginUser.name = name
                    loginUser.imageUrlStr = imageUrlStr
                    loginUser.token = token?.tokenString
                    loginCompleteHandle(loginUser)
                }
                
            } else {
                print("error!")
                
                //error!
                if let loginCompleteHandle = self.loginCompleteHandle {
                    let error = NSError(domain:"", code:999, userInfo:nil)
                    var loginUser = BGSocialLoginUser.init()
                    loginUser.sosial = .facebook
                    loginUser.error = error
                    loginCompleteHandle(loginUser)
                }
            }
        })
        
        /*
         FBSDKProfile.loadCurrentProfile { (profile, error) in
         if error != nil {
         print("need facebook login")
         return
         }
         
         if let profile = profile {
         //name
         let userName = profile.name ?? ""
         print("userName \(userName)")
         
         let userImageUrl = profile.imageURL(for: .normal, size: CGSize.init(width: 200, height: 200))
         print("userImageUrl \(userImageUrl)")
         
         
         if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"email"]) {
         // TODO: publish content.
         }
         } else {
         print("need facebook login")
         return
         }
         }
         */
    }
}

// MARK: - Google
extension BGLoginModel: GIDSignInUIDelegate, GIDSignInDelegate  {
    

    /**
     app delegate 의 다음 위치에 추가하기.
     func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
 */
    public static func setAppDelegateGoogleCallback(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        let urlStr = url.absoluteString
        if urlStr.contains("google") {
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication: sourceApplication,
                                                     annotation: annotation)
        }
        
        return false
    }
    
    func addGoogleLoginButton(wrapperView: UIView, clientId:String) {
        GIDSignIn.sharedInstance().clientID = clientId
        GIDSignIn.sharedInstance().signOut()
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        for view in wrapperView.subviews {
            //기존에 래퍼 안에 추가된 뷰들이 있다면 모두 이벤트 잡지 않도록 막는다.
            view.isUserInteractionEnabled = false
        }
        
        
        
        let button = GIDSignInButton.init(frame: CGRect.init())
        button.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        button.autoresizesSubviews = true
        //제일 뒤에 추가한다.
        wrapperView.insertSubview(button, at: 0)
        button.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(wrapperView)
            //make.height.equalTo(50)
        }
        
        //button.addTarget(self, action: #selector(invokeLoginWithTarget), for: .touchUpInside)
    }
    
    public func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        print("signIn present")
    }
    
    public func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        print("signIn dismiss")
    }
    
    public func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        print("signIn inWillDispatch")
        if let loginStatusHandle = self.loginStatusHandle {
            loginStatusHandle(.start, .google)
        }
    }
    
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            if let loginStatusHandle = self.loginStatusHandle {
                loginStatusHandle(.fail, .google)
            }
            // 로그인 에러 발생.
            if let loginCompleteHandle = self.loginCompleteHandle {
                var loginUser = BGSocialLoginUser.init()
                loginUser.sosial = .google
                loginUser.error = error
                loginCompleteHandle(loginUser)
            }
            return
        }
        
        //증명서가 발급됨.
        guard let authentication = user.authentication else { return }
        //발급된 증명서를 유저로 등록.
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        print(credential)
        
        if let accessToken = authentication.accessToken {
            
            var loginUser = BGSocialLoginUser.init()
            loginUser.sosial = .google
            loginUser.error = error
            loginUser.name = user.profile.name
            loginUser.email = user.profile.email
            loginUser.token = accessToken
            
            if user.profile.hasImage {
                loginUser.imageUrlStr = user.profile.imageURL(withDimension: 100)?.absoluteString
            } else {
                loginUser.imageUrlStr = ""
            }
            
            if let loginStatusHandle = self.loginStatusHandle {
                loginStatusHandle(.end, .google)
            }
            
            if let loginCompleteHandle = self.loginCompleteHandle {
                loginCompleteHandle(loginUser)
            }
            
        } else {
            print("구글로그인 실패. accesstoken 없음.")
            //self.showWarningDoneAlert("구글로그인에 실패했습니다. 관리자에게 문의해주세요.")
            GIDSignIn.sharedInstance().signOut()
            
            if let loginStatusHandle = self.loginStatusHandle {
                loginStatusHandle(.fail, .google)
            }
            
            if let loginCompleteHandle = self.loginCompleteHandle {
                var loginUser = BGSocialLoginUser.init()
                loginUser.sosial = .google
                loginUser.error = error
                loginCompleteHandle(loginUser)
            }
            
        }
    }
    
    public func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        if let loginStatusHandle = self.loginStatusHandle {
            loginStatusHandle(.fail, .google)
        }
        
        if let loginCompleteHandle = self.loginCompleteHandle {
            var loginUser = BGSocialLoginUser.init()
            loginUser.sosial = .google
            loginUser.error = error
            loginCompleteHandle(loginUser)
        }
    }
    
}

class CustomLoginButton:UIButton {
    var parentViewController:UIViewController?
}

