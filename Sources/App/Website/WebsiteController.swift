//
//  WebsiteController.swift
//  
//
//  Created by Karun Pant on 02/01/23.
//

import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: indexHandler)
        routes.get("acronym", ":acronymID", use: acronymDetail)
        routes.get("user", ":userID", use: userDetail)
        routes.get("user", "all", use: allUsersList)
        routes.get("category", "all", use: allCategories)
    }
}

private extension WebsiteController {
    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        Acronym.query(on: req.db)
            .all()
            .flatMap { acronyms in
                let context = IndexContext(title: "Home Page", acronyms: acronyms)
                return req.view.render("index", context)
            }
    }
    func acronymDetail(_ req: Request) throws -> EventLoopFuture<View> {
        Acronym.find(req.parameters.get("acronymID", as: UUID.self), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.$user.get(on: req.db)
                    .flatMap { user in
                        let context = AcronymDetailContex(title: acronym.short,
                                                          acronym: acronym,
                                                          user: user)
                        return req.view.render("AcronymDetail", context)
                    }
            }
    }
    func userDetail(_ req: Request) throws -> EventLoopFuture<View> {
        User.find(req.parameters.get("userID", as: UUID.self), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$acronyms.get(on: req.db)
                    .flatMap { acronyms in
                        let context = UserContext(title: user.name,
                                                  user: user,
                                                  acronyms: acronyms)
                        return req.view.render("UserDetail", context)
                    }
            }
    }
    func allUsersList(_ req: Request) throws -> EventLoopFuture<View> {
        User.query(on: req.db)
            .all()
            .flatMap { users in
                let context = AllUsersContext(title: "Users",
                                              users: users)
                return req.view.render("AllUsers", context)
            }
    }
    func allCategories(_ req: Request) throws -> EventLoopFuture<View> {
        Category.query(on: req.db)
            .all()
            .flatMap { categories in
                let context = AllCategoriesContext(title: "Categories",
                                                   categories: categories)
                return req.view.render("AllCategories", context)
            }
    }
}
