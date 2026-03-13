//
//  CameraViewController.swift
//  Polaroid
//
//  Created by jxcs on 2025/7/28.
//

import Alamofire
import AVFoundation
import CoreLocation
import FGRoute
import JxCameraSDK
import Kingfisher
import Masonry
import MJRefresh
import Network
import Toast_Swift
import UIKit
import SnapKit

class CameraViewController: UIViewController, UIGestureRecognizerDelegate {
    // MARK: - UI Elements

    // Top Bar
    private let topBarView: UIView = {
        let view = UIView()
        return view
    }()

    private let backView: UIView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 1

        let image: UIImage?
//        if let customImage = UIImage(named: "ic_back") {
//            image = customImage.withRenderingMode(.alwaysTemplate)
//        } else {
        image = UIImage(systemName: "chevron.left")
//        }
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .black
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let label = UILabel()
        label.text = "返回"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 17)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        return stackView
    }()

    private let titleView: UILabel = {
        let label = UILabel()
        label.text = "相机"
        label.textColor = UIColor.label // 跟随系统主题
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let tipButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_device"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()

    private let batteryBarView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let chargingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_charge")?.withTintColor(UIColor(hex: "#5A8DDF"))
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let batteryLevelImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_battery_state_3")?.withTintColor(UIColor(hex: "#5A8DDF"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // Content Views
    private let remoteView: UIView = {
        let view = UIView()
        return view
    }()

    private let noCameraTextView: UILabel = {
        let label = UILabel()
        label.text = "No Camera\nConnected"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17)
        label.backgroundColor = .black
        label.numberOfLines = 0
        return label
    }()

    private let mjpegView: UIImageView = {
        let view = UIImageView()
//        view.isHidden = true
        view.backgroundColor = .clear
        view.tintAdjustmentMode = .normal
        return view
    }()

    private let wifiConnectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("连接相机", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)

        // 高度 25，圆角 12
        button.layer.cornerRadius = 15
        button.layer.masksToBounds = true

        // 白色描边
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor

        // 横向 padding = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)

        button.backgroundColor = UIColor(hex: "#000000", alpha: 0.3)
        button.isHidden = true

        return button
    }()

    private let activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.center = view.center
        view.hidesWhenStopped = true // 停止时隐藏
        return view
    }()

    private let recordTimeView: UIView = {
        let view = UIView()
        return view
    }()

    private let recordTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .black
        label.isHidden = true
        return label
    }()

    private let remoteControlView: UIView = {
        let view = UIView()
        return view
    }()

    private let photoButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_photo")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(named: "icon_photo")?.withRenderingMode(.alwaysTemplate), for: .disabled)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor.gray
        return button
    }()

    private let recordButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_recod_start"), for: .normal)
        button.setImage(UIImage(named: "icon_recod_start"), for: .disabled)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()

    private let videoButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_recod")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(named: "icon_recod")?.withRenderingMode(.alwaysTemplate), for: .disabled)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor.gray
        return button
    }()

    // Tip View
    private let tipView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        view.isHidden = true
        return view
    }()

    private let tipCloseButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_close"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()

    private let tipImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "bg_tip")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Properties

    private var mjpegStatus = 0
    private var recordStatus = 0
    private var seconds = 0
    private var timer: Timer?
