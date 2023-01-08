//
//  IndexContext.swift
//  
//
//  Created by Karun Pant on 02/01/23.
//

import Foundation

struct IndexContext: Encodable {
    let isLoggedIn: Bool
    let title: String
    let acronyms: [AcronymItem]
    let shouldShowCookieMessage: Bool
}
