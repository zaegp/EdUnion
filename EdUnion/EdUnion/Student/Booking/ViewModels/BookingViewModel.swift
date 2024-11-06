//
//  BookingViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/18.
//

import Foundation

class BookingViewModel: ObservableObject {
    @Published var selectedDate: String?
    @Published var selectedTimes: [String] = []
    @Published var bookedSlots: [String] = []

    let timeSlots: [AvailableTimeSlot]
    let selectedTimeSlots: [String: String]
    
    init(timeSlots: [AvailableTimeSlot], selectedTimeSlots: [String: String]) {
        self.timeSlots = timeSlots
        self.selectedTimeSlots = selectedTimeSlots
    }
    
    var availableTimeSlotsForSelectedDate: [String] {
        guard let selectedDate = selectedDate else { return [] }
        let allSlots = timeSlots.filter { $0.colorHex == selectedTimeSlots[selectedDate] }
            .flatMap { generateTimeSlots(from: $0.timeRanges, bookedSlots: bookedSlots) }
        
        if TimeService.isToday(selectedDate) {
            let now = Date()
            return allSlots.filter { !TimeService.isTimeSlotInPast($0, comparedTo: now) }
        } else {
            return allSlots
        }
    }

    func generateTimeSlots(from timeRanges: [String], bookedSlots: [String]) -> [String] {
        var timeSlots: [String] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        for range in timeRanges {
            let times = range.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            
            if let startTime = dateFormatter.date(from: String(times[0])),
               let endTime = dateFormatter.date(from: String(times[1])) {
                var currentTime = startTime
                
                while currentTime < endTime {
                    let timeString = dateFormatter.string(from: currentTime)
                    timeSlots.append(timeString)
                    
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard dateFormatter.date(from: timeSlot) != nil else { return }
        
        if let index = selectedTimes.firstIndex(of: timeSlot) {
            var newSelection = selectedTimes
            newSelection.remove(at: index)
            
            if isSelectionContinuous(newSelection) {
                selectedTimes = newSelection
            }
        } else {
            var newSelection = selectedTimes + [timeSlot]
            newSelection.sort()
            
            if isSelectionContinuous(newSelection) {
                selectedTimes.append(timeSlot)
            }
        }
    }
    
    func isSelectionContinuous(_ times: [String]) -> Bool {
        guard times.count > 1 else { return true }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        let sortedTimes = times.sorted {
            dateFormatter.date(from: $0)! < dateFormatter.date(from: $1)!
        }
        
        for i in 0..<(sortedTimes.count - 1) {
            guard let firstTime = dateFormatter.date(from: sortedTimes[i]),
                  let secondTime = dateFormatter.date(from: sortedTimes[i + 1]) else {
                return false
            }
            
            let difference = Calendar.current.dateComponents([.minute], from: firstTime, to: secondTime).minute
            if difference != 30 {
                return false
            }
        }
        
        return true
    }
}
