//
//  EdUnionTests.swift
//  EdUnionTests
//
//  Created by Rowan Su on 2024/9/11.
//

import XCTest
@testable import EdUnion

class MockUserFirebaseService: UserFirebaseServiceProtocol {
    var followList: [String]?
    var error: Error?
    
    func getStudentFollowList(studentID: String, completion: @escaping ([String]?, Error?) -> Void) {
        completion(followList, error)
    }
}

class TeacherDetailVCTests: XCTestCase {
    var viewController: TeacherDetailVC!
    var mockService: MockUserFirebaseService!
    
    override func setUp() {
        super.setUp()
        viewController = TeacherDetailVC()
        mockService = MockUserFirebaseService()
        viewController.userFirebaseService = mockService
        viewController.teacher = Teacher(
            id: "teacher1",
            userID: "user1",
            fullName: "測試老師",
            photoURL: nil,
            totalCourses: 5,
            resume: ["博士", "5年經驗", "擅長數學", "數學", "高等數學"]
        )
        _ = viewController.view
    }
    
    override func tearDown() {
        viewController = nil
        mockService = nil
        super.tearDown()
    }
    
    func testCheckIfTeacherIsFavorited_WhenTeacherIsInFollowList_ShouldSetIsFavoriteTrue() {
        mockService.followList = ["teacher1", "teacher2"]
        
        viewController.testable_checkIfTeacherIsFavorited()
        
        XCTAssertTrue(viewController.testable_getIsFavorite(), "isFavorite 應該為 true")
    }
    
    func testCheckIfTeacherIsFavorited_WhenTeacherIsNotInFollowList_ShouldSetIsFavoriteFalse() {
        mockService.followList = ["teacher2", "teacher3"]
        
        viewController.testable_checkIfTeacherIsFavorited()

        XCTAssertFalse(viewController.testable_getIsFavorite(), "isFavorite 應該為 false")
    }
    
    func testCheckIfTeacherIsFavorited_WhenErrorOccurs_ShouldNotSetIsFavorite() {
        mockService.followList = nil
        mockService.error = NSError(domain: "TestError", code: 1, userInfo: nil)
        
        viewController.testable_checkIfTeacherIsFavorited()

        XCTAssertFalse(viewController.testable_getIsFavorite(), "isFavorite 應該保持 false")
    }
}
