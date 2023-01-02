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
}

struct CreateAcronymContext: Encodable {
    let title: String = "Create an Acronym"
    let users: [User]
}

struct EditAcronymContext: Encodable {
  // 1
  let title = "Edit Acronym"
  // 2
  let acronym: Acronym
  // 3
  let users: [User]
  // 4
  let isEditing = true
}
