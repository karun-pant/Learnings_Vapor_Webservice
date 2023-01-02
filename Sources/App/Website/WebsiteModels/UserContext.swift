//
//  UserContext.swift
//  
//
//  Created by Karun Pant on 02/01/23.
//

import Foundation

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]
}
