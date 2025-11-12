// © 2025 faiqadi. All rights reserved.

import UIKit
import XLPagerTabStrip

final class MainTabBarController: ButtonBarPagerTabStripViewController {
    private let buttonBarTopSpacing: CGFloat = 12

    init() {
        super.init(nibName: nil, bundle: nil)
        configureButtonBarAppearance()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buttonBarView.backgroundColor = .clear
        buttonBarView.selectedBar.backgroundColor = settings.style.selectedBarBackgroundColor
        buttonBarView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        buttonBarView.backgroundColor = .lightGray
        containerView.backgroundColor = .systemBackground
        self.view.backgroundColor = .white
        updateButtonBarLayout()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateButtonBarLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateButtonBarLayout()
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let homeVM = HomeViewModel()
        let homeVC = HomeViewController(viewModel: homeVM)
//        homeVC.navigationItem.largeTitleDisplayMode = .never

        let profileVM = ProfileViewModel()
        let profileVC = ProfileViewController(viewModel: profileVM)
//        profileVC.navigationItem.largeTitleDisplayMode = .never

        let homeNav = PagerNavigationController(rootViewController: homeVC, pagerTitle: "Home")
        let profileNav = PagerNavigationController(rootViewController: profileVC, pagerTitle: "Profile")

        [homeNav, profileNav].forEach { nav in
            nav.navigationBar.prefersLargeTitles = false
        }

        return [homeNav, profileNav]
    }

    private func configureButtonBarAppearance() {
        settings.style.buttonBarBackgroundColor = .systemBackground
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.buttonBarItemTitleColor = .label
        settings.style.buttonBarItemFont = .preferredFont(forTextStyle: .headline)
        settings.style.selectedBarBackgroundColor = .systemBlue
        settings.style.selectedBarHeight = 3
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarMinimumInteritemSpacing = 0
        settings.style.buttonBarItemsShouldFillAvailableWidth = true
    }

    private func updateButtonBarLayout() {
        guard view.bounds.height > 0 else { return }
        let safeTop = view.safeAreaInsets.top
        let desiredY = safeTop + buttonBarTopSpacing
        var barFrame = buttonBarView.frame

        if abs(barFrame.origin.y - desiredY) > .ulpOfOne {
            let originalHeight = barFrame.size.height
            barFrame.origin.y = desiredY
            buttonBarView.frame = barFrame

            var containerFrame = containerView.frame
            containerFrame.origin.y = barFrame.maxY
            containerFrame.size.height = max(0, view.bounds.height - containerFrame.origin.y)
            containerView.frame = containerFrame

            buttonBarView.setNeedsLayout()
            buttonBarView.layoutIfNeeded()

            if originalHeight != barFrame.size.height {
                containerView.setNeedsLayout()
                containerView.layoutIfNeeded()
            }
        }
    }
}

private final class PagerNavigationController: UINavigationController, IndicatorInfoProvider {
    private let pagerTitle: String

    init(rootViewController: UIViewController, pagerTitle: String) {
        self.pagerTitle = pagerTitle
        super.init(rootViewController: rootViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        IndicatorInfo(title: pagerTitle)
    }
}

