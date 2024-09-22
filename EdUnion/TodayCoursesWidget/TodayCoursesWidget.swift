////
////  TodayCoursesWidget.swift
////  TodayCoursesWidget
////
////  Created by Rowan Su on 2024/9/22.
////
//
//import WidgetKit
//import SwiftUI
//
//struct CourseEntry: TimelineEntry {
//    let date: Date
//    let courses: [Courses]
//}
//
//struct Courses {
//    var title: String
//    var time: String
//}
//
//struct Provider: TimelineProvider {
//    
//    func placeholder(in context: Context) -> CourseEntry {
//        CourseEntry(date: Date(), courses: [])
//    }
//
//    func getSnapshot(in context: Context, completion: @escaping (CourseEntry) -> Void) {
//        let sampleCourses = [
//            Courses(title: "Math", time: "10:00 AM"),
//            Courses(title: "Science", time: "12:00 PM")
//        ]
//        let entry = CourseEntry(date: Date(), courses: sampleCourses)
//        completion(entry)
//    }
//
//    func getTimeline(in context: Context, completion: @escaping (Timeline<CourseEntry>) -> Void) {
//        // 從您的 viewModel 中獲取課程數據
//        let viewModel = TodayCoursesViewModel()
//        viewModel.fetchTodayAppointments()
//
//        let courses = viewModel.appointments.map { appointment in
//            Courses(title: appointment.title, time: TimeService.convertCourseTimeToDisplay(from: appointment.times))
//        }
//
//        let entry = CourseEntry(date: Date(), courses: courses)
//
//        // 創建 timeline，刷新間隔可根據需要調整
//        let timeline = Timeline(entries: [entry], policy: .atEnd)
//        completion(timeline)
//    }
//}
//
//#Preview(as: .systemSmall) {
//    TodayCoursesWidget()
//} timeline: {
//    SimpleEntry(date: .now, configuration: .smiley)
//    SimpleEntry(date: .now, configuration: .starEyes)
//}
