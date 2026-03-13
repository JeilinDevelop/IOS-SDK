//
//  AppConstants.swift
//  Polaroid
//
//  Created by jxcs on 2025/8/13.
//

import Foundation

enum WorkMode: String {
    case photoCapture = "PhotoCapture"
    case videoCapture = "VideoCapture"
    case storage = "Storage"
    case setup = "Setup"
}

enum DeviceMode {
    case wifi
    case x95
}

enum AppConstants {
    // 静态常量
    static let appFlag: DeviceMode = .wifi

    static let settingSyncTime = "SETTING_SYNC_TIME"
    static let settingSSL = "SETTING_SSL"

    // 变量（可修改）
    static var workMode: WorkMode?
    static var launchTime: TimeInterval?

    // 获取启动时间
    static func getLaunchTime() -> TimeInterval {
        return launchTime ?? Date().timeIntervalSince1970
    }

    static func registDefaults() {
        UserDefaults.standard.register(defaults: [settingSyncTime: true, settingSSL: false])
    }

    // 读取设置（这里用 UserDefaults 代替 StaticDefine）
    static func isSettingSyncTime() -> Bool {
        return UserDefaults.standard.bool(forKey: settingSyncTime)
    }

    static func setSettingSyncTime(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: settingSyncTime)
    }

    static func isSettingSSL() -> Bool {
        return UserDefaults.standard.bool(forKey: settingSSL)
    }

    static func setSettingSSL(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: settingSSL)
    }

    // 设置模式
    static func setModeType(_ mode: String) {
        workMode = getWorkMode(mode)
    }

    static func getWorkMode(_ mode: String) -> WorkMode {
        return WorkMode(rawValue: mode) ?? .photoCapture
    }
}
