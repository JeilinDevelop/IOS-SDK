//
//  GalleryViewController.swift
//  Polaroid
//
//  Created by jxcs on 2025/7/28.
//
import Alamofire
import AVFoundation
import CoreLocation
import FGRoute
import Kingfisher
import Masonry
import MJRefresh
import Network
import Toast_Swift
import UIKit
import JxCameraSDK


class GalleryViewController: UIViewController, CLLocationManagerDelegate, UICollectionViewDataSource, UICollectionViewDelegate,UIGestureRecognizerDelegate {
    // MARK: - UI Elements
    
    // Top Bar
    private let topBarView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let titleView: UILabel = {
        let label = UILabel()
        label.text = "相册"
        label.textColor = UIColor.label // 跟随系统主题
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let galleryBarView: UIView = {
        let view = UIView()
        return view
    }()

    private let galleryView: UIView = {
        let view = UIView()
        return view
    }()

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let width = (UIScreen.screenWidth - 6 - 6) / 3
        layout.itemSize = CGSize(width: width, height: width * 0.85)
        layout.minimumLineSpacing = 3
        layout.minimumInteritemSpacing = 3
            
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        return collectionView
    }()
    
    private let selectView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    private let selectAllCheckBox: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "checkbox_normal_ic")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(named: "checkbox_checked_ic")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.imageView?.tintColor = .black
        button.setTitle("Select", for: .normal)
        button.setTitle("Cancel", for: .selected)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return button
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_delete2"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    // MARK: - Properties

    private var isAppInForeground = false
    private var pageIndex = 0
    private var pageSize = 16
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "相册"
        
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
        
        setupUI()
        setupActions()
        setupGallery()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        isAppInForeground = true
        //        galleryAdapter?.refreshLocalFileNames()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.collectionView.mj_header?.beginRefreshing()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        isAppInForeground = false
    }

    // MARK: - UI Setup

    private var selectViewHeightConstraint: MASConstraint?
    
    private func setupUI() {
        view.backgroundColor = .white

        // Add subviews
        view.addSubview(topBarView)
        topBarView.addSubview(titleView)
        topBarView.addSubview(galleryBarView)

        view.addSubview(galleryView)
        selectView.addSubview(selectAllCheckBox)
        selectView.addSubview(deleteButton)
        galleryView.addSubview(selectView)
        galleryView.addSubview(collectionView)
        
        selectView.isHidden = false

        // Constraints
        topBarView.mas_makeConstraints { make in
            make?.top.equalTo()(view.mas_safeAreaLayoutGuideTop)
            make?.left.right().equalTo()(view)
            make?.height.equalTo()(44)
        }
        
        titleView.mas_makeConstraints { make in
            make?.centerX.centerY().equalTo()(topBarView)
        }

        galleryView.mas_makeConstraints { make in
            make?.top.equalTo()(topBarView.mas_bottom)
            make?.left.right().bottom().equalTo()(view)
        }

        selectView.mas_makeConstraints { make in
            make?.left.right().bottom().equalTo()(galleryView)
            selectViewHeightConstraint = make?.height.equalTo()(0)
        }

        selectAllCheckBox.mas_makeConstraints { make in
            make?.centerY.equalTo()(selectView.mas_centerY)
            make?.left.equalTo()(selectView.mas_left)?.offset()(5)
        }
        selectAllCheckBox.imageView?.mas_makeConstraints { make in
            make?.centerY.equalTo()(selectAllCheckBox.mas_centerY)
            make?.width.height().equalTo()(30)
        }
        deleteButton.mas_makeConstraints { make in
            make?.centerY.equalTo()(selectView.mas_centerY)
            make?.right.equalTo()(selectView.mas_right)?.offset()(-5)
            make?.width.height().equalTo()(25)
        }
        collectionView.mas_makeConstraints { make in
            make?.top.equalTo()(galleryView)
            make?.left.equalTo()(galleryView)?.offset()(3)
            make?.right.equalTo()(galleryView)?.offset()(-3)
            make?.bottom.equalTo()(selectView.mas_top)
        }
    }

    // MARK: - Actions Setup

    private func setupActions() {
        
    }
    
    // MARK: - Gallery Setup

    var data: [FileMeta] = []
    private func setupGallery() {
        collectionView.register(GalleryCollectionViewCell.self, forCellWithReuseIdentifier: "GalleryCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        // 下拉刷新
        collectionView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(refreshData))
        // 上拉加载更多
        collectionView.mj_footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(loadMoreData))
    }
        
    func fetchImageRatios() {
        for (index, item) in data.enumerated() {
            guard let thumbUrl = URL(string: JxCameraCore.shared.getFileThumbUrl(item.fid)) else { return }
            KingfisherManager.shared.retrieveImage(with: thumbUrl) { result in
                switch result {
                case .success(let value):
                    let ratio = value.image.size.height / value.image.size.width
                    Task { @MainActor in
                        self.data[index].imageRatio = Float(ratio)
                        self.collectionView.performBatchUpdates {
                            self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
                        }
                    }
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
            }
        }
    }
        
    // MARK: - Refresh Data

    // 下拉刷新
    @objc private func refreshData() {
        pageIndex = 0
        loadData(isRefresh: true)
        collectionView.mj_footer?.resetNoMoreData()
    }
        
    // 上拉加载更多
    @objc private func loadMoreData() {
        pageIndex += 1
        loadData(isRefresh: false)
    }
    
    // MARK: - Load Data

    private func loadData(isRefresh: Bool) {
        JxCameraCore.shared.request().changeMode(to: "Storage") { (result: Result<HttpResult, any Error>) in
            switch result {
            case .success(let res):
                if res.result == 0 {
                    AppConstants.setModeType("Storage")
                    self.getListData(isRefresh: isRefresh)
                    return
                }else{
                    if isRefresh{
                        self.collectionView.mj_header?.endRefreshing()
                    }else{
                        self.pageIndex -= 1
                        self.collectionView.mj_footer?.endRefreshing()
                    }
                }
            case .failure(let error):
                print("请求失败: \(error.localizedDescription)")
                if isRefresh{
                    self.collectionView.mj_header?.endRefreshing()
                }else{
                    self.pageIndex -= 1
                    self.collectionView.mj_footer?.endRefreshing()
                }
            }
        }
    }
        
    func getListData(isRefresh: Bool) {
        JxCameraCore.shared.request().fetchFiles(page: pageIndex, type: -1) { (result: Result<FilePage, any Error>) in
            switch result {
            case .success(let res):
                let newItems = res.fs
                if isRefresh {
                    self.data = newItems
                    self.collectionView.reloadData()
                    self.collectionView.mj_header?.endRefreshing()
                } else {
                    if newItems.count > 0 {
                        self.data += newItems
                        self.collectionView.reloadData()
                    }
                    if newItems.count < self.pageSize {
                        self.collectionView.mj_footer?.endRefreshingWithNoMoreData()
                    } else {
                        self.collectionView.mj_footer?.endRefreshing()
                    }
                }
            case .failure:
                if isRefresh {
                    self.collectionView.mj_header?.endRefreshing()
                } else {
                    self.pageIndex -= 1
                    self.collectionView.mj_footer?.endRefreshing()
                }
            }
                
            //                    // 加载图片宽高比
            //                    self.fetchImageRatios()
        }
    }
        
    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! GalleryCollectionViewCell
        var item = data[indexPath.item]
        let fileName = "\(item.dt)_\(item.name)"
        item.isVideo = FileUtil.isVideoFile(fileName: fileName)
        cell.isEditing = false
        cell.configure(with: item)
        return cell
    }
        
    // 点击 item 后的操作
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected item at \(indexPath.row)")
        var item = data[indexPath.item]
        
    }
        
    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = data[indexPath.item]
        let width = (collectionView.bounds.width - 6) / 3
            
        if let ratio = item.imageRatio {
            return CGSize(width: width, height: width * CGFloat(ratio))
        } else {
            return CGSize(width: width, height: width * 0.85)
        }
    }
        
    
    
    func shareContent(items: [Any], from viewController: UIViewController) {
        // 3. 创建 UIActivityViewController
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // 4. 设置适配 iPad 的 popoverPresentationController
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }
        // 5. 显示分享界面
        viewController.present(activityVC, animated: true, completion: nil)
    }
        

}
