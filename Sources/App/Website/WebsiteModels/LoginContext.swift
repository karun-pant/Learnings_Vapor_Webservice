//
//  File.swift
//  
//
//  Created by Karun Pant on 05/01/23.
//

import Foundation

struct LoginContext: Encodable {
    let title = "Login"
    let loginError: Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}
