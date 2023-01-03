//
//  AcronymDetailContex.swift
//  
//
//  Created by Karun Pant on 02/01/23.
//

import Foundation

struct AcronymDetailContex: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
    let categories: [Category]
}

struct CreateAcronymContext: Encodable {
    let title: String = "Create an Acronym"
    let users: [User]
}

struct EditAcronymContext: Encodable {
    let title = "Edit Acronym"
    let acronym: Acronym
    let users: [User]
    let categories: [Category]
    let isEditing = true
}
