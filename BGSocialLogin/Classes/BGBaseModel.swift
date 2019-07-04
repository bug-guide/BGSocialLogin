//
//  BaseModel.swift
//  LastOrder
//
//  Created by HacJune Lee on 26/05/2019.
//  Copyright © 2019 HacJune Lee. All rights reserved.
//

import UIKit
import Alamofire
import SystemConfiguration

extension Error {
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
}


struct BGBaseErrorCodable:Codable {
    ///code의 벨류값이 int 였다가, string 이었다가 왔다갔다한다.아예 파싱하지말고 status로 보자.
    //var code:Int? {get set}
    var msg:String?
    var status:String?
    
    static func baseErrorMessagePasing(data:Data) -> String? {
        let decoder = JSONDecoder()
        do {
            let decodeData = try decoder.decode(BGBaseErrorCodable.self, from: data)
            if let msg = decodeData.msg {
                return msg
            }
        } catch {
            return nil
        }
        
        return nil
    }
}

public class BGBaseModel: NSObject {
    
    var sessionManager: SessionManager?
    
    static let SCHEME = "https://"
    ///www....
    static let HOST = ""
    
    let storeUrlString:String = ""
    let queue = DispatchQueue(label: "com.BGLoginModule", qos: .utility, attributes: [.concurrent])
    
    override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        sessionManager = Alamofire.SessionManager(configuration: configuration) // not in this line
    }
    
    func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        /* Only Working for WIFI
         let isReachable = flags == .reachable
         let needsConnection = flags == .connectionRequired
         
         return isReachable && !needsConnection
         */
        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
        
    }
    
    func publicHeader() -> HTTPHeaders {
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
        return headers
    }
    
    func publicRequestJsonData(request:DataRequest, complete:@escaping ((Data?, Error?)->Void)) {
        if let re = request.request {
            print("\n🐼 request : \(re)\n")
        }
        
        if !isConnectedToNetwork() {
            DispatchQueue.main.async {
                self.showNetworkMessage("앱을 사용하시려면 스마트폰이 네트워크에 반드시 연결되어 있어야 합니다.")
                complete(nil, nil)
            }
            return
        }
        
        request.validate(statusCode: 200..<500).responseJSON(queue: queue, options: .allowFragments) { (dataResponse) in
            
            switch dataResponse.result {
            case .success(let value):
                
                print("success \(value)\n\n")
                if value == nil {
                    DispatchQueue.main.async {
                        complete(nil, nil)
                    }
                    return
                }
                do {
                    let dataJson = try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
                    DispatchQueue.main.async {
                        complete(dataJson, nil)
                    }
                } catch {
                    complete(nil, nil)
                }
                
                return
            case .failure(let error):
                print("error \(error)\n\n")
                
                if error.code == -999 {
                    //취소됨
                    DispatchQueue.main.async {
                        complete(nil, error)
                    }
                } else {
                    DispatchQueue.main.async {
                        //MDCSnackbarManager().showSimpleMessage("\(error)")
                        self.showNetworkMessage("잠시 후 다시 시도해주세요.")
                        complete(nil, error)
                    }
                }
                
                return
            }
        }
    }
    
    func showNetworkMessage(_ message:String) {
        print("error \(message)\n\n")
    }
    
}
