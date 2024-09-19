//
//  AvailableTimeSlotsViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import UIKit

class AvailableTimeSlotsViewModel {
    private(set) var timeSlots: [AvailableTimeSlot] = []
    var onTimeSlotsChanged: (() -> Void)?
    
    private let teacherID: String
    
    init(teacherID: String) {
        self.teacherID = teacherID
    }
    
    func loadTimeSlots() {
        UserFirebaseService.shared.fetchTimeSlots(forTeacher: teacherID) { [weak self] result in
            switch result {
            case .success(let timeSlots):
                self?.timeSlots = timeSlots
                self?.onTimeSlotsChanged?()
            case .failure(let error):
                print("Error loading time slots: \(error)")
            }
        }
    }
    
    func addTimeSlot(_ timeSlot: AvailableTimeSlot) {
        if timeSlots.contains(timeSlot) {
            print("TimeSlot already exists.")
            return
        }
        UserFirebaseService.shared.saveTimeSlot(timeSlot, for: teacherID) { [weak self] result in
            switch result {
            case .success():
                self?.timeSlots.append(timeSlot)
                self?.onTimeSlotsChanged?()
            case .failure(let error):
                print("Error adding time slot: \(error)")
            }
        }
    }
    
    func deleteTimeSlot(at index: Int) {
        let timeSlot = timeSlots[index]
        UserFirebaseService.shared.deleteTimeSlot(timeSlot, for: teacherID) { [weak self] result in
            switch result {
            case .success():
                self?.timeSlots.remove(at: index)
                self?.onTimeSlotsChanged?()
            case .failure(let error):
                print("Error deleting time slot: \(error)")
            }
        }
    }
    
    func existingColors() -> [String] {
        return timeSlots.map { $0.colorHex }
    }
    
    func updateTimeSlot(at index: Int, with newTimeSlot: AvailableTimeSlot) {
        guard index >= 0 && index < timeSlots.count else { return }
        
        let oldTimeSlot = timeSlots[index]
        timeSlots[index] = newTimeSlot
        
        UserFirebaseService.shared.updateTimeSlot(oldTimeSlot: oldTimeSlot, newTimeSlot: newTimeSlot, forTeacher: teacherID) { [weak self] result in
            switch result {
            case .success:
                self?.onTimeSlotsChanged?()
            case .failure(let error):
                print("更新时间段时出错：\(error)")
                self?.timeSlots[index] = oldTimeSlot
            }
        }
    }
}

