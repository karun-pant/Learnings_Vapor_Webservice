//
//  BaseTestSetup.swift
//  
//
//  Created by Karun Pant on 05/01/23.
//

@testable import App
import XCTVapor
import Fluent

extension Application {
    static func configureForTest() throws -> Application {
        let app = Application(.testing)
        try configure(app)
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
        return app
    }
}

class BaseTestSetup: XCTestCase {

    var app: Application!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app = try Application.configureForTest()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app.shutdown()
    }

}
