//
//  ColorTimePickerVC.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/13.
//

import UIKit

class ColorTimePickerVC: UIViewController, UIColorPickerViewControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var editingTimeSlot: AvailableTimeSlot?
    var onTimeSlotSelected: ((AvailableTimeSlot) -> Void)?
    var existingTimeRanges: [String] = []
    var existingColors: [String] = []
    var existingTimeSlots: [AvailableTimeSlot] = []
    var onTimeSlotEdited: ((AvailableTimeSlot) -> Void)?
    
    let saveButton = UIButton(type: .system)
    let cancelButton = UIButton(type: .system)
    let addTimeSlotButton = UIButton(type: .system)
    
    private let startTimePicker = UIPickerView()
    private let endTimePicker = UIPickerView()
    private var selectedColor: UIColor = .white
    
    private var selectedTimeRanges: [String] = []
    
    private let selectedSlotLabel = UILabel()
    private let colorPreview = UIView()
    private let colorPreviewLabel: UILabel = {
        let label = UILabel()
        label.text = "請點擊選擇顏色"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "尚未添加時間段"
        label.textAlignment = .center
        label.textColor = .myGray
        label.font = UIFont.systemFont(ofSize: 18)
        label.isHidden = true
        return label
    }()
    private let timeSlotsTableView = UITableView()

    private let colorStackView = UIStackView()
    private let timePickersStackView = UIStackView()
    private let buttonStackView = UIStackView()
    
    private let hours = Array(0...23)
    private let minutes = ["00", "30"]
    private var existingTimeRangesForSelectedColor: [String] {
        let selectedColorHex = selectedColor.hexString.lowercased()
        let timeSlotsWithSelectedColor = existingTimeSlots.filter { $0.colorHex.lowercased() == selectedColorHex }
        return timeSlotsWithSelectedColor.flatMap { $0.timeRanges }
    }
    
    private var selectedStartHour = 0
    private var selectedStartMinute = "00"
    private var selectedEndHour = 0
    private var selectedEndMinute = "30"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .myBackground
        
        setupTimePickers()
        setupColorPicker()
        setupSelectedSlotDisplay()
        setupTimeSlotsTableView()
        setupButtons()
        setupConstraints()
        
        if let timeSlot = editingTimeSlot {
            selectedColor = UIColor(hexString: timeSlot.colorHex)
            colorPreview.backgroundColor = selectedColor
            
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
        colorPreview.layer.borderColor = UIColor.myGray.cgColor
        colorPreview.backgroundColor = selectedColor
        colorPreview.isUserInteractionEnabled = true
        
        // 添加 colorPreviewLabel 到 colorPreview 中
        colorPreview.addSubview(colorPreviewLabel)
        
        // 設置 colorPreviewLabel 的約束，使其在 colorPreview 的中間
        colorPreviewLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            colorPreviewLabel.centerXAnchor.constraint(equalTo: colorPreview.centerXAnchor),
            colorPreviewLabel.centerYAnchor.constraint(equalTo: colorPreview.centerYAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectColorTapped))
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
        timeSlotsTableView.layer.shadowColor = UIColor.black.cgColor
        timeSlotsTableView.layer.shadowOpacity = 0.2
        timeSlotsTableView.layer.shadowOffset = CGSize(width: 0, height: 2)
        timeSlotsTableView.layer.shadowRadius = 4
        timeSlotsTableView.layer.shadowPath = UIBezierPath(roundedRect: timeSlotsTableView.bounds, cornerRadius: timeSlotsTableView.layer.cornerRadius).cgPath
        
        timeSlotsTableView.backgroundView = emptyStateLabel
        
        timeSlotsTableView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }
    
    func updateEmptyState() {
        if selectedTimeRanges.isEmpty {
            emptyStateLabel.isHidden = false
        } else {
            emptyStateLabel.isHidden = true
        }
    }
    
    func setupButtons() {
        addTimeSlotButton.setTitle("新增時間段", for: .normal)
        addTimeSlotButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        addTimeSlotButton.setTitleColor(.systemBackground, for: .normal)
        addTimeSlotButton.backgroundColor = .label
        addTimeSlotButton.layer.cornerRadius = 8
        addTimeSlotButton.addTarget(self, action: #selector(addTimeSlotTapped), for: .touchUpInside)
        
        saveButton.setTitle("儲存", for: .normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        saveButton.setTitleColor(.mainTint, for: .normal)
        saveButton.backgroundColor = .mainOrange
        saveButton.layer.cornerRadius = 8
        saveButton.addTarget(self, action: #selector(saveAllTimeSlots), for: .touchUpInside)
        
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        cancelButton.setTitleColor(.systemBackground, for: .normal)
        cancelButton.backgroundColor = .label
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelSelection), for: .touchUpInside)
    }
    
    func setupConstraints() {

        let timeSeparatorLabel = UILabel()
        timeSeparatorLabel.text = "～"
        timeSeparatorLabel.textAlignment = .center
        timeSeparatorLabel.font = UIFont.systemFont(ofSize: 16)
        
        let startTimeStack = UIStackView(arrangedSubviews: [startTimePicker])
        startTimeStack.axis = .vertical
        startTimeStack.spacing = 5
        
        let endTimeStack = UIStackView(arrangedSubviews: [endTimePicker])
        endTimeStack.axis = .vertical
        endTimeStack.spacing = 5
        
        let timePickersVerticalStack = UIStackView(arrangedSubviews: [startTimeStack, timeSeparatorLabel, endTimeStack])
        timePickersVerticalStack.axis = .vertical
        timePickersVerticalStack.spacing = 10

        // 將時間選擇器和新增按鈕水平排列
        let timeSelectionStackView = UIStackView(arrangedSubviews: [timePickersVerticalStack, addTimeSlotButton])
        timeSelectionStackView.axis = .horizontal
        timeSelectionStackView.spacing = 10
        timeSelectionStackView.distribution = .fill
        timeSelectionStackView.alignment = .center

        // 中間區域：時間段列表
        let timeSlotsLabel = UILabel()
        timeSlotsLabel.text = "已選擇的時間段"
        timeSlotsLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        timeSlotsLabel.textAlignment = .left

        let timeSlotsContainer = UIStackView(arrangedSubviews: [timeSlotsLabel, timeSlotsTableView])
        timeSlotsContainer.axis = .vertical
        timeSlotsContainer.spacing = 10

        let buttonsStackView = UIStackView(arrangedSubviews: [saveButton, cancelButton])
        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 16
        buttonsStackView.distribution = .fillEqually

        // 整體佈局
        let mainStackView = UIStackView(arrangedSubviews: [colorPreview, timeSelectionStackView, timeSlotsContainer, buttonsStackView])
            mainStackView.axis = .vertical
            mainStackView.spacing = 20
        
            mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addTimeSlotButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        colorPreview.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(mainStackView)

            // 設置約束
            NSLayoutConstraint.activate([
//                mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//                mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

                addTimeSlotButton.heightAnchor.constraint(equalToConstant: 40),
                saveButton.heightAnchor.constraint(equalToConstant: 40),
                cancelButton.heightAnchor.constraint(equalToConstant: 40),

                colorPreview.heightAnchor.constraint(equalToConstant: 80),
                // 時間選擇器的大小
                startTimePicker.heightAnchor.constraint(equalToConstant: 100),
                endTimePicker.heightAnchor.constraint(equalToConstant: 100),
                startTimePicker.widthAnchor.constraint(equalToConstant: 200),
                // 時間段列表高度
                timeSlotsTableView.heightAnchor.constraint(equalToConstant: 150)
            ])
        }
    
    @objc func addTimeSlotTapped() {
        let startTimeString = String(format: "%02d:%@", selectedStartHour, selectedStartMinute)
        let endTimeString = String(format: "%02d:%@", selectedEndHour, selectedEndMinute)
        
        let timeRange = "\(startTimeString) - \(endTimeString)"
        
        guard let startTime = dateFromString(startTimeString), let endTime = dateFromString(endTimeString) else {
            return
        }
        
        if isTimeRangeOverlapping(start: startTime, end: endTime) {
            presentAlert(title: "此時段已經存在", message: "請重新選擇時段")
            return
        }
        
        selectedTimeRanges.append(timeRange)
        timeSlotsTableView.reloadData()
        updateEmptyState()
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
    
    // MARK: - ColorPicker Delegate
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        selectedColor = viewController.selectedColor
        colorPreview.backgroundColor = selectedColor
        
        colorPreviewLabel.isHidden = true
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        updateEmptyState()
        return selectedTimeRanges.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let timeRange = selectedTimeRanges[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSlotCell", for: indexPath)
        cell.textLabel?.text = timeRange
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            selectedTimeRanges.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        updateEmptyState()
    }
}

extension ColorTimePickerVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? hours.count : minutes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 60
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return component == 0 ? String(format: "%02d", hours[row]) : minutes[row]
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
}
