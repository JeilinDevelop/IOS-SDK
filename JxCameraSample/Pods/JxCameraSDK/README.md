# JxCamera SDK 使用文档

JxCameraSDK 是一个用于连接和控制相机设备的 iOS SDK，支持 WiFi 和蓝牙连接，提供完整的相机控制、设置管理、文件存储等功能。

## 目录

- [安装](#安装)
- [快速开始](#快速开始)
- [核心功能](#核心功能)
  - [1. SDK 初始化](#1-sdk-初始化)
  - [2. 网络监控](#2-网络监控)
  - [3. 蓝牙管理](#3-蓝牙管理)
  - [4. 相机连接](#4-相机连接)
  - [5. HTTP 请求](#5-http-请求)
  - [6. Socket 通信](#6-socket-通信)
  - [7. 自定义 HTTP 客户端](#7-自定义-http-客户端)
- [完整示例](#完整示例)
- [API 参考](#api-参考)

---

## 安装

### CocoaPods

在 `Podfile` 中添加：

```ruby
pod 'JxCameraSDK', '1.0.2'
```

然后运行：

```bash
pod install
```

---

## 快速开始

```swift
import JxCameraSDK

// 1. 初始化 SDK
let config = SDKConfig(
    logLevel: .info,
    connectTimeout: 8,
    readTimeout: 15,
    autoReconnect: true
)
JxCameraCore.shared.initialize(context: UIApplication.shared, config: config)

// 2. 开始网络监控
JxCameraCore.shared.startMonitoring()

// 3. 连接相机
JxCameraCore.shared.connectCamera { result in
    switch result {
    case .success:
        print("相机连接成功")
    case .failure(let error):
        print("连接失败: \(error)")
    }
}

// 4. 发送请求
JxCameraCore.shared.request().fetchMiscInfo { (result: Result<MiscInfo, Error>) in
    switch result {
    case .success(let info):
        print("相机信息: \(info)")
    case .failure(let error):
        print("请求失败: \(error)")
    }
}
```

---

## 核心功能

### 1. SDK 初始化

#### 配置参数

```swift
let config = SDKConfig(
    logLevel: .info,              // 日志级别: debug, info, warn, error
    connectTimeout: 8,            // 连接超时时间（秒）
    readTimeout: 15,              // 读取超时时间（秒）
    retryCount: 2,                // 重试次数
    autoReconnect: true,          // 是否自动重连
    reconnectAttempts: 3,         // 重连尝试次数
    reconnectInterval: 3,         // 重连间隔（秒）
    maxReconnectAttempts: 5       // 最大重连次数
)
```

#### 初始化 SDK

```swift
JxCameraCore.shared.initialize(context: UIApplication.shared, config: config)
```

#### SSL 配置（可选）

```swift
// 启用 SSL
JxCameraCore.shared.setUseSSL(true)
```

---

### 2. 网络监控

SDK 提供网络状态监控功能，自动检测 WiFi 连接状态和相机热点。

#### 开始监控

```swift
JxCameraCore.shared.startMonitoring()
```

#### 停止监控

```swift
JxCameraCore.shared.stopMonitoring()
```

#### 设置网络代理

```swift
class MyViewController: UIViewController, JxCameraNetDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        JxCameraCore.shared.setCameraNetDelegate(self)
    }
    
    // 网络状态变化回调
    func net(_ network: JxNetwork, statusChanged interface: ManagedInterface?, interfaces: [ManagedInterface]) {
        print("网络状态变化: \(interface?.description ?? "无")")
        print("所有接口: \(interfaces)")
    }
    
    // WiFi 信息获取回调
    func net(_ network: JxNetwork, didFetchWifi interface: ManagedInterface) {
        print("WiFi SSID: \(interface.ssid ?? "未知")")
        print("IP 地址: \(interface.ipAddress ?? "未知")")
    }
    
    // 相机 WiFi 连接成功
    func net(_ network: JxNetwork, cameraWifiConnected interface: ManagedInterface) {
        print("已连接到相机 WiFi")
    }
    
    // 相机 WiFi 断开连接
    func netDidDisconnectCameraWifi(_ core: JxNetwork) {
        print("相机 WiFi 已断开")
    }
}
```

#### 手动刷新 WiFi 信息

```swift
JxCameraCore.shared.fetchNetInfo()
```

---

### 3. 蓝牙管理

SDK 支持通过蓝牙扫描、连接相机设备，并发送控制指令。

#### 设置蓝牙代理

```swift
class MyViewController: UIViewController, JxCameraBleDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        JxCameraCore.shared.setCameraBleDelegate(self)
    }
    
    // 发现蓝牙设备
    func ble(_ ble: JxBle, didDiscoverDevice device: BleDevice) {
        print("发现设备: \(device.name), RSSI: \(device.rssi)")
    }
    
    // 设备连接成功
    func ble(_ ble: JxBle, didConnectDevice device: BleDevice) {
        print("设备连接成功: \(device.name)")
    }
    
    // 设备断开连接
    func ble(_ ble: JxBle, didDisconnectDevice device: BleDevice) {
        print("设备断开连接: \(device.name)")
    }
    
    // 设备连接失败
    func ble(_ ble: JxBle, didFailToConnect device: BleDevice) {
        print("设备连接失败: \(device.name)")
    }
}
```

#### 扫描蓝牙设备

```swift
// 开始扫描
JxCameraCore.shared.startScan()

// 停止扫描
JxCameraCore.shared.stopScan()
```

#### 连接/断开蓝牙设备

```swift
// 连接设备
JxCameraCore.shared.ble()?.connect(device)

// 断开设备
JxCameraCore.shared.ble()?.disconnect(device)
```

#### 发送蓝牙指令

```swift
// 打开相机 WiFi
JxCameraCore.shared.ble()?.execDeviceWiFi(device, command: "0A")

// 关闭相机 WiFi
JxCameraCore.shared.ble()?.execDeviceWiFi(device, command: "09")
```

---

### 4. 相机连接

#### 方式一：使用回调

```swift
JxCameraCore.shared.connectCamera(timeout: 8) { result in
    switch result {
    case .success:
        print("相机连接成功")
    case .failure(let error):
        print("连接失败: \(error)")
    }
}
```

#### 方式二：使用 async/await

```swift
Task {
    do {
        try await JxCameraCore.shared.connectCamera()
        print("相机连接成功")
    } catch {
        print("连接失败: \(error)")
    }
}
```

#### 断开连接

```swift
JxCameraCore.shared.closeCamera()
```

#### 监听连接状态

```swift
class MyViewController: UIViewController, JxCameraCoreDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        JxCameraCore.shared.setCameraDelegate(self)
    }
    
    // 相机连接状态变化
    func camera(_ core: JxCameraCore, didChangeConnectionState state: JxCameraCore.CameraConnectionState) {
        switch state {
        case .idle:
            print("空闲状态")
        case .wifiUnavailable:
            print("WiFi 不可用")
        case .handshaking:
            print("握手中...")
        case .socketConnecting:
            print("Socket 连接中...")
        case .connected:
            print("已连接")
        case .disconnecting:
            print("断开连接中...")
        case .failed(let error):
            print("连接失败: \(error)")
        }
    }
    
    // 接收 Socket 消息
    func camera(_ core: JxCameraCore, didReceiveSocketMessage message: String) {
        print("收到消息: \(message)")
    }
    
    // WiFi 可用性变化
    func camera(_ core: JxCameraCore, wifiAvailabilityChanged available: Bool) {
        print("WiFi 可用: \(available)")
    }
}
```

---

### 5. HTTP 请求

SDK 提供丰富的 HTTP API 接口用于控制相机和获取数据。

#### 获取请求对象

```swift
// 使用默认配置
let request = JxCameraCore.shared.request()

// 使用自定义超时配置
let config = HttpConfig(connectTimeout: 10, readTimeout: 20)
let request = JxCameraCore.shared.request(config: config)
```

#### 常用 API

##### 获取相机信息

```swift
JxCameraCore.shared.request().fetchMiscInfo { (result: Result<MiscInfo, Error>) in
    switch result {
    case .success(let info):
        print("协议版本: \(info.protocolVer)")
    case .failure(let error):
        print("请求失败: \(error)")
    }
}
```

##### 发送心跳

```swift
JxCameraCore.shared.request().sendAliveAck { (result: Result<HttpResult, Error>) in
    switch result {
    case .success(let response):
        print("心跳响应: \(response.result)")
    case .failure(let error):
        print("心跳失败: \(error)")
    }
}
```

##### 切换工作模式

```swift
// 切换到存储模式
JxCameraCore.shared.request().changeMode(to: "Storage") { (result: Result<HttpResult, Error>) in
    switch result {
    case .success(let response):
        if response.result == 0 {
            print("切换成功")
        }
    case .failure(let error):
        print("切换失败: \(error)")
    }
}
```

##### 获取文件列表

```swift
// 获取第 1 页文件，所有类型
JxCameraCore.shared.request().fetchFiles(page: 1, type: -1) { (result: Result<FilePage, Error>) in
    switch result {
    case .success(let filePage):
        print("总页数: \(filePage.pageTotal)")
        print("文件列表: \(filePage.files)")
    case .failure(let error):
        print("获取失败: \(error)")
    }
}
```

##### 删除文件

```swift
JxCameraCore.shared.request().deleteFile(withId: "12345") { (result: Result<HttpResult, Error>) in
    switch result {
    case .success:
        print("删除成功")
    case .failure(let error):
        print("删除失败: \(error)")
    }
}
```

##### 设置参数

```swift
// 方式一：使用回调
JxCameraCore.shared.request().setCommandValue(
    command: "Setup?",
    value: "Shutter=2"
) { (result: Result<HttpResult, Error>) in
    switch result {
    case .success:
        print("设置成功")
    case .failure(let error):
        print("设置失败: \(error)")
    }
}

// 方式二：使用 async/await
Task {
    do {
        let result: HttpResult = try await JxCameraCore.shared.request().setCommandValue(
            command: "Setup?",
            value: "Shutter=2"
        )
        print("设置成功: \(result)")
    } catch {
        print("设置失败: \(error)")
    }
}
```

##### 获取电池状态

```swift
JxCameraCore.shared.request().fetchBatteryStatus { (result: Result<BatteryStatus, Error>) in
    switch result {
    case .success(let status):
        print("电量: \(status.level)%")
    case .failure(let error):
        print("获取失败: \(error)")
    }
}
```

##### 获取当前工作模式

```swift
JxCameraCore.shared.request().fetchCurrentWorkMode { (result: Result<WorkMode, Error>) in
    switch result {
    case .success(let mode):
        print("当前模式: \(mode.mode)")
    case .failure(let error):
        print("获取失败: \(error)")
    }
}
```

##### 更新相机时间

```swift
let currentDate = Date()
JxCameraCore.shared.request().updateDateTime(at: currentDate) { (result: Result<HttpResult, Error>) in
    switch result {
    case .success:
        print("时间更新成功")
    case .failure(let error):
        print("时间更新失败: \(error)")
    }
}
```

##### 获取菜单和字典

```swift
// 获取菜单 JSON
JxCameraCore.shared.request().fetchMenuJson { (result: Result<[String: Any], Error>) in
    switch result {
    case .success(let json):
        print("菜单: \(json)")
    case .failure(let error):
        print("获取失败: \(error)")
    }
}

// 获取字典 JSON
JxCameraCore.shared.request().fetchDictionaryJson { (result: Result<[String: Any], Error>) in
    switch result {
    case .success(let json):
        print("字典: \(json)")
    case .failure(let error):
        print("获取失败: \(error)")
    }
}

// 获取所有设置列表
JxCameraCore.shared.request().fetchAllSettings { (result: Result<[String: Any], Error>) in
    switch result {
    case .success(let settings):
        print("所有设置: \(settings)")
    case .failure(let error):
        print("获取失败: \(error)")
    }
}
```

##### 手动对焦

```swift
// 设置对焦点
JxCameraCore.shared.request().setManualFocus(
    to: 1,
    x: 100,
    y: 200
) { (result: Result<HttpResult, Error>) in
    switch result {
    case .success:
        print("对焦成功")
    case .failure(let error):
        print("对焦失败: \(error)")
    }
}
```

---

### 6. Socket 通信

SDK 内部自动管理 Socket 连接，用于接收相机的实时消息推送。

#### 设置 Socket 代理

```swift
class MyViewController: UIViewController, JxCameraSocketDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        JxCameraCore.shared.setCameraSocketDelegate(self)
    }
    
    // Socket 连接成功
    func socketDidConnect(_ socket: JxSocket) {
        print("Socket 连接成功")
    }
    
    // Socket 断开连接
    func socket(_ socket: JxSocket, didDisconnectWith error: Error?) {
        if let error = error {
            print("Socket 断开: \(error)")
        } else {
            print("Socket 正常断开")
        }
    }
    
    // 接收消息
    func socket(_ socket: JxSocket, didReceiveMessage message: String) {
        print("收到消息: \(message)")
    }
    
    // Socket 状态变化
    func socket(_ socket: JxSocket, didChangeState state: SocketState) {
        print("Socket 状态: \(state)")
    }
    
    // 心跳超时
    func socketHeartbeatTimeout(_ socket: JxSocket, missCount: Int) {
        print("心跳超时，错过次数: \(missCount)")
    }
}
```

---

### 7. 自定义 HTTP 客户端

SDK 支持注入自定义的 HTTP 客户端实现，例如使用 Alamofire。

#### 实现 JxHttpClient 协议

```swift
import Alamofire
import JxCameraSDK

final class AlamofireHttpClient: JxHttpClient {
    private let session: Session
    
    init(
        connectTimeout: TimeInterval = 30,
        readTimeout: TimeInterval = 30,
        sslConfig: JxSSLConfiguration?,
        host: String
    ) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = readTimeout
        configuration.timeoutIntervalForResource = connectTimeout
        
        // 配置 SSL 证书固定
        if let sslConfig = sslConfig, sslConfig.isEnabled {
            var evaluators: [String: ServerTrustEvaluating] = [:]
            
            let certificates = sslConfig.pinnedCertificates.compactMap {
                SecCertificateCreateWithData(nil, $0 as CFData)
            }
            
            evaluators[host] = PinnedCertificatesTrustEvaluator(
                certificates: certificates,
                acceptSelfSignedCertificates: sslConfig.allowSelfSigned,
                performDefaultValidation: false,
                validateHost: sslConfig.validateHost
            )
            
            let trustManager = ServerTrustManager(
                allHostsMustBeEvaluated: false,
                evaluators: evaluators
            )
            
            self.session = Session(
                configuration: configuration,
                serverTrustManager: trustManager
            )
        } else {
            self.session = Session(configuration: configuration)
        }
    }
    
    func request(
        url: URL,
        method: JxHttpMethod,
        headers: [String: String]?,
        body: Data?,
        timeout: TimeInterval?,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let afMethod: HTTPMethod = method == .get ? .get : .post
        var afHeaders: HTTPHeaders?
        if let headers = headers {
            afHeaders = HTTPHeaders(headers)
        }
        
        session.request(
            url,
            method: afMethod,
            parameters: nil,
            encoding: URLEncoding.default,
            headers: afHeaders
        ).responseData { response in
            switch response.result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
```

#### 使用自定义客户端

```swift
let client = AlamofireHttpClient(
    connectTimeout: 8,
    readTimeout: 15,
    sslConfig: JxCameraCore.shared.getSSLConfig(),
    host: "192.168.1.1"
)

JxCameraCore.shared.setHttpClient(client)
```

---

## 完整示例

以下是一个完整的相机连接和控制流程：

```swift
import UIKit
import JxCameraSDK

class CameraViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. 初始化 SDK
        initializeSDK()
        
        // 2. 设置代理
        setupDelegates()
        
        // 3. 开始监控
        JxCameraCore.shared.startMonitoring()
    }
    
    func initializeSDK() {
        let config = SDKConfig(
            logLevel: .info,
            connectTimeout: 8,
            readTimeout: 15,
            autoReconnect: true
        )
        JxCameraCore.shared.initialize(context: UIApplication.shared, config: config)
        JxCameraCore.shared.setUseSSL(true)
    }
    
    func setupDelegates() {
        JxCameraCore.shared.setCameraDelegate(self)
        JxCameraCore.shared.setCameraNetDelegate(self)
        JxCameraCore.shared.setCameraBleDelegate(self)
        JxCameraCore.shared.setCameraSocketDelegate(self)
    }
    
    // 连接相机
    func connectToCamera() {
        // 设置自定义 HTTP 客户端
        let client = AlamofireHttpClient(
            connectTimeout: 8,
            readTimeout: 15,
            sslConfig: JxCameraCore.shared.getSSLConfig(),
            host: "192.168.1.1"
        )
        JxCameraCore.shared.setHttpClient(client)
        
        // 连接相机
        JxCameraCore.shared.connectCamera(timeout: 8) { result in
            switch result {
            case .success:
                print("相机连接成功")
                self.getCameraInfo()
            case .failure(let error):
                print("连接失败: \(error)")
            }
        }
    }
    
    // 获取相机信息
    func getCameraInfo() {
        JxCameraCore.shared.request().fetchMiscInfo { (result: Result<MiscInfo, Error>) in
            switch result {
            case .success(let info):
                print("相机信息: \(info)")
                self.getFileList()
            case .failure(let error):
                print("获取失败: \(error)")
            }
        }
    }
    
    // 获取文件列表
    func getFileList() {
        // 切换到存储模式
        JxCameraCore.shared.request().changeMode(to: "Storage") { (result: Result<HttpResult, Error>) in
            switch result {
            case .success(let response):
                if response.result == 0 {
                    // 获取文件列表
                    JxCameraCore.shared.request().fetchFiles(page: 1, type: -1) { (result: Result<FilePage, Error>) in
                        switch result {
                        case .success(let filePage):
                            print("文件总数: \(filePage.files.count)")
                        case .failure(let error):
                            print("获取失败: \(error)")
                        }
                    }
                }
            case .failure(let error):
                print("切换模式失败: \(error)")
            }
        }
    }
    
    deinit {
        JxCameraCore.shared.stopMonitoring()
        JxCameraCore.shared.closeCamera()
    }
}

// MARK: - JxCameraCoreDelegate

extension CameraViewController: JxCameraCoreDelegate {
    func camera(_ core: JxCameraCore, didChangeConnectionState state: JxCameraCore.CameraConnectionState) {
        switch state {
        case .connected:
            print("已连接到相机")
        case .failed(let error):
            print("连接失败: \(error)")
        default:
            break
        }
    }
    
    func camera(_ core: JxCameraCore, didReceiveSocketMessage message: String) {
        print("收到消息: \(message)")
    }
    
    func camera(_ core: JxCameraCore, wifiAvailabilityChanged available: Bool) {
        print("WiFi 可用: \(available)")
    }
}

// MARK: - JxCameraNetDelegate

extension CameraViewController: JxCameraNetDelegate {
    func net(_ network: JxNetwork, statusChanged interface: ManagedInterface?, interfaces: [ManagedInterface]) {
        print("网络状态变化")
    }
    
    func net(_ network: JxNetwork, didFetchWifi interface: ManagedInterface) {
        print("WiFi SSID: \(interface.ssid ?? "未知")")
    }
    
    func net(_ network: JxNetwork, cameraWifiConnected interface: ManagedInterface) {
        print("已连接到相机热点")
    }
    
    func netDidDisconnectCameraWifi(_ core: JxNetwork) {
        print("相机热点已断开")
    }
}

// MARK: - JxCameraBleDelegate

extension CameraViewController: JxCameraBleDelegate {
    func ble(_ ble: JxBle, didDiscoverDevice device: BleDevice) {
        print("发现设备: \(device.name)")
    }
    
    func ble(_ ble: JxBle, didConnectDevice device: BleDevice) {
        print("设备已连接: \(device.name)")
    }
    
    func ble(_ ble: JxBle, didDisconnectDevice device: BleDevice) {
        print("设备已断开: \(device.name)")
    }
    
    func ble(_ ble: JxBle, didFailToConnect device: BleDevice) {
        print("设备连接失败: \(device.name)")
    }
}

// MARK: - JxCameraSocketDelegate

extension CameraViewController: JxCameraSocketDelegate {
    func socketDidConnect(_ socket: JxSocket) {
        print("Socket 连接成功")
    }
    
    func socket(_ socket: JxSocket, didDisconnectWith error: Error?) {
        print("Socket 断开连接")
    }
    
    func socket(_ socket: JxSocket, didReceiveMessage message: String) {
        print("Socket 消息: \(message)")
    }
    
    func socket(_ socket: JxSocket, didChangeState state: SocketState) {
        print("Socket 状态: \(state)")
    }
    
    func socketHeartbeatTimeout(_ socket: JxSocket, missCount: Int) {
        print("心跳超时")
    }
}
```

---

## API 参考

### JxCameraCore

#### 初始化方法

| 方法 | 说明 |
|------|------|
| `initialize(context:config:)` | 初始化 SDK |
| `startMonitoring()` | 开始网络监控 |
| `stopMonitoring()` | 停止网络监控 |

#### 连接方法

| 方法 | 说明 |
|------|------|
| `connectCamera(timeout:completion:)` | 连接相机（回调） |
| `connectCamera() async throws` | 连接相机（async/await） |
| `closeCamera()` | 断开相机连接 |

#### 蓝牙方法

| 方法 | 说明 |
|------|------|
| `startScan()` | 开始扫描蓝牙设备 |
| `stopScan()` | 停止扫描蓝牙设备 |
| `ble()` | 获取蓝牙管理器 |

#### HTTP 客户端

| 方法 | 说明 |
|------|------|
| `setHttpClient(_:)` | 设置自定义 HTTP 客户端 |
| `request()` | 获取请求对象（默认配置） |
| `request(config:)` | 获取请求对象（自定义配置） |

#### 代理设置

| 方法 | 说明 |
|------|------|
| `setCameraDelegate(_:)` | 设置相机核心代理 |
| `setCameraNetDelegate(_:)` | 设置网络代理 |
| `setCameraBleDelegate(_:)` | 设置蓝牙代理 |
| `setCameraSocketDelegate(_:)` | 设置 Socket 代理 |

### JxRequest

#### 系统信息

| 方法 | 说明 |
|------|------|
| `fetchMiscInfo(timeout:completion:)` | 获取相机信息 |
| `fetchBatteryStatus(completion:)` | 获取电池状态 |
| `fetchCurrentWorkMode(completion:)` | 获取当前工作模式 |
| `sendAliveAck(completion:)` | 发送心跳 |

#### 模式切换

| 方法 | 说明 |
|------|------|
| `changeMode(to:completion:)` | 切换工作模式 |

#### 文件管理

| 方法 | 说明 |
|------|------|
| `fetchFiles(page:type:completion:)` | 获取文件列表 |
| `deleteFile(withId:completion:)` | 删除文件 |

#### 设置管理

| 方法 | 说明 |
|------|------|
| `setCommandValue(command:value:completion:)` | 设置参数（回调） |
| `setCommandValue(command:value:) async throws` | 设置参数（async/await） |
| `updateDateTime(at:completion:)` | 更新相机时间 |
| `fetchMenuJson(completion:)` | 获取菜单 JSON |
| `fetchDictionaryJson(completion:)` | 获取字典 JSON |
| `fetchAllSettings(completion:)` | 获取所有设置 |

#### 相机控制

| 方法 | 说明 |
|------|------|
| `setManualFocus(to:x:y:step:completion:)` | 手动对焦 |
| `setShutter(to:completion:)` | 设置快门 |
| `fetchRecordingStatus(completion:)` | 获取录制状态 |

### JxBle

#### 设备管理

| 方法 | 说明 |
|------|------|
| `connect(_:)` | 连接蓝牙设备 |
| `disconnect(_:)` | 断开蓝牙设备 |
| `isConnected(_:)` | 检查设备是否已连接 |
| `execDeviceWiFi(_:command:)` | 发送 WiFi 控制指令 |

### JxNetwork

#### 网络管理

| 方法 | 说明 |
|------|------|
| `fetchWifiInfo()` | 手动刷新 WiFi 信息 |

---

## 注意事项

1. **权限配置**：使用蓝牙和 WiFi 功能需要在 `Info.plist` 中添加相应权限：
   ```xml
   <key>NSBluetoothAlwaysUsageDescription</key>
   <string>需要使用蓝牙连接相机设备</string>
   <key>NSBluetoothPeripheralUsageDescription</key>
   <string>需要使用蓝牙连接相机设备</string>
   <key>NSLocalNetworkUsageDescription</key>
   <string>需要访问本地网络连接相机</string>
   ```

2. **网络环境**：确保设备已连接到相机的 WiFi 热点，IP 地址通常在 `192.168.1.x` 段。

3. **SSL 证书**：使用 SSL 连接时，需要将证书文件（如 `my_cert.cer`）添加到项目中。

4. **自动重连**：SDK 支持自动重连功能，可在配置中设置重连策略。

5. **线程安全**：所有回调默认在主线程执行，可直接更新 UI。

---

## 更新日志

### v1.0.0
- 初始版本发布
- 支持 WiFi 和蓝牙连接
- 提供完整的相机控制 API
- 支持 SSL 连接
- 支持自定义 HTTP 客户端

---

## 许可证

请参阅 [LICENSE](LICENSE) 文件。

---

## 技术支持

如有问题或建议，请联系开发团队。
