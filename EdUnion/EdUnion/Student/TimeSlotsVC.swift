//
//  TimeSlotsVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/14.
//

import Foundation
import UIKit

// 時段模型


//struct TimeSlots: Codable, Equatable {
//    let colorHex: String
//    let timeRanges: [String]
//    
//    // 初始化方法
//    init(colorHex: String, timeRanges: [String]) {
//        self.colorHex = colorHex
//        self.timeRanges = timeRanges
//    }
//}



// 每日模型
struct Day {
    let name: String       // 如 "周一"
    let date: Date         // 該日的日期
    var timeSlots: [TimeSlotDetail]
}

struct TimeSlotDetail: Equatable {
    let startTime: String // 格式為 "HH:mm"
    let endTime: String   // 格式為 "HH:mm"
    let color: UIColor
    var isSelected: Bool = false
    
    init(startTime: String, endTime: String, color: UIColor, isSelected: Bool = false) {
        self.startTime = startTime
        self.endTime = endTime
        self.color = color
        self.isSelected = isSelected
    }
}


struct WeekCalendar {
    var days: [Day] = []
    
    init(selectedTimeSlots: [String: String], timeSlots: [TimeSlot]) {
        generateCurrentWeek(selectedTimeSlots: selectedTimeSlots, timeSlots: timeSlots)
    }
    
    mutating func generateCurrentWeek(selectedTimeSlots: [String: String], timeSlots: [TimeSlot]) {
        days = []
        let calendar = Calendar.current
        let today = Date()
        
        // 找到當前週的週一
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else { return }
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: weekStart) {
                let dayName = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
                let dateString = formatDate(date)
                let colorHex = selectedTimeSlots[dateString] ?? "#FFFFFF" // 默認白色
                
                // 選取對應的 TimeSlots
                let dayTimeSlots = timeSlots.filter { $0.colorHex.lowercased() == colorHex.lowercased() }
                
                var timeSlotDetails: [TimeSlotDetail] = []
                
                for timeSlot in dayTimeSlots {
                    for range in timeSlot.timeRanges {
                        let times = range.components(separatedBy: " - ")
                        if times.count == 2 {
                            let start = times[0]
                            let end = times[1]
                            if let color = UIColor(named: timeSlot.colorHex) {
                                timeSlotDetails.append(TimeSlotDetail(startTime: start, endTime: end, color: color))
                            }
                        }
                    }
                }
                
                // 生成每天的所有30分鐘時段，並標記可選的時段
                var allTimeSlots: [TimeSlotDetail] = []
                for hour in 0..<24 {
                    for minute in [0, 30] {
                        let start = String(format: "%02d:%02d", hour, minute)
                        let endHour = minute == 30 ? hour + 1 : hour
                        let endMinute = minute == 30 ? 0 : 30
                        if endHour < 24 {
                            let end = String(format: "%02d:%02d", endHour, endMinute)
                            
                            // 檢查此時段是否在可選時段中
                            if let matchedSlot = timeSlotDetails.first(where: { $0.startTime == start && $0.endTime == end }) {
                                allTimeSlots.append(matchedSlot)
                            } else {
                                allTimeSlots.append(TimeSlotDetail(startTime: start, endTime: end, color: .clear))
                            }
                        }
                    }
                }
                
                days.append(Day(name: dayName, date: date, timeSlots: allTimeSlots))
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}



class TimeSlotsCell: UICollectionViewCell {
    static let identifier = "TimeSlotsCell"
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    // 設置UI元素
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4)
        ])
        
        // 設置圓角和邊框
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 配置cell內容
    func configure(with timeSlot: TimeSlotDetail) {
        timeLabel.text = "\(timeSlot.startTime) - \(timeSlot.endTime)"
        if timeSlot.color != .clear {
            contentView.backgroundColor = timeSlot.color.withAlphaComponent(0.3)
            contentView.layer.borderColor = timeSlot.color.cgColor
        } else {
            contentView.backgroundColor = .clear
            contentView.layer.borderColor = UIColor.systemGray4.cgColor
        }
    }
}

class DayHeaderView: UICollectionReusableView {
    static let identifier = "DayHeaderView"
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(dayLabel)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: topAnchor),
            dayLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            dayLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            dayLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with dayName: String) {
        dayLabel.text = dayName
    }
}


import UIKit

class WeeklyCalendarViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // 接收從 TeacherDetailVC 傳來的 weekCalendar
    var weekCalendar: WeekCalendar!
    
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "周曆"
        view.backgroundColor = .systemBackground
        
        setupCollectionView()
    }
    
    func setupCollectionView() {
        // 使用 Flow Layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        
        // 設置 header 大小
        layout.headerReferenceSize = CGSize(width: view.frame.size.width, height: 30)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // 註冊 cell 和 header
        collectionView.register(TimeSlotsCell.self, forCellWithReuseIdentifier: TimeSlotsCell.identifier)
        collectionView.register(DayHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: DayHeaderView.identifier)
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // 設置約束
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return weekCalendar.days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weekCalendar.days[section].timeSlots.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TimeSlotsCell.identifier, for: indexPath) as? TimeSlotsCell else {
            return UICollectionViewCell()
        }
    
        let timeSlot = weekCalendar.days[indexPath.section].timeSlots[indexPath.item]
        cell.configure(with: timeSlot)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 切換選擇狀態
        weekCalendar.days[indexPath.section].timeSlots[indexPath.item].isSelected.toggle()
        
        // 更新 cell
        collectionView.reloadItems(at: [indexPath])
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 計算每個 cell 的寬度，根據屏幕寬度和間距
        let totalSpacing: CGFloat = 8 * 3 // 4 個 cell 的間距
        let width = (collectionView.frame.width - totalSpacing) / 4 // 每行 4 個時段顯示
        return CGSize(width: width, height: 40)
    }
    
    // 設置 header
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    
        if kind == UICollectionView.elementKindSectionHeader {
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DayHeaderView.identifier, for: indexPath) as? DayHeaderView else {
                return UICollectionReusableView()
            }
            let dayName = weekCalendar.days[indexPath.section].name
            header.configure(with: dayName)
            return header
        }
        return UICollectionReusableView()
    }
    
    // 設置 header 大小
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: 30)
    }
}
