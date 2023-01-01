//
//  UserTests.swift
//  
//
//  Created by Karun Pant on 01/01/23.
//

import XCTVapor
@testable import App

final class UserTests: XCTestCase {
    
    let baseURL = "/api/v1/user"
    var app: Application!
    let expectedName = "Test User"
    let expectedUserName = "TUSer"
    var expectedUser: User {
        User(name: expectedName, uName: expectedUserName)
    }
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app = try Application.configureForTest()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app.shutdown()
    }
    
    func testUserRetrieval() throws {
        // insert
        try expectedUser.save(on: app.db).wait()
        let anotherUser = User(name: "Testing Bob", uName: "TBob")
        try anotherUser.save(on: app.db).wait()
        
        // test
        try app.test(.GET, "\(baseURL)/all", afterResponse: { res in
            try expectationResponse(res, userCountExpectation: 2)
        })
    }
    
    func testCreateUser() throws {
        try app.test(.POST, baseURL, beforeRequest: { req in
            try req.content.encode(expectedUser)
        }, afterResponse: { response in
            let recievedUser = try response.content.decode(User.self)
            XCTAssertEqual(recievedUser.name, expectedName)
            XCTAssertEqual(recievedUser.uName, expectedUserName)
            XCTAssertNotNil(recievedUser.id)
            
            try app.test(.GET, "\(baseURL)/all", afterResponse: { res in
                try expectationResponse(res, userCountExpectation: 1)
            })
        })
    }
    
    func testGettingSingleUser() throws {
        let user = expectedUser
        try user.save(on: app.db).wait()
        let id = try XCTUnwrap(user.id)
        try app.test(.GET, "\(baseURL)/by/\(id)", afterResponse: { res in
            let user = try res.content.decode(User.self)
            expecationUser(user)
        })
    }
    
    private func expectationResponse(_ res: XCTHTTPResponse,
                                 userCountExpectation: Int,
                                 file: StaticString = #file,
                                 line: UInt = #line) throws {
        XCTAssertEqual(res.status, .ok, file: file, line: line)
        let users = try res.content.decode([User].self)
        XCTAssertEqual(users.count, userCountExpectation, file: file, line: line)
        expecationUser(users[0],
                       file: file,
                       line: line)
    }
    
    private func expecationUser(_ user: User,
                                file: StaticString = #file,
                                line: UInt = #line) {
        XCTAssertEqual(user.name, expectedName, file: #file, line: #line)
        XCTAssertEqual(user.uName, expectedUserName, file: #file, line: #line)
    }
}
