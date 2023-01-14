//
//  UserTests.swift
//  
//
//  Created by Karun Pant on 01/01/23.
//

import XCTVapor
@testable import App

final class UserTests: BaseTestSetup {
    
    let expectedName = "Test User"
    let expectedUserName = "TUSer"
    let pass = "password"
    
    func testUserRetrieval() throws {
        // insert
        let expectedUser = try User.createAndSave(name: expectedName,
                                              userName: expectedUserName,
                                              on: app.db)
        try expectedUser.save(on: app.db).wait()
        let anotherUser = User(name: "Testing Bob", uName: "TBob", password: pass, email: "test@email.com")
        try anotherUser.save(on: app.db).wait()
        
        // test
        try app.test(.GET, "\(User.apiBase)/all", afterResponse: { res in
            try expectationResponse(res, userCountExpectation: 2)
        })
    }
    
    func testCreateUser() throws {
        let expectedUser = User(name: expectedName, uName: expectedUserName, password: pass, email: "test@gmail.com")
        try app.test(.POST, User.apiBase, beforeRequest: { req in
            try req.content.encode(expectedUser)
        }, afterResponse: { response in
            let recievedUser = try response.content.decode(User.self)
            XCTAssertEqual(recievedUser.name, expectedName)
            XCTAssertEqual(recievedUser.uName, expectedUserName)
            XCTAssertNotNil(recievedUser.id)
            
            try app.test(.GET, "\(User.apiBase)/all", afterResponse: { res in
                try expectationResponse(res, userCountExpectation: 1)
            })
        })
    }
    
    func testGettingSingleUser() throws {
        let expectedUser = try User.createAndSave(name: expectedName,
                                              userName: expectedUserName,
                                              on: app.db)
        let id = try XCTUnwrap(expectedUser.id)
        try app.test(.GET, "\(User.apiBase)/by/\(id)", afterResponse: { res in
            let user = try res.content.decode(User.self)
            expectationUser(user)
        })
    }
}

private extension UserTests {
    func expectationResponse(_ res: XCTHTTPResponse,
                             userCountExpectation: Int,
                             file: StaticString = #file,
                             line: UInt = #line) throws {
        XCTAssertEqual(res.status, .ok, file: file, line: line)
        let users = try res.content.decode([User].self)
        XCTAssertEqual(users.count, userCountExpectation, file: file, line: line)
        expectationUser(users[0],
                       file: file,
                       line: line)
    }
    
    func expectationUser(_ user: User,
                        expectedName: String? = nil,
                        expectedUName: String? = nil,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let expectedName = expectedName ?? self.expectedName
        let expectedUName = expectedUName ?? self.expectedUserName
        XCTAssertEqual(user.name, expectedName, file: #file, line: #line)
        XCTAssertEqual(user.uName, expectedUName, file: #file, line: #line)
    }
}
