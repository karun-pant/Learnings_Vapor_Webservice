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
    let previousURI: String
    
    init(loginError: Bool = false,
         previousURI: String) {
        self.loginError = loginError
        self.previousURI = previousURI
    }
}

struct RegisterContext: Encodable {
    let title = "Register"
    let message: String?
    let previousURI: String
    init(message: String? = nil,
         previousURI: String = "") {
        self.message = message
        self.previousURI = previousURI
    }
}

struct UserDTO: Content {
    let name: String
    let userName: String
    let password: String
    let confirmPassword: String
    let email: String
}

extension UserDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .ascii)
        validations.add("userName", as: String.self, is: .alphanumeric && .count(3...))
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("email", as: String.self, is: .email)
    }
}
