//
//  ViewController.swift
//  BGSocialLogin
//
//  Created by bugguide@gmail.com on 06/23/2019.
//  Copyright (c) 2019 bugguide@gmail.com. All rights reserved.
//

import UIKit
import Toaster
import Firebase
import BGSocialLogin

class ViewController: UIViewController {
    
    var socials:[BGSocial] = [BGSocial.kakao, BGSocial.naver, BGSocial.google]
    var presenter = BGLoginPresenter.init(model: BGLoginModel())
    
    @IBOutlet weak var vIndicator: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        //TestCall().TestLog("testCall")
        presenter.attachView(view: self)
        tableView.reloadData()
        
        vIndicator.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return socials.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SocialCell") as! SocialCell
        let social = socials[indexPath.row]
        cell.setCellData(social: social, parentVC:self, presenter: presenter)
        return cell
    }
}

extension ViewController: BGLoginContract_View {
    func startLoading(_ sosial: BGSocial) {
        vIndicator.isHidden = false
        indicator.startAnimating()
    }
    
    func endLoading(_ sosial: BGSocial) {
        vIndicator.isHidden = true
        indicator.stopAnimating()
    }
    
    func failLoading(_ sosial: BGSocial) {
        vIndicator.isHidden = true
        indicator.stopAnimating()
    }
    
    func responseSosialLogin(_ loginUser: BGSocialLoginUser) {
        let message = "loginUser : \(loginUser)"
        Toast.init(text: message).show()
    }
}

class SocialCell: UITableViewCell {
    
    @IBOutlet weak var vWrapper: UIView!
    @IBOutlet weak var lbTitle: UILabel!
    
    func setCellData(social:BGSocial, parentVC:UIViewController, presenter:BGLoginPresenter) {
        //타이틀 셋팅
        let text = social.rawValue
        lbTitle.text = text
        
        for child in vWrapper.subviews {
            if child != lbTitle {
                child.removeFromSuperview()
            }
        }
        
        lbTitle.backgroundColor = UIColor.clear
        switch social {
        case .kakao:
            presenter.addKakaoLoginButton(wrapperView: vWrapper)
            lbTitle.backgroundColor = UIColor.yellow
            break
        case .google:
            if let clientId = FirebaseApp.app()?.options.clientID {
                presenter.addGoogleLoginButton(wrapperView: vWrapper, clientId: clientId)
            }
            lbTitle.backgroundColor = UIColor.white
            break
        case .facebook:
            
            lbTitle.backgroundColor = UIColor.white
            break
        default:
            lbTitle.backgroundColor = UIColor.red.withAlphaComponent(0.5)
            break
        }
    }
}
