//
//  CategoryContext.swift
//  
//
//  Created by Karun Pant on 02/01/23.
//

import Foundation

struct AllCategoriesContext: Encodable {
    let title: String
    let categories: [Category]
}
