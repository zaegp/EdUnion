//
//  AvailableTimeSlotsCell.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/13.
//

import UIKit

struct TimeSlot {
    var color: UIColor
    var startTime: String
    var endTime: String
}

class AvailableTimeSlotsCell: UITableViewCell {
    
    let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.clipsToBounds = true
        return view
    }()
    
    let startTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        return label
    }()
    
    let endTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(colorView)
        addSubview(startTimeLabel)
        addSubview(endTimeLabel)
        
        colorView.translatesAutoresizingMaskIntoConstraints = false
        startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        endTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            colorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            colorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 30),
            colorView.heightAnchor.constraint(equalToConstant: 30),
            
            startTimeLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 16),
            startTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            endTimeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            endTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(timeSlot: TimeSlot) {
        colorView.backgroundColor = timeSlot.color
        startTimeLabel.text = "Start: \(timeSlot.startTime)"
        endTimeLabel.text = "End: \(timeSlot.endTime)"
    }
}

class TimePickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIColorPickerViewControllerDelegate {

    var onTimeSlotSelected: (([String], UIColor) -> Void)?
    var existingTimeRanges: [String] = []  // 用於保存已選的時間段，防止重疊
    let timePicker = UIPickerView()

    let timeOptions = [
        "00:00", "00:30", "01:00", "01:30", "02:00", "02:30",
        "03:00", "03:30", "04:00", "04:30", "05:00", "05:30",
        "06:00", "06:30", "07:00", "07:30", "08:00", "08:30",
        "09:00", "09:30", "10:00", "10:30", "11:00", "11:30",
        "12:00", "12:30", "13:00", "13:30", "14:00", "14:30",
        "15:00", "15:30", "16:00", "16:30", "17:00", "17:30",
        "18:00", "18:30", "19:00", "19:30", "20:00", "20:30",
        "21:00", "21:30", "22:00", "22:30", "23:00", "23:30"
    ]

    var availableEndTimes: [String] = []  // 選擇開始時間後可用的結束時間
    var selectedStartTime: String?
    var selectedEndTime: String?
    var selectedColor: UIColor = .blue
    var selectedTimeRanges: [String] = []
    let selectedSlotLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.layer.cornerRadius = 20
        
        setupPickerView()
        setupTimeSlotDisplay()
        setupButtons()
    }

    func setupPickerView() {
        timePicker.delegate = self
        timePicker.dataSource = self

        view.addSubview(timePicker)
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timePicker.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            timePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func setupTimeSlotDisplay() {
        // 用於即時顯示選擇的時段
        selectedSlotLabel.font = UIFont.systemFont(ofSize: 16)
        selectedSlotLabel.textAlignment = .center
        selectedSlotLabel.numberOfLines = 0
        selectedSlotLabel.textColor = .label
        view.addSubview(selectedSlotLabel)
        selectedSlotLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectedSlotLabel.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 20),
            selectedSlotLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            selectedSlotLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            selectedSlotLabel.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // 在選擇時間和顏色後，立即顯示選擇
        self.onTimeSlotSelected = { timeRanges, color in
            self.selectedSlotLabel.text = "Selected: \(timeRanges.joined(separator: ", "))"
            self.selectedSlotLabel.backgroundColor = color.withAlphaComponent(0.2)
        }
    }

    func setupButtons() {
        let selectColorButton = UIButton(type: .system)
        selectColorButton.setTitle("Select Color", for: .normal)
        selectColorButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        selectColorButton.setTitleColor(.white, for: .normal)
        selectColorButton.backgroundColor = .systemTeal
        selectColorButton.layer.cornerRadius = 8
        selectColorButton.addTarget(self, action: #selector(selectColorTapped), for: .touchUpInside)

        let addButton = UIButton(type: .system)
        addButton.setTitle("Add Time Slot", for: .normal)
        addButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = .systemGreen
        addButton.layer.cornerRadius = 8
        addButton.addTarget(self, action: #selector(addTimeSlot), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [selectColorButton,        addButton])
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: selectedSlotLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc func selectColorTapped() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        present(colorPicker, animated: true, completion: nil)
    }

    @objc func addTimeSlot() {
        guard let startTime = selectedStartTime, let endTime = selectedEndTime else {
            let alert = UIAlertController(title: "Invalid Time", message: "Please select both start and end times.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        let timeRange = "\(startTime) - \(endTime)"

        // 檢查時間是否與現有時間重疊
        if existingTimeRanges.contains(where: { $0 == timeRange }) {
            let alert = UIAlertController(title: "Overlap", message: "This time range overlaps with an existing selection.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        selectedTimeRanges.append(timeRange)
        onTimeSlotSelected?(selectedTimeRanges, selectedColor)

        selectedStartTime = nil
        selectedEndTime = nil
        timePicker.selectRow(0, inComponent: 0, animated: true)
        timePicker.selectRow(0, inComponent: 1, animated: true)
    }

    // MARK: - UIPickerView DataSource & Delegate

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2 // 一個是開始時間，一個是結束時間
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return timeOptions.count // 第一個選項是開始時間
        } else {
            return availableEndTimes.count // 第二個選項是結束時間
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return timeOptions[row]
        } else {
            return availableEndTimes[row]
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedStartTime = timeOptions[row]
            updateAvailableEndTimes()
            timePicker.reloadComponent(1)
        } else {
            selectedEndTime = availableEndTimes[row]
        }
    }

    private func updateAvailableEndTimes() {
        guard let selectedStartTime = selectedStartTime, let startIndex = timeOptions.firstIndex(of: selectedStartTime) else {
            availableEndTimes = []
            return
        }

        // 只允許選擇開始時間之後的結束時間
        availableEndTimes = Array(timeOptions[(startIndex + 1)...])
    }

    // MARK: - UIColorPickerViewControllerDelegate

    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        selectedColor = viewController.selectedColor
    }
}
