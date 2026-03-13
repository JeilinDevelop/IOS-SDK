//
//  SettingViewController.swift
//  Polaroid
//
//  Created by jxcs on 2025/1/20.
//
import JxCameraSDK
import Masonry
import MJRefresh
import UIKit

class SettingViewController: UIViewController {
    // MARK: - Properties
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .white
        table.separatorStyle = .singleLine
        table.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        table.delegate = self
        table.dataSource = self
        table.register(SettingViewCell.self, forCellReuseIdentifier: "SettingViewCell")
        // 禁用单元格选中效果
//        table.allowsSelection = false
        return table
    }()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        MenuData.shared.menuMap = nil
        MenuData.shared.menuList = nil
        MenuData.shared.settingMap = nil
        MenuData.shared.dictList = nil
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.mj_header?.beginRefreshing()
    }
    
    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        title = "设置"
        
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        
        view.addSubview(tableView)
        // 下拉刷新
        tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(refreshData))
    }
    
    private func setupConstraints() {
        tableView.mas_makeConstraints { make in
            make?.top.equalTo()(view.mas_safeAreaLayoutGuideTop)
            make?.left.right().bottom().equalTo()(view)
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // 下拉刷新
    @objc private func refreshData() {
        loadData()
    }
    
    private func loadData() {
        JxCameraCore.shared.request().changeMode(to: "Setup") { (result: Result<HttpResult, any Error>) in
            switch result {
            case .success(let res):
                if res.result == 0 {
                    AppConstants.setModeType("Setup")
                    self.getSettingMenuJson()
                }else{
                    self.tableView.mj_header?.endRefreshing()
                }
            case .failure(let error):
                print("请求失败: \(error.localizedDescription)")
                self.tableView.mj_header?.endRefreshing()
            }
        }
    }
    
    private var menuDescription = "Menu Description"
    private var menu = "Menu"
    private func getSettingMenuJson() {
        if MenuData.shared.menuMap == nil || MenuData.shared.menuList == nil {
            JxCameraCore.shared.request().fetchMenuJson { (result: Result<[String: Any], any Error>) in
                switch result {
                case .success(let res):
                    MenuData.shared.menuMap = res
                    if let menuDescriptionDict = res[self.menuDescription] as? [String: Any] {
                        let menuList = menuDescriptionDict[self.menu] as? [[String: Any]]
                        MenuData.shared.menuList = menuList
                        self.getDicList()
                    }
                case .failure(let error):
                    print("请求失败: \(error.localizedDescription)")
                    self.tableView.mj_header?.endRefreshing()
                }
            }
        } else {
            getDicList()
        }
    }
    
    func getDicList() {
        if MenuData.shared.dictList == nil {
            JxCameraCore.shared.request().fetchDictionaryJson { (result: Result<[String: Any], any Error>) in
                switch result {
                case .success(let res):
                    let dictList = res["Dic"] as? [[String: Any]]
                    MenuData.shared.dictList = dictList
                    self.getAllSettings()
                case .failure(let error):
                    print("请求失败: \(error.localizedDescription)")
                    self.tableView.mj_header?.endRefreshing()
                }
            }
        }else{
            self.getAllSettings()
        }
    }
    
    func getAllSettings() {
        JxCameraCore.shared.request().fetchAllSettings { (result: Result<[String: Any], any Error>) in
            switch result {
            case .success(let res):
                MenuData.shared.settingMap = res
            case .failure(let error):
                print("请求失败: \(error.localizedDescription)")
            }
            self.tableView.mj_header?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    var selectedIndexPath: IndexPath? = nil
}

// MARK: - UITableViewDelegate & DataSource

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuData.shared.menuList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingViewCell", for: indexPath) as! SettingViewCell
        cell.selectionStyle = .none
        if let item = MenuData.shared.menuList?[indexPath.row] {
            cell.configure(with: item)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        let language = MenuData.shared.language
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
}
