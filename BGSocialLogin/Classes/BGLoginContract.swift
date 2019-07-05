//
//  LoginContract.swift
//  LastOrder
//
//  Created by HacJune Lee on 26/05/2019.
//  Copyright © 2019 HacJune Lee. All rights reserved.
//

import UIKit

public struct BGSocialLoginUser {
    public var sosial:BGSocial? = .none
    public var name:String?
    public var email:String?
    public var phone:String?
    public var imageUrlStr:String?
    public var token:String?
    public var error:Error?
}

public enum BGSocialLoginStatus {
    case start
    case end
    case fail
}

public protocol BGLoginContract_View {
    
    func startLoading(_ sosial:BGSocial)
    func endLoading(_ sosial:BGSocial)
    func failLoading(_ sosial:BGSocial)
    
    /**
     소셜 로그인이 진행하고 결과를 반환한다.
     - Parameters:
        - social : 로그인을 진행한 플랫폼정보
        - email : 사용자의 이메일정보(선택)
        - phoneNumber : 사용자의 전화번호(선택)
        - error : 에러여부
     */
    func responseSosialLogin(_ loginUser:BGSocialLoginUser)
}

public protocol BGLoginContract_Presenter {
    
    ///카카오의 로그인 버튼을 지정한 뷰에 fit 하여 추가한다.
    func addKakaoLoginButton(wrapperView:UIView)
    func addNaverLoginButton(wrapperView:UIView)
    func addGoogleLoginButton(wrapperView:UIView, clientId:String)
    func addFacebookLoginButton(wrapperView:UIView, superViewController:UIViewController)
}

public class BGLoginContract: NSObject {
    public override init() { }
}
