//
// VizbeeSigninAdapter.swift
// This is the template for writing Vizbee SigninAdapter
//
import Foundation

class VizbeeSigninAdapter: NSObject {
    
    /**
      This adapter method is invoked by the Vizbee SDK on connection to 
      a new device to get user signin info. The returned signin info is sent
      to the receiver for automatic signin.

      - Return : A dictionary with fields 
                    {
                        "userId" : "<required id for user>", 
                        "userLogin" : "<required login for user>", 
                        "userFullName" : "<required fullname for user>", // this is shown in the welcome message on receiver
                        "accessToken" : "<accessToken for user>", // one of access or refresh token must be included
                        "refreshToken" : "<refreshToken for user>", // one of access or refresh token must be included
                    }
    */
    func getSigninInfo(completionHandler: @escaping ([AnyHashable: Any]?) -> Void) {
        
        // EXAMPLE:
        /*
         AccountManager.shared().session?.getRefreshToken().done({ obj in
                 let refreshToken = obj?.token
                 DispatchQueue.main.async {
                     let userInfo = [
                         "userId": AccountManager.shared().profileId ?? "",
                         "userLogin": AccountManager.shared().userEmail ?? "",
                         "userFullName": AccountManager.shared().profileName ?? "",
                         "accessToken": AccountManager.shared().accessToken ?? "",
                         "refreshToken": refreshToken ?? ""
                     ]
                     completionHandler(userInfo)
                 }
             }, rejected: { _ in
                     DispatchQueue.main.async {
                         completionHandler(nil)
                     }
             })
         */
        
        
        // default
        completionHandler(nil)
    }
}
