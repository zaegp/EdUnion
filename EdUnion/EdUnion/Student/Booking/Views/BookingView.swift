//
//  BookingView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/15.
//

import SwiftUI
import FirebaseCore

struct BookingView: View {
    @ObservedObject var viewModel: BookingViewModel

    var body: some View {
        VStack {
            if viewModel.availableDates.isEmpty {
                noAvailableDatesView()
            } else {
                dateSelectionView()
                if let selectedDate = viewModel.selectedDate, let _ = viewModel.selectedTimeSlots[selectedDate] {
                    if viewModel.availableTimeSlotsForSelectedDate.isEmpty {
                        Spacer()
                        noAvailableTimeSlotsView()
                    } else {
                        availableTimeSlotsView()
                    }
                } else {
                    Text("請選擇日期")
                        .font(.headline)
                        .padding()
                    Spacer()
                }
            }
            
            Spacer()
            
            Button(action: viewModel.submitBooking) {
                Text("確定預約")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background((viewModel.selectedDate != nil && !viewModel.selectedTimes.isEmpty) ? Color.mainOrange : Color.gray)
                    .cornerRadius(10)
                    .padding([.horizontal, .bottom])
            }
            .disabled(viewModel.selectedDate == nil || viewModel.selectedTimes.isEmpty)
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(title: Text("通知"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("確定")))
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color.myBackground)
    }

    private func noAvailableDatesView() -> some View {
        return VStack {
            Image(systemName: "calendar.badge.exclamationmark")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            Text("暫無可預約的日期")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }

    private func dateSelectionView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(viewModel.availableDates, id: \.self) { date in
                    Button(action: {
                        viewModel.selectedDate = date
                        viewModel.selectedTimes = []
                        viewModel.bookedSlots.removeAll()
                        viewModel.getBookedSlots(for: date)
                    }) {
                        VStack {
                            Text(TimeService.formattedDate(date))
                                .font(.headline)
                                .foregroundColor(Color(UIColor.systemBackground))
                            Text(TimeService.formattedWeekday(date))
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.systemBackground))
                        }
                        .padding()
                        .background(viewModel.selectedDate == date ? Color.mainOrange : Color.myMessageCell)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
    }

    private func availableTimeSlotsView() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 20) {
                ForEach(viewModel.availableTimeSlotsForSelectedDate) { timeSlot in
                    timeSlotButton(timeSlot)
                }
            }
            .padding()
        }
    }

    private func timeSlotButton(_ timeSlot: TimeSlot) -> some View {
        Button(action: {
            viewModel.toggleSelection(of: timeSlot.time)
        }) {
            Text(timeSlot.time)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(buttonBackgroundColor(for: timeSlot))
                .foregroundColor(buttonForegroundColor(for: timeSlot))
                .cornerRadius(10)
        }
        .disabled(timeSlot.isBooked)
    }
    
    func buttonBackgroundColor(for timeSlot: TimeSlot) -> Color {
        if timeSlot.isBooked {
            return Color.gray
        } else if viewModel.isSelected(timeSlot: timeSlot.time) {
            return Color.mainOrange
        } else {
            return Color.myMessageCell
        }
    }

    func buttonForegroundColor(for timeSlot: TimeSlot) -> Color {
        if timeSlot.isBooked {
            return Color.white
        } else if viewModel.isSelected(timeSlot: timeSlot.time) {
            return Color.white
        } else {
            return Color(UIColor.systemBackground)
        }
    }

    func buttonBackgroundColor(for timeSlot: String) -> Color {
        if viewModel.isBooked(timeSlot: timeSlot) {
            return Color.gray
        } else if viewModel.isSelected(timeSlot: timeSlot) {
            return Color.mainOrange
        } else {
            return Color.myMessageCell
        }
    }

    func buttonForegroundColor(for timeSlot: String) -> Color {
        if viewModel.isBooked(timeSlot: timeSlot) {
            return Color.white
        } else if viewModel.isSelected(timeSlot: timeSlot) {
            return Color.white
        } else {
            return Color(UIColor.systemBackground)
        }
    }

    private func noAvailableTimeSlotsView() -> some View {
        VStack {
            Image(systemName: "clock.arrow.circlepath")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            Text("該日期暫無可用的時間段")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}