//        private var galleryAdapter: GalleryAdapter?
    private var isWifiConnected = false
    private var isAppInForeground = false
    private var currentWorkMode = WorkMode.photoCapture // 1: PhotoCapture, 2: VideoCapture
    private var shutter = 0
    private var pageIndex = 0
    private var pageSize = 16
    private var photoPlayer: AVAudioPlayer?
    private var videoPlayer: AVAudioPlayer?

    var streamingController: MjpegStreamingController?

    var hasLaunchedBefore = true

    var hasPreview = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "相机"

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

        addSwipeToDismissGesture()

        setupUI()
        setupActions()
        setupSocket()

        photoPlayer = createAudioPlayer(resource: "photo_sound", type: "wav")
        videoPlayer = createAudioPlayer(resource: "video_sound", type: "wav")

        streamingController = MjpegStreamingController()
        streamingController?.didStartLoading = { [weak self] in
            guard let self = self else { return }
            self.activityIndicatorView.startAnimating()
            self.hasPreview = false
        }
        streamingController?.didFinishLoading = { [weak self] in
            guard let self = self else { return }
            self.activityIndicatorView.stopAnimating()
            self.hasPreview = true
        }

        streamingController?.didReceiveImage = { [weak mjpegView] image in
            guard let imageView = mjpegView else { return }

            imageView.image = image

            let ratio = image.size.height / image.size.width
            let height = UIScreen.main.bounds.width * ratio

            imageView.snp.updateConstraints {
                $0.height.equalTo(height)
            }

            self.hasPreview = true
        }
        streamingController?.contentURL = URL(string: JxCameraCore.shared.getMjpegURL())

        if let workMode = AppConstants.workMode, workMode == .photoCapture || workMode == .videoCapture {
            currentWorkMode = workMode
        }
        updateControlButton()

        let isSyncTime = AppConstants.isSettingSyncTime()
        if isSyncTime {
            tryUpdateTimeDate()
        }
        
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache {
            print("Disk cache cleared")
        }
    }

    func tryUpdateTimeDate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.isAppInForeground {
                self.updateTimeDate()
            } else {
                self.tryUpdateTimeDate() // 不在前台继续延迟10秒后重试
            }
        }
    }

    func updateTimeDate() {
        JxCameraCore.shared.request().updateDateTime(at: Date()) { (result: Result<HttpResult, Error>) in
            switch result {
            case .success(let res):
                print("返回数据:\(res.result)")
            case .failure(let error):
                print("网络请求失败: \(error.localizedDescription)")
                return
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        setupNetworkMonitor()
        isAppInForeground = true
        startNetworkDependentTasks()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        isAppInForeground = false
        stopBatteryStatusTimer()
        stopNetworkDependentTasks()
    }

    func refreshStatus() {
        print("refreshStatus")
        startBatteryStatusTimer()
        startNetworkDependentTasks()
    }

    private func addSwipeToDismissGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let progress = translation.x / view.bounds.width

        switch gesture.state {
        case .changed:
            if translation.x > 0 {
                view.transform = CGAffineTransform(translationX: translation.x, y: 0)
                view.alpha = 1 - progress * 0.5
            }

        case .ended, .cancelled:
            if progress > 0.3 {
                // 模仿 Android 的 alpha 淡出动画
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.alpha = 0
                    self.view.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
                }) { _ in
                    self.dismiss(animated: false, completion: nil)
                }
            } else {
                // 回弹
                UIView.animate(withDuration: 0.2) {
                    self.view.transform = .identity
                    self.view.alpha = 1.0
                }
            }

        default:
            break
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let location = pan.location(in: view)
            // 限制手势必须从左边缘 30pt 以内开始
            return location.x < 30
        }
        return true
    }

    @objc func backToHome() {
        dismiss(animated: true, completion: nil)
    }

    func createAudioPlayer(resource: String, type: String) -> AVAudioPlayer? {
        if let filePath = Bundle.main.path(forResource: resource, ofType: type) {
            let fileURL = URL(fileURLWithPath: filePath)
            do {
                // 初始化 AVAudioPlayer
                let audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                audioPlayer.prepareToPlay() // 准备播放
                print("初始化音频播放")
                return audioPlayer
            } catch {
                print("音频播放出错：\(error.localizedDescription)")
            }
        } else {
            print("音频文件未找到")
        }
        return nil
    }

    func setupNetworkMonitor() {
        JxCameraCore.shared.setCameraNetDelegate(self)
        JxCameraCore.shared.fetchNetInfo()
    }

    private func setupUI() {
        tipButton.isHidden = true

        view.addSubview(topBarView)
        topBarView.addSubview(backView)
        topBarView.addSubview(titleView)
        topBarView.addSubview(tipButton)

        view.addSubview(remoteView)
        remoteView.addSubview(noCameraTextView)
        remoteView.addSubview(mjpegView)
        remoteView.addSubview(wifiConnectButton)
        remoteView.addSubview(activityIndicatorView)
        remoteView.addSubview(recordTimeView)
        recordTimeView.addSubview(recordTimeLabel)
        remoteView.addSubview(remoteControlView)
        remoteControlView.addSubview(photoButton)
        remoteControlView.addSubview(recordButton)
        remoteControlView.addSubview(videoButton)

        remoteView.addSubview(batteryBarView)
        batteryBarView.addSubview(chargingImageView)
        batteryBarView.addSubview(batteryLevelImageView)

        view.addSubview(tipView)
        tipView.addSubview(tipCloseButton)
        tipView.addSubview(tipImageView)

        // --- 使用 SnapKit 替代 Masonry 的约束 ---
        topBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }

        backView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.height.equalTo(25)
        }

        titleView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }

        tipButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(25)
        }

        remoteView.snp.makeConstraints { make in
            make.top.equalTo(topBarView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        noCameraTextView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(180)
        }

        mjpegView.snp.makeConstraints { make in
            make.top.equalTo(noCameraTextView.snp.top)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(180)
        }

        wifiConnectButton.snp.makeConstraints { make in
            make.center.equalTo(mjpegView) // 完全居中
            make.height.equalTo(30)
        }

        activityIndicatorView.snp.makeConstraints { make in
            make.top.equalTo(mjpegView.snp.bottom)
            make.left.right.equalTo(mjpegView)
        }

        recordTimeView.snp.makeConstraints { make in
            make.top.equalTo(mjpegView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(remoteControlView.snp.top)
        }

        recordTimeLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        remoteControlView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-50)
            make.height.equalTo(80)
        }

        photoButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(30)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(remoteControlView.snp.width).multipliedBy(1.0 / 3.0).offset(-70)
        }

        recordButton.snp.makeConstraints { make in
            make.left.equalTo(photoButton.snp.right)
            make.right.equalTo(videoButton.snp.left)
            make.top.bottom.equalToSuperview()
        }

        videoButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-30)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(remoteControlView.snp.width).multipliedBy(1.0 / 3.0).offset(-70)
        }

        batteryBarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.top.equalToSuperview().offset(20)
        }

        batteryLevelImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(30)
        }

        chargingImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(batteryLevelImageView.snp.right).offset(-2)
            make.height.equalTo(12)
        }

        tipView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tipCloseButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.right.equalToSuperview().offset(-15)
        }

        tipImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
    }

    // MARK: - Actions Setup

    private func setupActions() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(backToHome))
        backView.isUserInteractionEnabled = true
        backView.addGestureRecognizer(tap)

        tipCloseButton.addTarget(self, action: #selector(closeTipView), for: .touchUpInside)
        tipButton.addTarget(self, action: #selector(showTipView), for: .touchUpInside)

        wifiConnectButton.addTarget(self,
                                    action: #selector(connectCameraAction),
                                    for: .touchUpInside)

        photoButton.addTarget(self, action: #selector(photoAction), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(recordAction), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(videoAction), for: .touchUpInside)
    }

    // MARK: - Button Actions

    @objc private func showTipView() {
//        tipView.isHidden = false
        batteryBarView.isHidden = true
//        mjpegView.isHidden = true
        wifiConnectButton.isHidden = false
    }

    @objc private func closeTipView() {
//        tipView.isHidden = true
        batteryBarView.isHidden = false
//        mjpegView.isHidden = false
        wifiConnectButton.isHidden = true
    }

    @objc private func connectCameraAction() {
        // 跳转 Wi-Fi 设置 / 相机列表
        print("点击连接相机")
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func photoAction() {
        currentWorkMode = WorkMode.photoCapture
        startStream(workMode: currentWorkMode)
    }

    private var isShutter = false
    @objc private func recordAction() {
        isShutter = true
        startCapture()
        if currentWorkMode == WorkMode.photoCapture {
            shutter = 1
            photoPlayer?.play()
        }
        if currentWorkMode == WorkMode.videoCapture {
            shutter = shutter == 0 ? 1 : 0
            videoPlayer?.play()
        }
        recordStatus = 1
        updateControlButton(1)
        streamingController?.stop()
        JxCameraCore.shared.request().setShutter(to: shutter) { (result: Result<SetupShutter, Error>) in
            self.isShutter = false
            switch result {
            case .success(let res):
                if res.result == 0 {
                    if self.currentWorkMode == WorkMode.videoCapture {
                        if self.shutter == 1 {
                            self.startRecordTimer()
                        } else {
                            self.finishCapture()
                            self.stopRecordTimer()
                        }
                    } else {
                        self.finishCapture()
                        self.shutter = 0
                        self.recordStatus = 0
                    }
                } else {
                    self.finishCapture()
                    self.showToast(message: res.caption ?? res.msg ?? "")
                    if self.currentWorkMode == WorkMode.videoCapture {
                        if self.shutter == 1 {
                            self.shutter = 0
                            self.recordStatus = 0
                        } else {
                            self.stopRecordTimer()
                        }
                    } else {
                        self.shutter = 0
                        self.recordStatus = 0
                    }
                }
            case .failure:
                self.recordStatus = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.streamingController?.play()
                self.updateControlButton()
            }
        }
    }

    @objc private func videoAction() {
        currentWorkMode = WorkMode.videoCapture
        startStream(workMode: currentWorkMode)
    }
    
    private var mainTabBar: MainTabBarController? {
        var parentVC = parent
        while parentVC != nil {
            if let tab = parentVC as? MainTabBarController {
                return tab
            }
            parentVC = parentVC?.parent
        }
        return nil
    }

    func startCapture() {
        mainTabBar?.tabSwitchEnabled = false
    }

    func finishCapture() {
        mainTabBar?.tabSwitchEnabled = true
    }

    // MARK: - Record Timer

    private func startRecordTimer(_ time: Int = 0) {
        timer?.invalidate()
        timer = nil
        recordStatus = 2
        seconds = time
        print("录制时长：\(seconds)")
        recordTimeFormatted()
        recordTimeLabel.isHidden = false
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(recordTimeTimer), userInfo: nil, repeats: true)
    }

    private func stopRecordTimer() {
        timer?.invalidate()
        timer = nil
        recordStatus = 0
        recordTimeLabel.isHidden = true
    }

    @objc private func recordTimeTimer() {
        recordStatus = 3
        seconds += 1
        recordTimeFormatted()
    }

    private func recordTimeFormatted() {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        let formattedTime: String
        if hours > 0 {
            // 超过 1 小时：HH:MM:SS
            formattedTime = String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            // 1 小时以内：MM:SS
            formattedTime = String(format: "%02d:%02d", minutes, remainingSeconds)
        }

        recordTimeLabel.text = formattedTime
    }

    // MARK: - Re-start Preview

    private lazy var reStartPreviewRunnable: () -> Void = { [weak self] in
        guard let self = self else { return }
//        if self.recordStatus >= 2 {
//            if self.currentWorkMode == WorkMode.videoCapture {
//                self.stopRecordTimer()
//            }
//        }

        if self.isShutter {
            return
        }
        if self.isAppInForeground && self.isWifiConnected {
            streamingController?.stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.streamingController?.play()
                self.updateControlButton()
            }
        }
    }

    // MARK: - Battery Status

    var batteryStatusTimer: Timer?
    private func startBatteryStatusTimer(delayMillis: TimeInterval = 30) {
        batteryStatusTimer?.invalidate()
        batteryStatusTimer = nil

        // 第一次立即执行 fetchBatteryStatus
        if isAppInForeground && isWifiConnected {
            fetchBatteryStatus()
        }

        var isBatteryStatusTurn = false // 用于交替执行

        batteryStatusTimer = Timer.scheduledTimer(withTimeInterval: delayMillis, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isAppInForeground && self.isWifiConnected {
                if isBatteryStatusTurn {
                    self.fetchBatteryStatus()
                } else {
                    self.sendAliveAck()
                }
                isBatteryStatusTurn.toggle() // 切换执行类型
            }
        }
    }

    private func stopBatteryStatusTimer() {
        batteryStatusTimer?.invalidate()
        batteryStatusTimer = nil
    }

    func fetchBatteryStatus() {
        JxCameraCore.shared.request().fetchBatteryStatus { (result: Result<BatteryStatus, any Error>) in
            switch result {
            case .success(let res):
                if res.result == 0 {
                    self.batteryBarView.isHidden = false
                    guard let level = res.level else { return }
                    if level >= 128 {
                        self.chargingImageView.isHidden = false
                        self.batteryLevelImageView.image = UIImage(named: self.getBatteryLevelImage(level: BatteryLevel.full))?.withTintColor(UIColor(hex: "#5A8DDF"))
                    } else {
                        self.chargingImageView.isHidden = true
                        if let batteryLevel = BatteryLevel(rawValue: level) {
                            self.batteryLevelImageView.image = UIImage(named: self.getBatteryLevelImage(level: batteryLevel))?.withTintColor(UIColor(hex: "#5A8DDF"))
                        }
                    }
                } else {
                    self.batteryBarView.isHidden = true
                }
            case .failure:
                self.batteryBarView.isHidden = true
            }
        }
    }

    private func getBatteryLevelImage(level: BatteryLevel) -> String {
        switch level {
        case .low:
            return "icon_battery_state_1"
        case .normal:
            return "icon_battery_state_2"
        case .full:
            return "icon_battery_state_3"
        default:
            return "icon_battery_state_0"
        }
    }

    func sendAliveAck() {
        JxCameraCore.shared.request().sendAliveAck { (result: Result<HttpResult, Error>) in
            switch result {
            case .success(let res):
                print("返回数据:\(res.result)")
            case .failure(let error):
                print("网络请求失败: \(error.localizedDescription)")
                return
            }
        }
    }

    private func startNetworkDependentTasks() {
        print("startNetworkDependentTasks")
        DispatchQueue.main.async {
            self.closeTipView()
        }
        startStream(workMode: currentWorkMode)
        if currentWorkMode == WorkMode.videoCapture {
            fetchRecordingStatus()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.startBatteryStatusTimer()
        }
    }

    private func stopNetworkDependentTasks() {
        print("stopNetworkDependentTasks")
        DispatchQueue.main.async {
            self.showTipView()
        }
        stopStream()
        stopBatteryStatusTimer()
        checkByStopRecord()
    }

    func startStream(workMode: WorkMode) {
        streamingController?.stop()
        if AppConstants.workMode != workMode {
            JxCameraCore.shared.request().changeMode(to: workMode.rawValue) { (result: Result<HttpResult, any Error>) in
                switch result {
                case .success(let res):
                    if res.result == 0 {
                        AppConstants.setModeType(workMode.rawValue)
                    }
                case .failure(let error):
                    print("请求失败: \(error.localizedDescription)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.streamingController?.play()
                    self.updateControlButton()
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.streamingController?.play()
                self.updateControlButton()
            }
        }
    }

    func stopStream() {
        AppConstants.workMode = nil
        streamingController?.stop()
        updateControlButton()
    }

    func updateControlButton(_ flag: Int = 0) {
        print("updateControlButton")
        let connected = isWifiConnected || JxCameraCore.shared.isSocketState() == .connected

        recordButton.isEnabled = connected
        recordButton.tintColor = connected ? .black : .gray
        recordButton.alpha = connected ? 1.0 : 0.5

        photoButton.isEnabled = connected
        videoButton.isEnabled = connected
    
        photoButton.alpha = connected ? 1.0 : 0.5
        videoButton.alpha = connected ? 1.0 : 0.5

        if connected {
            if currentWorkMode == .photoCapture {
                photoButton.tintColor = .black
                videoButton.tintColor = .gray
            } else {
                photoButton.tintColor = .gray
                videoButton.tintColor = .black
            }
            if isShutter || recordStatus >= 1 {
                photoButton.isEnabled = false
                videoButton.isEnabled = false
                photoButton.alpha = 0.5
                videoButton.alpha = 0.5
            }
        } else {
            photoButton.tintColor = .gray
            videoButton.tintColor = .gray
        }
    }

    func fetchRecordingStatus() {
        JxCameraCore.shared.request().fetchRecordingStatus { (result: Result<RecordStatus, any Error>) in
            switch result {
            case .success(let res):
                if res.result == 0 {
                    if res.aviRecording == 1 || res.mp4Recording == 1 {
                        self.isShutter = true
                        self.startCapture()
                        self.shutter = 1
                        self.recordStatus = 1
                        self.updateControlButton(1)
                        let time = res.time ?? 0
                        self.startRecordTimer(time / 1000)
                    }
                }
            case .failure(let error):
                print("请求失败: \(error.localizedDescription)")
            }
        }
    }

    func checkByStopRecord() {
        if currentWorkMode == WorkMode.videoCapture && recordStatus >= 1 {
            JxCameraCore.shared.request().setShutter(to: 0) { (result: Result<SetupShutter, Error>) in
                switch result {
                case .success(let res):
                    if res.result == 0 {
                        self.stopRecordTimer()
                    }
                case .failure:
                    self.recordStatus = 0
                }
            }
        }
    }

//    var socket: SocketIO? = nil

    // MARK: - Socket Setup

    private func setupSocket() {
//        let socket = SocketIO(serverAddress: AppConstants.host, serverPort: AppConstants.socketPort)
//        socket.delegate = self
//        socket.connect()
//        self.socket = socket

        JxCameraCore.shared.setCameraSocketDelegate(self)
    }

    // MARK: - Socket Event Handler

    private func handleSocketEvent(event: Int) {
        switch event {
        case 1:
            if shutter == 1 {
                shutter = 0
            }
            DispatchQueue.main.async {
                self.stopRecordTimer()
            }
        case 4:
            DispatchQueue.main.async {
                self.reStartPreviewRunnable()
            }
        case 6:
            DispatchQueue.main.async {
                self.showToast(message: "Device no power")
            }
        case 10:
            DispatchQueue.main.async {
                self.showToast(message: "SD Card error")
            }
        case 11:
            DispatchQueue.main.async {
                self.showToast(message: "SD Card full")
            }
        case 12:
            DispatchQueue.main.async {
                self.showToast(message: "SD Card inserted")
            }
        case 15:
            DispatchQueue.main.async {
                self.showToast(message: "SD Card red fail")
            }
        case 16:
            DispatchQueue.main.async {
                self.showToast(message: "SD Card write protect")
            }
        default:
            break
        }
    }

    private let LOCAL_IP_PREFIX = "192.168.1"

    func updateStatus(ssid: String?, bssid: String?, ipAddress: String?) {
        if let currentSSID = ssid {
            isWifiConnected = true
            startNetworkDependentTasks()
        } else {
            isWifiConnected = false
            stopNetworkDependentTasks()
        }
    }
}

extension CameraViewController: JxCameraNetDelegate {
    func net(_ network: JxNetwork, statusChanged interface: ManagedInterface?, interfaces: [ManagedInterface]) {
        print("全局接口变化")
    }

    func net(_ network: JxNetwork, didFetchWifi interface: ManagedInterface) {
        print("刷新WiFi信息: \(interface.description)")
        // 做一些相机连接后的操作
        updateStatus(ssid: interface.ssid, bssid: interface.bssid, ipAddress: interface.ipAddress)
    }

    func net(_ network: JxNetwork, cameraWifiConnected interface: ManagedInterface) {
        print("相机已连接: \(interface.description)")
        // 做一些相机连接后的操作
        updateStatus(ssid: interface.ssid, bssid: interface.bssid, ipAddress: interface.ipAddress)
    }

    func netDidDisconnectCameraWifi(_ network: JxNetwork) {
        print("相机已断开")
        // 做一些相机断开后的操作
        updateStatus(ssid: nil, bssid: nil, ipAddress: nil)
    }
}

extension CameraViewController: JxCameraSocketDelegate {
    func socketDidConnect(_ socket: JxSocket) {
        print("Socket connected")
        startNetworkDependentTasks()
    }

    func socket(_ socket: JxSocket, didDisconnectWith error: Error?) {
        if let error = error {
            print("Socket disconnected with error: \(error)")
        } else {
            print("Socket disconnected")
        }
        stopNetworkDependentTasks()
    }

    func socket(_ socket: JxSocket, didReceiveMessage message: String) {
        print("Socket Received message: \(message)")
        do {
            if let data = message.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            {
                if let event = json["Event"] as? Int {
                    handleSocketEvent(event: event)
                }
                if let recodingLength = json["AVIRecodingLength"] as? Int {
                    print("Socket AVIRecodingLength: \(recodingLength)")
                }
            }
        } catch {
            print("Socket Error parsing socket message: \(error)")
        }
    }

    func socket(_ socket: JxSocket, didChangeState state: SocketState) {
        print("Socket Change State to: \(state.description)")
        if state == SocketState.connected {
            DispatchQueue.main.async {
                self.closeTipView()
            }
        }
    }
    
    func socketHeartbeatTimeout(_ socket: JxSocket, missCount: Int) {
        print("Socket Heartbeat Timeout to: \(missCount)")
        
    }
}
