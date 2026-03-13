//
//  MenuData.swift
//  Polaroid
//
//  Created by jxcs on 2025/1/20.
//

class MenuData {
    static let shared = MenuData()
    
    var menuMap: [String: Any]? = nil
    var menuList: [[String: Any]]? = nil
    var dictList: [[String: Any]]? = nil
    var language = "Chinese"
    
    var settingMap: [String: Any]? = nil
    
}
