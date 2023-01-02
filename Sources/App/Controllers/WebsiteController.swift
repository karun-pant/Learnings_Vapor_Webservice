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
    }
}

private extension WebsiteController {
    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        req.view.render("index")
    }
}
