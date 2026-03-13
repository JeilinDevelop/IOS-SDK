//
//  SettingViewCell.swift
//  Polaroid
//
//  Created by jxcs on 2025/1/20.
//

import UIKit
import Masonry

// MARK: - SettingViewCell

class SettingViewCell: UITableViewCell {
    
    private lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = .black
        switchControl.isEnabled = false
        switchControl.isHidden = true
        return switchControl
    }()
    
    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(switchControl)
    }
    
    private func setupConstraints() {
        
        switchControl.mas_makeConstraints { make in
            make?.centerY.equalTo()(contentView)
            make?.right.equalTo()(contentView)?.offset()(-15)
        }
    }
    
    func configure(with menuMap: [String: Any]) {
        let language = MenuData.shared.language
        let settingMap = MenuData.shared.settingMap
        let dictList = MenuData.shared.dictList
        if let captionTransIdx = menuMap["Caption Trans Idx"] as? Int,
           let dictList = dictList, let caption = dictList[captionTransIdx][language] as? String
        {
            textLabel?.text = caption
        } else {
            textLabel?.text = menuMap["Caption"] as? String
        }
        switchControl.isHidden = true
        detailTextLabel?.isHidden = true
        accessoryType = .none
        
        let menuUiType = menuMap["ui type"] as? Int
        let menuGetCmd = menuMap["get cmd"] as? String
        let menuSetCmd = menuMap["set cmd"] as? String
        let menuItems = menuMap["item"] as? [[String: Any]]
        
        if let menuUiType = menuUiType, menuUiType == 0 {
            if let list = menuItems, let menuGetCmd = menuGetCmd {
                var isSwitch = false
                var isSetCmd = false
                var isUiType = false
//                var uiType = 0
//                var uiTypeIndex = 0
                
                // 检查列表项属性
                for (index, item) in list.enumerated() {
                    if let caption = item["Caption"] as? String,
                       ["On", "Off", "Yes", "No"].contains(caption)
                    {
                        isSwitch = true
                    }
                    if item["set cmd"] != nil {
                        isSetCmd = true
                    }
                    if let itemUiType = item["ui type"] as? Int {
                        isUiType = true
//                        uiType = itemUiType
//                        uiTypeIndex = index
                    }
                }
                
                if list.count == 2 && isSwitch {
                    if isUiType || isSetCmd {
                        switchControl.isHidden = true
                        if let settingValue = settingMap?[menuGetCmd] as? Int {
                            var index = settingValue
                            if index >= list.count {
                                index = 1
                            }
                            let item = list[index]
                            if let captionTransIdx = item["Caption Trans Idx"] as? Int, let caption = dictList?[captionTransIdx][language] as? String {
                                detailTextLabel?.text = caption
                            } else {
                                detailTextLabel?.text = item["Caption"] as? String
                            }
                            detailTextLabel?.isHidden = false
                        }
                        accessoryType = .disclosureIndicator
                    } else {
                        if let settingValue = settingMap?[menuGetCmd] as? Int {
                            let item = list[settingValue]
                            if let caption = item["Caption"] as? String {
                                switchControl.isOn = caption == "On"
                                switchControl.isHidden = false
                                detailTextLabel?.isHidden = true
                            }
                        }
                    }
                } else {
                    switchControl.isHidden = true
                    if var settingValue = settingMap?[menuGetCmd] as? Int {
                        if settingValue >= list.count {
                            settingValue = 0
                        }
                        let item = list[settingValue]
                        if let captionTransIdx = item["Caption Trans Idx"] as? Int, let caption = dictList?[captionTransIdx][language] as? String {
                            detailTextLabel?.text = caption
                        } else {
                            detailTextLabel?.text = item["Caption"] as? String
                        }
                        detailTextLabel?.isHidden = false
                    }
                    accessoryType = .disclosureIndicator
                }
            }
        } else if let menuUiType = menuUiType, menuUiType == 6 || menuUiType == 9 {
            if let list = menuItems, let menuGetCmd = menuGetCmd {
                switchControl.isHidden = true
                if let settingValue = settingMap?[menuGetCmd] as? Int {
                    let item = list[settingValue]
                    if let number = item["Number"] as? Int {
                        if let captionTransIdx = item["Caption Trans Idx"] as? Int, let caption = dictList?[captionTransIdx][language] as? String {
                            detailTextLabel?.text = "\(number)\(caption)"
                        } else {
                            detailTextLabel?.text = "\(number)\(item["Caption"] as? String ?? "")"
                        }
                        detailTextLabel?.isHidden = false
                    }
                }
                accessoryType = .disclosureIndicator
            }
        } else {
            switchControl.isHidden = true
            if let menuGetCmd = menuGetCmd,
               let value = settingMap?[menuGetCmd]
            {
                detailTextLabel?.text = "\(value)"
                detailTextLabel?.isHidden = false
            }
        }
    }
}
