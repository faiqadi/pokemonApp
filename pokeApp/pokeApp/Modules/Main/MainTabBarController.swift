// © 2025 Prodia. All rights reserved.

import UIKit
import XLPagerTabStrip

final class MainTabBarController: ButtonBarPagerTabStripViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        configureButtonBarAppearance()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buttonBarView.backgroundColor = .systemBackground
        buttonBarView.selectedBar.backgroundColor = settings.style.selectedBarBackgroundColor
        buttonBarView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        buttonBarView.backgroundColor = .lightGray
        containerView.backgroundColor = .systemBackground
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let homeVM = HomeViewModel()
        let homeVC = HomeViewController(viewModel: homeVM)
        homeVC.navigationItem.largeTitleDisplayMode = .always

        let profileVM = ProfileViewModel()
        let profileVC = ProfileViewController(viewModel: profileVM)
        profileVC.navigationItem.largeTitleDisplayMode = .always

        let homeNav = PagerNavigationController(rootViewController: homeVC, pagerTitle: "Home")
        let profileNav = PagerNavigationController(rootViewController: profileVC, pagerTitle: "Profile")

        [homeNav, profileNav].forEach { nav in
            nav.navigationBar.prefersLargeTitles = true
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

