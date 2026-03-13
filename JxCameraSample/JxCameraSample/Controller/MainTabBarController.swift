import Masonry
import UIKit

class MainTabBarController: UIViewController {
    private let contentView = UIView()
    private var buttons: [UIButton] = []
    private var controllers: [(controller: UIViewController, title: String, icon: String, iconSelected: String)] = []
    private var selectedIndex = 0
    private var contentViewBottomConstraint: MASConstraint?

    private let tabBarView: UIView = {
        let tabBarView = UIView()
        tabBarView.backgroundColor = .white
        tabBarView.layer.shadowColor = UIColor.black.cgColor
        tabBarView.layer.shadowOpacity = 0.1
        tabBarView.layer.shadowOffset = CGSize(width: 0, height: -1)
        return tabBarView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        // setupViewControllers()
        // switchTo(index: 0)

        if let nav = navigationController {
            nav.delegate = self
        }
    }

    private func setupView() {
        view.addSubview(contentView)
        view.addSubview(tabBarView)

        contentView.mas_makeConstraints { make in
            make?.top.left().right().equalTo()(view)
            if #available(iOS 11.0, *) {
                contentViewBottomConstraint = make?.bottom.equalTo()(view.mas_safeAreaLayoutGuideBottom)
            }else{
                contentViewBottomConstraint = make?.bottom.equalTo()(view.mas_bottom)
            }
        }
        tabBarView.mas_makeConstraints { make in
            if #available(iOS 11.0, *) {
                make?.bottom.equalTo()(self.view.mas_safeAreaLayoutGuideBottom)
                make?.left.equalTo()(self.view.mas_safeAreaLayoutGuideLeft)
                make?.right.equalTo()(self.view.mas_safeAreaLayoutGuideRight)
            } else {
                make?.left.right().bottom().equalTo()(view)
            }
            make?.height.mas_equalTo()(60)
        }
    }

    private func setupViewControllers() {
        for (index, item) in controllers.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(item.title, for: .normal)
            button.setTitleColor(.gray, for: .normal)
            button.setTitleColor(.black, for: .selected)
            button.titleLabel?.font = .systemFont(ofSize: 10)
            button.tag = index

            if let image = UIImage(named: item.icon)?.resize(to: CGSize(width: 26, height: 26)) {
                button.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
            }

            if let image = UIImage(named: item.iconSelected)?.resize(to: CGSize(width: 26, height: 26)) {
                button.setImage(image.withRenderingMode(.alwaysOriginal), for: .selected)
            }

            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            tabBarView.addSubview(button)
            buttons.append(button)
        }

        layoutTabBarButtons()
    }

    func setViewControllers(_ items: [(UIViewController, String, String, String)]) {
        controllers = items.map { vc, title, icon, iconSelected in
            // 包一层 navigationController 的时候设置代理
            if let nav = vc as? UINavigationController {
                nav.delegate = self
            }
            return (controller: vc, title: title, icon: icon, iconSelected: iconSelected)
        }
        setupViewControllers()
        tabTapped(buttons[0])
    }

    private func layoutTabBarButtons() {
        let buttonWidth = UIScreen.main.bounds.width / CGFloat(buttons.count)
        for (index, button) in buttons.enumerated() {
            button.mas_makeConstraints { make in
                make?.top.bottom().equalTo()(tabBarView)
                make?.width.mas_equalTo()(buttonWidth)
                make?.left.mas_equalTo()(CGFloat(index) * buttonWidth)
            }
            button.centerImageAndTitle(spacing: 4)
        }
    }

    @objc private func tabTapped(_ sender: UIButton) {
        print("[MainTabBarController] tabTapped: \(tabSwitchEnabled)")
        guard tabSwitchEnabled else { return }

        switchTo(index: sender.tag)
        for (i, btn) in buttons.enumerated() {
            btn.isSelected = (i == sender.tag)
        }
    }

    func switchToIndex(index: Int) {
        switchTo(index: index)
        for (i, btn) in buttons.enumerated() {
            btn.isSelected = (i == index)
        }
    }

    private func switchTo(index: Int) {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        let vc = controllers[index].controller
        addChild(vc)
        contentView.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.mas_makeConstraints { make in
            make?.edges.equalTo()(contentView)
        }
        vc.didMove(toParent: self)

        selectedIndex = index
    }

    func hideTabBar(_ hidden: Bool) {
        tabBarView.isHidden = hidden
        contentViewBottomConstraint?.mas_equalTo()(hidden ? 0 : -60)
        view.layoutIfNeeded() // 👈 强制立即布局
    }

    func getSelectController() -> UIViewController? {
        return controllers[selectedIndex].controller
    }
    
    /// 是否允许切换 Tab（拍照/录影中 = false）
    var tabSwitchEnabled: Bool = true {
        didSet {
            DispatchQueue.main.async {
                self.updateTabBarUI()
            }
        }
    }
    
    private func updateTabBarUI() {
        print("[MainTabBarController] updateTabBarUI: \(tabSwitchEnabled)")
        buttons.forEach { btn in
            print("[MainTabBarController] updateTabBarUI: \(btn.titleLabel?.text)")
            btn.isEnabled = tabSwitchEnabled
            btn.alpha = tabSwitchEnabled ? 1.0 : 0.7
        }
    }
}

// MARK: - UIButton扩展：图标上、文字下

extension UIButton {
    func centerImageAndTitle(spacing: CGFloat) {
        // 强制布局，确保 imageView 和 titleLabel 有尺寸
        layoutIfNeeded()

        guard let imageSize = imageView?.intrinsicContentSize,
              let titleSize = titleLabel?.intrinsicContentSize
        else {
            return
        }

        let totalHeight = imageSize.height + spacing + titleSize.height

        imageEdgeInsets = UIEdgeInsets(
            top: -(totalHeight - imageSize.height),
            left: 0,
            bottom: 0,
            right: -titleSize.width
        )

        titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -imageSize.width,
            bottom: -(totalHeight - titleSize.height),
            right: 0
        )

        contentEdgeInsets = UIEdgeInsets(
            top: (totalHeight - imageSize.height - titleSize.height) / 2,
            left: 0,
            bottom: (totalHeight - imageSize.height - titleSize.height) / 2,
            right: 0
        )
    }
}

extension MainTabBarController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let isRoot = navigationController.viewControllers.first === viewController
        hideTabBar(!isRoot)
    }
}
