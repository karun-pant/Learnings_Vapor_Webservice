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
        routes.get("acronym", ":acronymID", "edit", use: editAcronym)
        routes.post("acronym", ":acronymID", "edit", use: editAcronymPost)
        routes.post("acronym", ":acronymID", "delete", use: deleteAcronym)
        routes.get("acronym", "create", use: createAcronym)
        routes.post("acronym", "create", use: createAcronymPost)
        routes.get("user", ":userID", use: userDetail)
        routes.get("user", "all", use: allUsersList)
        routes.get("category", "all", use: allCategories)
        routes.get("category", ":categoryID", use: categoryDetail)
    }
}

private extension WebsiteController {
    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        Acronym.query(on: req.db)
            .with(\.$user)
            .all()
            .flatMap({ acronyms in
                let response = AcronymResponse(acronyms: acronyms)
                let context = IndexContext(title: "Home Page", acronyms: response.acronyms)
                return req.view.render("index", context)
            })
    }
    func acronymDetail(_ req: Request) throws -> EventLoopFuture<View> {
        Acronym.find(req.parameters.get("acronymID", as: UUID.self), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                let users = acronym.$user.get(on: req.db)
                let categories = acronym.$categories.get(on: req.db)
                return users.and(categories)
                    .flatMap { user, categories in
                        let context = AcronymDetailContex(title: acronym.short,
                                                          acronym: acronym,
                                                          user: user,
                                                          categories: categories)
                        return req.view.render("AcronymDetail", context)
                    }
            }
    }
    
    func editAcronym(_ req: Request) throws -> EventLoopFuture<View> {
        let acronym = Acronym.find(req.parameters.get("acronymID", as: UUID.self), on: req.db)
            .unwrap(or: Abort(.notFound))
        let users = User.query(on: req.db)
            .all()
        return acronym.and(users).flatMap { acronym, users in
            acronym.$categories.get(on: req.db)
                .flatMap { categories in
                    let context = EditAcronymContext(acronym: acronym,
                                                     users: users,
                                                     categories: categories)
                    return req.view.render("CreateAcronym", context)
                }
        }
    }
    func deleteAcronym(_ req: Request) throws -> EventLoopFuture<Response> {
        let acronym = Acronym.find(req.parameters.get("acronymID", as: UUID.self), on: req.db)
            .unwrap(or: Abort(.notFound))
        return acronym.flatMap { acronym in
            let redirect = req.redirect(to: "/")
            return acronym.delete(on: req.db)
                .transform(to: redirect)
        }
    }
    
    func editAcronymPost(_ req: Request) throws -> EventLoopFuture<Response> {
        let dto = try req.content.decode(AcronymDTO.self)
        guard let acronymID = req.parameters.get("acronymID", as: UUID.self) else {
            throw Abort(.internalServerError)
        }
        return Acronym.find(acronymID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                
                acronym.long = dto.long
                acronym.short = dto.short
                acronym.$user.id = dto.userID
                return acronym.save(on: req.db)
                    .flatMap {
                        acronym.$categories.get(on: req.db)
                    }
                    .flatMap { existingCategories in
                        let existing = Set(existingCategories.compactMap { $0.name })
                        let new = Set(dto.categories ?? [])
                        let categoriesToAdd = new.subtracting(existing)
                        let categoriesToRemove = existing.subtracting(new)
                        var categoryResults: [EventLoopFuture<Void>] = []
                        //attach
                        for categoryName in categoriesToAdd {
                            categoryResults.append(
                                Category.attachCategory(name: categoryName,
                                                        to: acronym,
                                                        on: req)
                            )
                        }
                        // detach
                        for categoryName in categoriesToRemove {
                            let categoryToRemove = existingCategories.first(where: { $0.name == categoryName })
                            if let category = categoryToRemove {
                                categoryResults.append(
                                    acronym.$categories.detach(category, on: req.db)
                                )
                            }
                        }
                        let redirect = req.redirect(to: "/acronym/\(acronymID)")
                        return categoryResults.flatten(on: req.eventLoop)
                            .transform(to: redirect)
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
    func categoryDetail(_ req: Request) throws -> EventLoopFuture<View> {
        Category.find(req.parameters.get("categoryID", as: UUID.self), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { category in
                category.$acronyms.get(on: req.db)
                    .flatMap { acronyms in
                        let context = CategoryContext(title: category.name,
                                                      category: category,
                                                      acronyms: acronyms)
                        return req.view.render("CategoryDetail", context)
                    }
            }
    }
    
    func createAcronym(_ req: Request) throws -> EventLoopFuture<View> {
        let userQuery = User.query(on: req.db) .all()
        
        return userQuery
            .flatMap { users in
                let context = CreateAcronymContext(users: users)
                return req.view.render("CreateAcronym", context)
            }
    }
    
    func createAcronymPost(_ req: Request) throws -> EventLoopFuture<Response> {
        let dto = try req.content.decode(AcronymDTO.self)
        let acronym = Acronym(short: dto.short,
                              long: dto.long,
                              userID: dto.userID)
        return acronym.save(on: req.db)
            .flatMap {
                guard let id = acronym.id else {
                    return req.eventLoop.future(error: Abort(.internalServerError))
                }
                var categoryQueries: [EventLoopFuture<Void>] = []
                for category in dto.categories ?? [] {
                    categoryQueries.append(
                        Category.attachCategory(name: category,
                                                to: acronym,
                                                on: req)
                    )
                }
                let redirects = req.redirect(to: "/acronym/\(id)")
                return categoryQueries
                    .flatten(on: req.eventLoop)
                    .transform(to: redirects)
            }
    }
}
