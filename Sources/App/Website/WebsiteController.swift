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
        routes.get("login" ,use: login)
        /// This creates a route group that runs DatabaseSessionAuthenticator before the route handlers. This middleware reads the cookie from the request and looks up the session ID in the application’s session list. If the session contains a user, DatabaseSessionAuthenticator adds it to the request’s authentication cache, making the user available later in the process.
        let authSessionRoutes = routes.grouped(User.sessionAuthenticator())
        let credentialAuthRoutes = authSessionRoutes.grouped(User.credentialsAuthenticator())
        credentialAuthRoutes.post("login", use: loginHandler)
        
        /// Adding all routes where user might be needed to `authSessionRoutes` makes the User available to these pages. This is useful for displaying user-specific content, such as a profile link, on any page you desire.
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("acronym", ":acronymID", use: acronymDetail)
        authSessionRoutes.get("acronym", ":acronymID", "edit", use: editAcronym)
        authSessionRoutes.get("user", ":userID", use: userDetail)
        authSessionRoutes.get("user", "all", use: allUsersList)
        authSessionRoutes.get("category", "all", use: allCategories)
        authSessionRoutes.get("category", ":categoryID", use: categoryDetail)
        authSessionRoutes.post("logout", use: logout)
        authSessionRoutes.get("register", use: registerRender)
        authSessionRoutes.post("register", use: registerPost)
        
        
        /// “This creates a new route group, extending from authSessionsRoutes, that includes RedirectMiddleware for User. The application runs a request through RedirectMiddleware before it reaches the route handler, but after DatabaseSessionAuthenticator. This allows RedirectMiddleware to check for an authenticated user. RedirectMiddleware requires you to specify the path for redirecting unauthenticated users.
        let protectedRoutes = authSessionRoutes.grouped(User.redirectMiddleware(path: "/login"))
        protectedRoutes.post("acronym", ":acronymID", "edit", use: editAcronymPost)
        protectedRoutes.post("acronym", ":acronymID", "delete", use: deleteAcronym)
        protectedRoutes.get("acronym", "create", use: createAcronym)
        protectedRoutes.post("acronym", "create", use: createAcronymPost)
    }
}

//MARK: - Login

private extension WebsiteController {
    func login(_ req: Request) throws -> EventLoopFuture<View> {
        let context: LoginContext
        if let error = req.query[Bool.self, at: "error"], error {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        return req.view.render("login", context)
    }
    func loginHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        if req.auth.has(User.self) {
            return req.eventLoop.future(req.redirect(to: "/"))
        } else {
            let context = LoginContext(loginError: true)
            return req.view.render("login", context)
                .encodeResponse(for: req)
        }
    }
    func logout(_ req: Request) throws -> Response {
        req.auth.logout(User.self)
        return req.redirect(to: "/")
    }
}

// MARK: - Register

private extension WebsiteController {
    func registerRender(_ req: Request) throws -> EventLoopFuture<View> {
        let context: RegisterContext
        if let message = try? req.query.get(String.self ,at: "message") {
            context = RegisterContext(message: message)
        } else {
            context = RegisterContext()
        }
        return req.view.render("register", context)
    }
    func registerPost(_ req: Request) throws -> EventLoopFuture<Response> {
        do {
            try UserDTO.validate(content: req)
        } catch let error as ValidationsError {
            let message = error.description.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Unknown Error"
            return req.eventLoop.future(req.redirect(to: "/register?message=\(message)"))
        }
        let registerDTO = try req.content.decode(UserDTO.self)
        let password = try Bcrypt.hash(registerDTO.password)
        let user = User(name: registerDTO.name, uName: registerDTO.userName, password: password)
        return user.save(on: req.db)
            .map {
                req.auth.login(user)
                return req.redirect(to: "/")
            }
    }
}

// MARK: - Acronym

private extension WebsiteController {
    
    func createAcronym(_ req: Request) throws -> EventLoopFuture<View> {
        let csrf = [UInt8].random(count: 16).base64
        let context: CreateAcronymContext
        if let errorMessage = try? req.query.get(String.self ,at: "error") {
            context = CreateAcronymContext(csrf: csrf, error: errorMessage)
        } else {
            context = CreateAcronymContext(csrf: csrf)
        }
        req.session.data["CSRF_TOKEN"] = csrf
        return req.view.render("CreateAcronym", context)
    }
    
    func createAcronymPost(_ req: Request) throws -> EventLoopFuture<Response> {
        let dto = try req.content.decode(AcronymDTO.self)
        let expectedToken = req.session.data["CSRF_TOKEN"]
        // clear token once used we will create a new one everytime.
        req.session.data["CSRF_TOKEN"] = nil
        guard let expectedToken = expectedToken,
              let csrfFromDTO = dto.csrf,
              csrfFromDTO == expectedToken else {
            throw Abort(.unauthorized)
        }
        let user = try req.auth.require(User.self)
        let acronym = try Acronym(short: dto.short,
                                  long: dto.long,
                                  userID: user.requireID())
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
            }.flatMapError { _ in
                let redirects = req.redirect(to: "/acronym/create?error=Acronym is already created. Try adding something new.")
                return req.eventLoop.future(redirects)
            }
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
        return acronym.flatMap { acronym in
            acronym.$categories.get(on: req.db)
                .flatMap { categories in
                    let context = EditAcronymContext(acronym: acronym,
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
    
}

private extension WebsiteController {
    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        Acronym.query(on: req.db)
            .with(\.$user)
            .all()
            .flatMap({ acronyms in
                let isUserLoggedin = req.auth.has(User.self)
                let response = AcronymResponse(acronyms: acronyms)
                let shouldShowCookieMessage = req.cookies["cookies-accepted"] == nil
                let context = IndexContext(isLoggedIn: isUserLoggedin,
                                           title: "Home Page",
                                           acronyms: response.acronyms,
                                           shouldShowCookieMessage: shouldShowCookieMessage)
                return req.view.render("index", context)
            })
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
}
