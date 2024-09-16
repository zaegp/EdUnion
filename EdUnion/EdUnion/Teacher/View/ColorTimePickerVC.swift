//
//  ColorTimePickerVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/13.
//

import UIKit

class ColorTimePickerVC: UIViewController, UIColorPickerViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {

    var editingTimeSlot: AvailableTimeSlot?
    var onTimeSlotSelected: ((AvailableTimeSlot) -> Void)?
    var existingTimeRanges: [String] = []
    var existingColors: [String] = []
    var existingTimeSlots: [AvailableTimeSlot] = []
    var onTimeSlotEdited: ((AvailableTimeSlot) -> Void)?

    private let startTimePicker = UIPickerView()
    private let endTimePicker = UIPickerView()
    private var selectedColor: UIColor = .clear

    private var selectedTimeRanges: [String] = []

    private let selectedSlotLabel = UILabel()
    private let colorPreview = UIView()
    private let timeSlotsTableView = UITableView()

    // Declare UI elements as instance properties
    private let colorStackView = UIStackView()
    private let timePickersStackView = UIStackView()
    private let buttonStackView = UIStackView()

    // Data sources for the pickers
    private let hours = Array(0...23)
    private let minutes = ["00", "30"]
    private var existingTimeRangesForSelectedColor: [String] {
            let selectedColorHex = selectedColor.hexString.lowercased()
            let timeSlotsWithSelectedColor = existingTimeSlots.filter { $0.colorHex.lowercased() == selectedColorHex }
            return timeSlotsWithSelectedColor.flatMap { $0.timeRanges }
        }


    // Variables to hold selected times
    private var selectedStartHour = 0
    private var selectedStartMinute = "00"
    private var selectedEndHour = 0
    private var selectedEndMinute = "30"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupTimePickers()
        setupColorPicker()
        setupSelectedSlotDisplay()
        setupTimeSlotsTableView()
        setupButtons()
        setupConstraints()
        
