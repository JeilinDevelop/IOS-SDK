//
//  GalleryCollectionViewCell.swift
//  Polaroid
//
//  Created by jxcs on 2025/1/10.
//

import UIKit
import Masonry
import Kingfisher
import JxCameraSDK

class GalleryCollectionViewCell: UICollectionViewCell {
    
    // 创建 UI 元素
    let thumbImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let selectCheckBox: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "checkbox_normal_ic"), for: .normal)
        button.setImage(UIImage(named: "checkbox_checked_ic"), for: .selected)
        button.isUserInteractionEnabled = false
        button.tintColor = .white
        return button
    }()
    
    let sizeLabel: UILabel = {
        let label = UILabel()
        label.text = "0.00MB"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .center
        // 设置背景颜色，包含半透明效果
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        // 设置圆角
        label.layer.cornerRadius = 2
        label.layer.masksToBounds = true // 让圆角效果生效
        return label
    }()
    
    let synchImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_synch")
        imageView.isHidden = true
        return imageView
    }()
    
    let playImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_play")
        imageView.isHidden = true
        return imageView
    }()
    
    // 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // 设置容器的背景色
        self.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        // 添加子视图
        self.addSubview(thumbImageView)
        self.addSubview(selectCheckBox)
        self.addSubview(sizeLabel)
        self.addSubview(synchImageView)
        self.addSubview(playImageView)
        
        // 使用 Masonry 进行布局
        thumbImageView.mas_makeConstraints { make in
            make?.top.equalTo()(self)
            make?.left.equalTo()(self)
            make?.right.equalTo()(self)
            make?.bottom.equalTo()(self)
        }
        
        selectCheckBox.mas_makeConstraints { make in
            make?.top.equalTo()(self)
            make?.left.equalTo()(self)
            make?.width.equalTo()(30)
            make?.height.equalTo()(30)
        }
        
        sizeLabel.mas_makeConstraints { make in
            make?.right.equalTo()(self)
            make?.bottom.equalTo()(self)
        }
        
        synchImageView.mas_makeConstraints { make in
            make?.top.equalTo()(self)?.offset()(0)
            make?.right.equalTo()(self)?.offset()(0)
            make?.width.equalTo()(30)
            make?.height.equalTo()(30)
        }
        
        playImageView.mas_makeConstraints { make in
            make?.centerX.equalTo()(self)
            make?.centerY.equalTo()(self)
            make?.width.equalTo()(35)
            make?.height.equalTo()(35)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isEditing = false
    
    // 配置 cell 数据
    func configure(with item: FileMeta) {
        let thumbUrl = URL(string: JxCameraCore.shared.getFileThumbUrl(item.fid))
        thumbImageView.kf.setImage(with: thumbUrl, placeholder: UIImage(named: "placeholder"))
        let sizeInMB = Double(item.size) / 1024.0 / 1024.0 // 转换为 MB
        let formattedSize = String(format: "%.2f MB", sizeInMB) // 保留两位小数
        sizeLabel.text = formattedSize
        selectCheckBox.isHidden = !isEditing
        selectCheckBox.isSelected = item.isSelected ?? false
        if let isDownloaded = item.isDownloaded, isDownloaded {
            synchImageView.isHidden = false
        }else{
            synchImageView.isHidden = true
        }
        if let isVideo = item.isVideo, isVideo {
            playImageView.isHidden = false
        }else {
            playImageView.isHidden = true
        }
    }
    
}
