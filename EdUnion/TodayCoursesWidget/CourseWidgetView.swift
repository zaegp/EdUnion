////
////  CourseWidgetView.swift
////  EdUnion
////
////  Created by Rowan Su on 2024/9/22.
////
//
//import SwiftUI
//
//struct CourseWidgetView: View {
//    var entry: Provider.Entry
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text("Today's Courses")
//                .font(.headline)
//            ForEach(entry.courses, id: \.title) { course in
//                HStack {
//                    Text(course.title)
//                        .font(.subheadline)
//                    Spacer()
//                    Text(course.time)
//                        .font(.subheadline)
//                }
//            }
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    CourseWidgetView()
//}
