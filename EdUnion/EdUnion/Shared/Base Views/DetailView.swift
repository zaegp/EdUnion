//
//  DetailView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/21.
//

import SwiftUI

struct DetailView: View {
    let appointment: Appointment  // 需要傳遞的預約數據

    var body: some View {
        VStack(alignment: .leading) {
            Text("Student ID: \(appointment.studentID)")
                .font(.title2)
                .padding()

            Text("Appointment Time: \(TimeService.convertCourseTimeToDisplay(from: appointment.times))")
                .font(.body)
                .padding()

            // 根據需要展示其他預約詳情
            Spacer()
        }
        .navigationTitle("Appointment Details")
        .padding()
    }
}

//#Preview {
//    DetailView()
//}