        if let timeSlot = editingTimeSlot {
                    // Set selected color
                    selectedColor = UIColor(hexString: timeSlot.colorHex)
                    colorPreview.backgroundColor = selectedColor
                    
                    // Set selected time ranges
                    selectedTimeRanges = timeSlot.timeRanges
                    timeSlotsTableView.reloadData()
                }
    }

    func setupTimePickers() {
        startTimePicker.delegate = self
        startTimePicker.dataSource = self
        endTimePicker.delegate = self
        endTimePicker.dataSource = self

        startTimePicker.selectRow(0, inComponent: 0, animated: false)
        startTimePicker.selectRow(0, inComponent: 1, animated: false)
        endTimePicker.selectRow(0, inComponent: 0, animated: false)
        endTimePicker.selectRow(1, inComponent: 1, animated: false)
        
        selectedStartHour = hours[0]
        selectedStartMinute = minutes[0]
        selectedEndHour = hours[0]
        selectedEndMinute = minutes[1]

        timePickersStackView.axis = .horizontal
        timePickersStackView.spacing = 16
        timePickersStackView.distribution = .fillEqually
        timePickersStackView.addArrangedSubview(startTimePicker)
        timePickersStackView.addArrangedSubview(endTimePicker)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return hours.count
        } else {
            return minutes.count
        }
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 60
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return String(format: "%02d", hours[row])
        } else {
            return minutes[row]
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == startTimePicker {
            if component == 0 {
                selectedStartHour = hours[row]
            } else {
                selectedStartMinute = minutes[row]
            }
        } else {
            if component == 0 {
                selectedEndHour = hours[row]
            } else {
                selectedEndMinute = minutes[row]
            }
        }
        validateTimeSelection()
    }

    func validateTimeSelection() {
        let startTimeString = String(format: "%02d:%@", selectedStartHour, selectedStartMinute)
        let endTimeString = String(format: "%02d:%@", selectedEndHour, selectedEndMinute)

        guard let startTime = dateFromString(startTimeString), let endTime = dateFromString(endTimeString) else {
            return
        }

        if startTime >= endTime {
            if let newEndTime = Calendar.current.date(byAdding: .minute, value: 30, to: startTime) {
                let calendar = Calendar.current
                selectedEndHour = calendar.component(.hour, from: newEndTime)
                selectedEndMinute = calendar.component(.minute, from: newEndTime) == 0 ? "00" : "30"
                endTimePicker.selectRow(hours.firstIndex(of: selectedEndHour) ?? 0, inComponent: 0, animated: true)
                endTimePicker.selectRow(minutes.firstIndex(of: selectedEndMinute) ?? 0, inComponent: 1, animated: true)
            }
        }
    }

    func setupColorPicker() {
        colorPreview.layer.cornerRadius = 8
        colorPreview.layer.borderWidth = 1
        colorPreview.layer.borderColor = UIColor(resource: .background).cgColor
        colorPreview.backgroundColor = selectedColor
        colorPreview.largeContentTitle = "請選擇顏色"

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectColorTapped))
        colorPreview.isUserInteractionEnabled = true
        colorPreview.addGestureRecognizer(tapGesture)
    }

    @objc func selectColorTapped() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.selectedColor = selectedColor
        present(colorPicker, animated: true, completion: nil)
    }

    func setupSelectedSlotDisplay() {
        selectedSlotLabel.font = UIFont.systemFont(ofSize: 16)
        selectedSlotLabel.textAlignment = .center
        selectedSlotLabel.numberOfLines = 0
        selectedSlotLabel.textColor = .label
        selectedSlotLabel.text = "已選時段："
    }

    func setupTimeSlotsTableView() {
        timeSlotsTableView.delegate = self
        timeSlotsTableView.dataSource = self
        timeSlotsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "TimeSlotCell")
        timeSlotsTableView.tableFooterView = UIView()
        timeSlotsTableView.isScrollEnabled = false

        timeSlotsTableView.layer.cornerRadius = 8
        timeSlotsTableView.clipsToBounds = true
        timeSlotsTableView.layer.shadowColor = UIColor.black.cgColor  // 阴影颜色
        timeSlotsTableView.layer.shadowOpacity = 0.2  // 阴影不透明度，取值范围 0~1
        timeSlotsTableView.layer.shadowOffset = CGSize(width: 0, height: 2)  // 阴影偏移量
        timeSlotsTableView.layer.shadowRadius = 4
        timeSlotsTableView.layer.shadowPath = UIBezierPath(roundedRect: timeSlotsTableView.bounds, cornerRadius: timeSlotsTableView.layer.cornerRadius).cgPath


        timeSlotsTableView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }

    func setupButtons() {
        let addTimeSlotButton = UIButton(type: .system)
        addTimeSlotButton.setTitle("新增時間段", for: .normal)
        addTimeSlotButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        addTimeSlotButton.setTitleColor(.mainTint, for: .normal)
        addTimeSlotButton.backgroundColor = .background
        addTimeSlotButton.layer.cornerRadius = 8
        addTimeSlotButton.addTarget(self, action: #selector(addTimeSlotTapped), for: .touchUpInside)

        let saveButton = UIButton(type: .system)
        saveButton.setTitle("儲存", for: .normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        saveButton.setTitleColor(.mainTint, for: .normal)
        saveButton.backgroundColor = .background
        saveButton.layer.cornerRadius = 8
        saveButton.addTarget(self, action: #selector(saveAllTimeSlots), for: .touchUpInside)

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        cancelButton.setTitleColor(.mainTint, for: .normal)
        cancelButton.backgroundColor = .background
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelSelection), for: .touchUpInside)

        // Configure buttonStackView
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 16
        buttonStackView.distribution = .fillEqually
        buttonStackView.addArrangedSubview(addTimeSlotButton)
        buttonStackView.addArrangedSubview(saveButton)
        buttonStackView.addArrangedSubview(cancelButton)
    }

    func setupConstraints() {
        // Add subviews to the main view
        view.addSubview(timePickersStackView)
        view.addSubview(selectedSlotLabel)
        view.addSubview(timeSlotsTableView)
        view.addSubview(buttonStackView)
        view.addSubview(colorPreview)
        
        timePickersStackView.translatesAutoresizingMaskIntoConstraints = false
        selectedSlotLabel.translatesAutoresizingMaskIntoConstraints = false
        timeSlotsTableView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        colorPreview.translatesAutoresizingMaskIntoConstraints = false

        // Set up constraints
        NSLayoutConstraint.activate([
            selectedSlotLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            selectedSlotLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            selectedSlotLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            selectedSlotLabel.heightAnchor.constraint(equalToConstant: 30),

            timeSlotsTableView.topAnchor.constraint(equalTo: selectedSlotLabel.bottomAnchor, constant: 10),
            timeSlotsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            timeSlotsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            timeSlotsTableView.heightAnchor.constraint(equalToConstant: 150),
            
            timePickersStackView.topAnchor.constraint(equalTo: timeSlotsTableView.bottomAnchor, constant: 20),
            timePickersStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            timePickersStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            timePickersStackView.heightAnchor.constraint(equalToConstant: 200),
            
            colorPreview.topAnchor.constraint(equalTo: timePickersStackView.bottomAnchor, constant: 20),
//            colorPreview.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colorPreview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            colorPreview.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            colorPreview.heightAnchor.constraint(equalToConstant: 50),

            buttonStackView.topAnchor.constraint(equalTo: colorPreview.bottomAnchor, constant: 20),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 180),
            buttonStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    @objc func addTimeSlotTapped() {
        let startTimeString = String(format: "%02d:%@", selectedStartHour, selectedStartMinute)
        let endTimeString = String(format: "%02d:%@", selectedEndHour, selectedEndMinute)

        let timeRange = "\(startTimeString) - \(endTimeString)"

        // Check for overlapping time ranges
//        if existingTimeRanges.contains(timeRange) || selectedTimeRanges.contains(timeRange) {
//            presentAlert(title: "Overlap", message: "This time range overlaps with an existing selection.")
//            return
//        }

        guard let startTime = dateFromString(startTimeString), let endTime = dateFromString(endTimeString) else {
            return
        }
        if isTimeRangeOverlapping(start: startTime, end: endTime) {
            presentAlert(title: "Overlap", message: "This time range overlaps with an existing selection.")
            return
        }

        selectedTimeRanges.append(timeRange)
        timeSlotsTableView.reloadData()
    }

    @objc func saveAllTimeSlots() {
        guard !selectedTimeRanges.isEmpty else {
            presentAlert(title: "没有時間段", message: "請至少添加一個時間段。")
            return
        }
        
        let selectedColorHex = selectedColor.hexString
        if existingColors.contains(selectedColorHex) {
            presentAlert(title: "顏色重覆", message: "該顏色已經存在，請選擇其他顏色。")
            return
        }
        
        let newTimeSlot = AvailableTimeSlot(colorHex: selectedColorHex, timeRanges: selectedTimeRanges)
        
        if editingTimeSlot != nil {
            onTimeSlotEdited?(newTimeSlot)
        } else {
            onTimeSlotSelected?(newTimeSlot)
        }
        
        dismiss(animated: true, completion: nil)
    }
    @objc func cancelSelection() {
        dismiss(animated: true, completion: nil)
    }

    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func isTimeRangeOverlapping(start: Date, end: Date) -> Bool {
        for timeRange in selectedTimeRanges {
            let times = timeRange.components(separatedBy: " - ")
            if times.count == 2,
               let existingStart = dateFromString(times[0]),
               let existingEnd = dateFromString(times[1]) {
                if start < existingEnd && end > existingStart {
                    return true
                }
            }
        }
        return false
    }

    func dateFromString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }

    // MARK: - UIColorPickerViewControllerDelegate

    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        selectedColor = viewController.selectedColor
        colorPreview.backgroundColor = selectedColor
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedTimeRanges.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let timeRange = selectedTimeRanges[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSlotCell", for: indexPath)
        cell.textLabel?.text = timeRange
        return cell
    }

    // Allow deletion of time slots
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,     forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            selectedTimeRanges.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    
}
