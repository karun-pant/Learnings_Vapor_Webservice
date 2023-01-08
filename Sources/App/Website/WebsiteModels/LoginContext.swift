//
//  File.swift
//  
//
//  Created by Karun Pant on 05/01/23.
//

import Vapor

struct LoginContext: Encodable {
    let title = "Login"
    let loginError: Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct RegisterContext: Encodable {
    let title = "Register"
    let message: String?
    init(message: String? = nil) {
        self.message = message
    }
}

struct UserDTO: Content {
    let name: String
    let userName: String
    let password: String
    let confirmPassword: String
}

extension UserDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .ascii)
        validations.add("userName", as: String.self, is: .alphanumeric && .count(3...))
        validations.add("password", as: String.self, is: .count(8...))
    }
}
