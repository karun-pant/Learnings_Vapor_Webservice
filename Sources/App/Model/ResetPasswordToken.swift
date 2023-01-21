//
//  ResetPasswordToken.swift
//  
//
//  Created by Karun Pant on 21/01/23.
//

import Vapor
import Fluent

final class ResetPasswordToken: Model, Content {
    
    static let schema = "resetPasswordTokens"
    
    @ID
    var id: UUID?
    
    @Field(key: "token")
    var token: String
    
    @Parent(key: "userID")
    var user: User
    
    init() {}
    
    init(id: UUID? = nil,
         token: String,
         userID: UUID) {
        self.id = id
        self.token = token
        $user.id = userID
    }
}

