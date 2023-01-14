//
//  UserContext.swift
//  
//
//  Created by Karun Pant on 02/01/23.
//

import Vapor

struct UserContext: Encodable {
    let title: String = "Profile"
    let user: User
    let acronyms: [Acronym]
    let isEditing: Bool
    let error: String?
    let csrf: String?
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct GoogleUserInfo: Content {
    let email: String
    let name: String
    var userName: String {
        email.components(separatedBy: "@").first ?? email
    }
}

struct ProfileDTO: Content {
    let name: String
    let email: String
    let csrf: String
}

extension ProfileDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .ascii)
        validations.add("email", as: String.self, is: .email)
    }
}
