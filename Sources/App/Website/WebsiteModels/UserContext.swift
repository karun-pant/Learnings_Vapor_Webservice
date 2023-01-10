//
//  UserContext.swift
//  
//
//  Created by Karun Pant on 02/01/23.
//

import Vapor

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct GoogleUserInfo: Content {
    let email: String
    let name: String
}
