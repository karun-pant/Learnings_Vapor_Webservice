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
