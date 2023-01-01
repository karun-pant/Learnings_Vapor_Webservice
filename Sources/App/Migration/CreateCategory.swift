//
//  CreateCategory.swift
//
//
//  Created by Karun Pant on 29/12/22.
//

import FluentKit
import Vapor

struct CreateCategory: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(Category.schema)
      .id()
      .field("name", .string, .required)
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema(Category.schema).delete()
  }
}
