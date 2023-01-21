//
//  ResetPasswordContext.swift
//  
//
//  Created by Karun Pant on 21/01/23.
//

import Vapor

struct ResetPasswordContext: Encodable {
    let title: String = "Update Password"
    let error: String?
    init(error: String? = nil) {
        self.error = error
    }
}

struct ResetPasswordData: Content {
    let password: String
    let confirmPassword: String
}
