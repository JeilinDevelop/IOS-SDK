//
//  ViewController.swift
//  JxCameraSample
//
//  Created by jxcs on 2026/3/12.
//

import CoreLocation
import FGRoute
import Foundation
import Network
import NetworkExtension
import SnapKit
import UIKit
import Kingfisher
import JxCameraSDK


class ViewController: UIViewController {
    // MARK: - Properties
    
    private let addCameraButton: UIButton = {
        let button = UIButton()
        button.setTitle("添加相机", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#5A8DDF")
        button.layer.cornerRadius = 10
        return button
    }()
    
    private let cameraInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 5
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor(hex: "#DCD8D8").cgColor
        view.isHidden = true
        return view
    }()
    
    private let cameraNameLabel: UILabel = {
        let label = UILabel()
        label.text = "相机名称"
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 17)
        return label
    }()
    
    private let cameraStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "未连接"
        label.textColor = UIColor(hex: "#666666")
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let connectCameraButton: UIButton = {
        let button = UIButton()
        button.setTitle("进入相机", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#5A8DDF")
        button.layer.cornerRadius = 3
        button.titleLabel?.font = .systemFont(ofSize: 13)
        return button
    }()
    
    private let locationManager = CLLocationManager()
    private func requestLocationAccess() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        JxCameraCore.shared.initialize(context: UIApplication.shared, config: SDKConfig())
        JxCameraCore.shared.startMonitoring()
        setupUI()
        setupConstraints()
        setupActions()
        
        AppConstants.registDefaults()
        
        JxCameraCore.shared.setUseSSL(AppConstants.isSettingSSL())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 设置返回按钮颜色为黑色（系统的 "<" 图标）
        navigationController?.navigationBar.tintColor = .black
        // 设置导航栏背景色为白色
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.backgroundColor = .white
        
        // 设置标题颜色为黑色
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 17)
        ]
        
        // iOS 15+ 需额外设置 scrollEdgeAppearance
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        
        checkLocationPermission { status in
            switch status {
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
            case .denied:
                self.showPermissionAlert()
            case .authorized:
                print("有权限")
                self.setupNetworkMonitor()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("viewDidDisappear")
    }
    
    func setupNetworkMonitor() {
        JxCameraCore.shared.setCameraNetDelegate(self)
        JxCameraCore.shared.fetchNetInfo()
    }
    
    
    private func handleNetworkUpdate(_ iface: ManagedInterface?, _ all: [ManagedInterface]?) {
        // 根据当前接口更新 UI
        if let interface = iface {
            print("接口 \(interface.type): 可用=\(interface.isAvailable) 公网=\(interface.isInternetReachable) 相机热点=\(interface.isCameraWifi)")
        } else {
            print("没有可用接口了")
        }
    }
    
    func showPermissionAlert() {
        let alert = UIAlertController(title: "需要位置权限",
                                      message: "请在设置中开启位置权限以获取Wi-Fi信息",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            if let appSettings = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(appSettings)
            {
                UIApplication.shared.open(appSettings)
            }
        })
        present(alert, animated: true)
    }
    
    private var currentNetwork: Network.NWPath?
    private var ssid: String?
    private var ipAddress: String?
    private var bssid: String?
    private let LOCAL_IP_PREFIX = "192.168.1"

    private var connectStatus = 0
    
    func updateStatus(ssid: String?, bssid: String?, ipAddress: String?) {
        self.ssid = ssid
        self.bssid = bssid
        // 获取IP地址
        self.ipAddress = ipAddress
        updateCameraView()
    }
    
    private func updateCameraView() {
        if let currentSSID = ssid, let ipAddress = ipAddress, ipAddress.hasPrefix(LOCAL_IP_PREFIX) {
            cameraInfoView.isHidden = false
            addCameraButton.isHidden = true
            cameraNameLabel.text = currentSSID
            cameraStatusLabel.text = "已连接"
            connectStatus = 1
        } else {
            cameraStatusLabel.text = "未连接"
            connectStatus = -1
        }
    }
    
    func showCameraConnectionAlert(on viewController: UIViewController, cameraName: String, connectHandler: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "连接提示",
            message: "检测到\(cameraName)设备，是否尝试连接？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "连接", style: .default, handler: { _ in
            connectHandler()
        }))
        
        viewController.present(alert, animated: true, completion: nil)
    }

    private func verifyConnection(completion: @escaping (Bool) -> Void) {
        // 这里实现网络验证逻辑
        JxCameraCore.shared.request().sendAliveAck { (result: Result<HttpResult, Error>) in
            switch result {
            case .success(let res):
                print("返回数据:\(res.result)")
                completion(true)
            case .failure(let error):
                print("网络请求失败: \(error.localizedDescription)")
                completion(false)
                return
            }
        }
    }
    
    enum WiFiPermissionStatus {
        case notDetermined
        case denied
        case authorized
    }

    private func checkLocationPermission(_ type: Int = 0, completion: @escaping (WiFiPermissionStatus) -> Void) {
        let status = CLLocationManager().authorizationStatus
        switch status {
        case .notDetermined:
            // 初次启动，主动申请
            completion(.notDetermined)
            return
        case .denied, .restricted:
            // 被拒绝或受限制，需要引导用户去系统设置开启
            completion(.denied)
            return
        case .authorizedWhenInUse, .authorizedAlways:
            // 已授权
            completion(.authorized)
        default:
            break
        }
    }
    
    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(addCameraButton)
        view.addSubview(cameraInfoView)
        
        cameraInfoView.addSubview(cameraNameLabel)
        cameraInfoView.addSubview(cameraStatusLabel)
        cameraInfoView.addSubview(buttonStackView)
        
        buttonStackView.addArrangedSubview(connectCameraButton)
    }
    
    private func setupConstraints() {
        
        cameraNameLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(10)
        }
        
        cameraStatusLabel.snp.makeConstraints { make in
            make.centerY.equalTo(cameraNameLabel)
            make.right.equalToSuperview().offset(-10)
        }
        
        buttonStackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.top.equalTo(cameraNameLabel.snp.bottom).offset(10)
            make.height.equalTo(25)
        }
        
        addCameraButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-50)
            }else{
                make.bottom.equalTo(view).offset(-50)
            }
            make.height.equalTo(40)
        }
        
        cameraInfoView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-50)
            }else{
                make.bottom.equalTo(view).offset(-50)
            }
            make.height.equalTo(80)
        }
        
        connectCameraButton.snp.makeConstraints { make in
            make.width.equalTo(70)
        }
        
        let bottomInset = self.view.safeAreaInsets.bottom
        print("viewDidAppear -> bottom inset: \(bottomInset)")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    private func setupActions() {
        addCameraButton.addTarget(self, action: #selector(addCameraButtonTapped), for: .touchUpInside)
        connectCameraButton.addTarget(self, action: #selector(connectCameraButtonTapped), for: .touchUpInside)
    }

    
    @objc private func addCameraButtonTapped() {
        checkLocationPermission { status in
            switch status {
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
            case .denied:
                self.showPermissionAlert()
            case .authorized:
                // 处理添加按钮点击
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
    
    @objc private func connectCameraButtonTapped() {
        if connectStatus == 1 {
            let sslConfig = JxCameraCore.shared.getSSLConfig()
            let host = JxCameraCore.shared.getHost()
            let client = AlamofireHttpClient(sslConfig:sslConfig,host:host)
            JxCameraCore.shared.setHttpClient(client)
            JxCameraCore.shared.connectCamera(timeout: 8) { result in
                switch result {
                case .success:
                    self.getCurrentWorkMode()
                    break
                case .failure(let error):
                    print("网络请求失败: \(error.localizedDescription)")
                    self.showToast(error.localizedDescription)
                    break
                }
            }
        } else {
            self.showToast("请连接相机WiFi")
        }
    }
    
    private func getCurrentWorkMode(){
        JxCameraCore.shared.request().fetchCurrentWorkMode{ (result: Result<CurrentWorkMode, Error>) in
            switch result {
            case .success(let res):
                AppConstants.setModeType(res.mode)
                
                let workMode = AppConstants.workMode
                if (workMode != nil && (workMode == WorkMode.photoCapture || workMode == WorkMode.videoCapture)) {
                    self.changeMode(workMode?.rawValue ?? WorkMode.photoCapture.rawValue)
                } else {
                    self.changeMode(WorkMode.photoCapture.rawValue)
                }
            case .failure(let error):
                print("网络请求失败: \(error.localizedDescription)")
                self.changeMode(WorkMode.photoCapture.rawValue)
                return
            }
        }
    }
    
    private func changeMode(_ workMode:String){
        JxCameraCore.shared.request().changeMode(to: workMode){(result: Result<HttpResult, Error>) in
            switch result {
            case .success(let res):
                if res.result == 0 {
                    AppConstants.setModeType(workMode)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.openCameraTabBar()
                    }
                }else{
                    self.showToast("请重试")
                }
            case .failure(let error):
                print("网络请求失败: \(error.localizedDescription)")
                self.showToast(error.localizedDescription)
                return
            }
        }
    }
    
    private func openCameraTabBar(){
        let cameraTabBar = MainTabBarController()
        cameraTabBar.setViewControllers([
            (UINavigationController(rootViewController: CameraViewController()), "相机", "camera_home_off_ic", "camera_home_on_ic"),
            (UINavigationController(rootViewController: GalleryViewController()), "相册", "home_photo_off_ic", "home_photo_on_ic"),
            (UINavigationController(rootViewController: SettingViewController()), "设置", "camera_setting_off_ic", "camera_setting_on_ic")
        ])
        
        cameraTabBar.modalPresentationStyle = .fullScreen
        present(cameraTabBar, animated: true, completion: nil)
    }

    deinit {
        JxCameraCore.shared.stopMonitoring()
    }
}

extension ViewController: CLLocationManagerDelegate {
    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("Location access granted.")
            // 重新获取当前 SSID，IP
//            NetworkManager.shared.fetchSSID { ssid, bssid in
//                print("locationManager fetchSSID，SSID: \(ssid ?? "-")")
//                self.updateStatus(ssid: ssid, bssid: bssid, ipAddress: NetworkManager.shared.getIPAddress())
//            }
        } else {
            print("Location access denied.")
        }
    }
}

extension ViewController: JxCameraNetDelegate {
    func net(_ network: JxNetwork, statusChanged interface: ManagedInterface?, interfaces: [ManagedInterface]) {
        print("全局接口变化")
        self.handleNetworkUpdate(interface, interfaces)
    }
    
    func net(_ network: JxNetwork, didFetchWifi interface: ManagedInterface) {
        print("刷新WiFi信息: \(interface.description)")
        // 做一些相机连接后的操作
        self.updateStatus(ssid: interface.ssid, bssid: interface.bssid, ipAddress: interface.ipAddress)
    }
    
    func net(_ network: JxNetwork, cameraWifiConnected interface: ManagedInterface) {
        print("相机已连接: \(interface.description)")
        // 做一些相机连接后的操作
        self.updateStatus(ssid: interface.ssid, bssid: interface.bssid, ipAddress: interface.ipAddress)
    }
    
    func netDidDisconnectCameraWifi(_ network: JxNetwork) {
        print("相机已断开")
        // 做一些相机断开后的操作
        self.updateStatus(ssid: nil, bssid: nil, ipAddress: nil)
    }
}
