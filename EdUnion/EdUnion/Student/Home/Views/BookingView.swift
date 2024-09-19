//
//  BookingView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/15.
//

import SwiftUI
import FirebaseCore

struct BookingView: View {
    let selectedTimeSlots: [String: String]
    let timeSlots: [AvailableTimeSlot]
    
    @State private var selectedDate: String?
    @State private var selectedTimes: [String] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var availableDates: [String] {
        return Array(selectedTimeSlots.keys).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.flexible())], spacing: 15) {
                        ForEach(availableDates, id: \.self) { date in
                            Button(action: {
                                selectedDate = date
                                selectedTimes = []
                            }) {
                                Text(date)
                                    .padding()
                                    .background(selectedDate == date ? .mainOrange : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedDate == date ? .white : .black)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                
                if let selectedDate = selectedDate, let colorHex = selectedTimeSlots[selectedDate] {
                    let slotsForDate = timeSlots.filter { $0.colorHex == colorHex }
                    
                    if slotsForDate.isEmpty {
                        Text("無可用時間段")
                            .padding()
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 20) {
                                ForEach(slotsForDate.flatMap { generateTimeSlots(from: $0.timeRanges) }, id: \.self) { timeSlot in
                                    Button(action: {
                                        toggleSelection(of: timeSlot)
                                    }) {
                                        Text(timeSlot)
                                            .frame(height: 50)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedTimes.contains(timeSlot) ? .mainOrange : .background)
                                            .foregroundColor(selectedTimes.contains(timeSlot) ? .white : .black)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    Text("請選擇日期")
                        .padding()
                }
                
                Spacer()
                
                Button(action: submitBooking) {
                    Text("提交預約")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background((selectedDate != nil && !selectedTimes.isEmpty) ? Color(UIColor(resource: .mainOrange)) : Color.gray)
                        .cornerRadius(10)
                        .padding([.horizontal, .bottom])
                }
                .disabled(selectedDate == nil || selectedTimes.isEmpty)
            }
            .navigationBarTitle("預約", displayMode: .inline)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("通知"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
            }
        }
    }
    
//    func formattedDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        return formatter.string(from: date)
//    }
    
    func generateTimeSlots(from timeRanges: [String]) -> [String] {
        var timeSlots: [String] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        for range in timeRanges {
            let times = range.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            
            if let startTime = dateFormatter.date(from: String(times[0])),
               let endTime = dateFormatter.date(from: String(times[1])) {
                var currentTime = startTime
                
                while currentTime < endTime {
                    timeSlots.append(dateFormatter.string(from: currentTime))
                    if let newTime = Calendar.current.date(byAdding: .minute, value: 30, to: currentTime) {
                        currentTime = newTime
                    } else {
                        break
                    }
                }
            }
        }
        return timeSlots
    }
    
    func toggleSelection(of timeSlot: String) {
        if let index = selectedTimes.firstIndex(of: timeSlot) {
            selectedTimes.remove(at: index)
        } else {
            selectedTimes.append(timeSlot)
        }
    }
    
    func submitBooking() {
        guard let date = selectedDate, !selectedTimes.isEmpty else {
            alertMessage = "請選擇日期和至少一個時間段。"
            showingAlert = true
            return
        }
        
        let bookingRef = UserFirebaseService.shared.db.collection("appointments").document()
        let documentID = bookingRef.documentID
        
        let bookingData: [String: Any] = [
            "id": documentID,
            "studentID": studentID,
            "teacherID": teacherID,
            "date": date,
            "times": selectedTimes,
            "status": "pending",
            "timestamp": Timestamp(date: Date())
        ]
        
        bookingRef.setData(bookingData) { error in
            if let error = error {
                alertMessage = "預約失敗：\(error.localizedDescription)"
                showingAlert = true
            } else {
                alertMessage = "預約成功！"
                showingAlert = true
                selectedDate = nil
                selectedTimes = []
            }
        }
    }
}

//#Preview {
//    BookingView(selectedTimeSlots: ["2024-09-11": "#FF624F", "2024-09-13": "#FF624F", "2024-09-12": "#000000", "2024-10-10": "#FF624F"], timeSlots: [EdUnion.TimeSlot(colorHex: "#FF624F", timeRanges: ["08:00 - 11:00", "14:00 - 18:00"]), EdUnion.TimeSlot(colorHex: "#000000", timeRanges: ["06:00 - 21:00"])])
//}