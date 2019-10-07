//
//  LoginPresenter.swift
//  LastOrder
//
//  Created by HacJune Lee on 26/05/2019.
//  Copyright © 2019 HacJune Lee. All rights reserved.
//

import UIKit

public enum BGSocial: String {
    case kakao = "Kakao"
    case naver = "Naver"
    case facebook = "Facebook"
    case google = "Google"
}

public class BGLoginPresenter: NSObject {
    var model: BGLoginModel
    var view: BGLoginContract_View?
    
    public init(model:BGLoginModel) {
        self.model = model
    }
    
    public func attachView(view: BGLoginContract_View) {
        self.view = view
        
        //뷰를 지정한 후 모델의 완료햔들을 셋팅.
        self.model.loginCompleteHandle = { loginUser in
            DispatchQueue.main.async {
                //모델을 통해 들어온 소셜로그인 완료정보를 뷰로 전달한다.
                self.view?.responseSosialLogin(loginUser)
            }
        }
        
        self.model.loginStatusHandle = { status, social in
            //print("\(status), \(social)")
            DispatchQueue.main.async {
                if status == .start {
                    self.view?.startLoading(social)
                } else if status == .end {
                    self.view?.endLoading(social)
                } else {
                    self.view?.failLoading(social)
                }
            }
        }
    }
}

extension BGLoginPresenter: BGLoginContract_Presenter {
    
    public func addKakaoLoginButton(wrapperView:UIView) {
        //로그인 버튼을 생성하여 랩퍼로 세팅.
        model.addKakaoLoginButton(wrapperView: wrapperView)
    }
    
    public func addNaverLoginButton(wrapperView:UIView) {
        model.addNaverLoginButton(wrapperView: wrapperView)
    }
    
    public func addGoogleLoginButton(wrapperView: UIView, clientId:String) {
        model.addGoogleLoginButton(wrapperView: wrapperView, clientId: clientId)
    }
    
    /*
    public func addFacebookLoginButton(wrapperView:UIView, superViewController:UIViewController) {
        model.addFacebookLoginButton(wrapperView: wrapperView, superViewController: superViewController)
    }
     */
}

