//
//  CreateAcroCatPivot.swift
//
//
//  Created by Karun Pant on 29/12/22.
//

import FluentKit
import Vapor

struct CreateAcroCatPivot: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(AcronymCategoryPivot.schema)
      .id()
      .field("acronymID",
        .uuid,
        .required,
             .references(Acronym.schema,
                         "id",
                         onDelete: .cascade))
      
      .field("categoryID",
        .uuid,
        .required,
             .references(Category.schema,
                         "id",
                         onDelete: .cascade))
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema(AcronymCategoryPivot.schema).delete()
  }
}
