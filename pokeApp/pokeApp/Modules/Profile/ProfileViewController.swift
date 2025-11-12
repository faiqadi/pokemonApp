// © 2025 Prodia. All rights reserved.

import UIKit
import RxSwift
import RxCocoa

final class ProfileViewController: UIViewController {
    private let viewModel: ProfileViewModel
    private let disposeBag = DisposeBag()

    private let stackView = UIStackView()
    private let nameTitleLabel = UILabel()
    private let nameValueLabel = UILabel()
    private let emailTitleLabel = UILabel()
    private let emailValueLabel = UILabel()
    private let logoutButton = UIButton(type: .system)

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { return nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        bindViewModel()
    }

    private func setupViews() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        [nameTitleLabel, nameValueLabel, emailTitleLabel, emailValueLabel].forEach { label in
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .left
        }

        nameTitleLabel.text = "Username"
        nameTitleLabel.font = .preferredFont(forTextStyle: .headline)

        nameValueLabel.font = .preferredFont(forTextStyle: .body)

        emailTitleLabel.text = "Email"
        emailTitleLabel.font = .preferredFont(forTextStyle: .headline)

        emailValueLabel.font = .preferredFont(forTextStyle: .body)

        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.setTitleColor(.systemRed, for: .normal)
        logoutButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)

        let nameStack = UIStackView(arrangedSubviews: [nameTitleLabel, nameValueLabel])
        nameStack.axis = .vertical
        nameStack.spacing = 4

        let emailStack = UIStackView(arrangedSubviews: [emailTitleLabel, emailValueLabel])
        emailStack.axis = .vertical
        emailStack.spacing = 4

        stackView.addArrangedSubview(nameStack)
        stackView.addArrangedSubview(emailStack)
        stackView.addArrangedSubview(UIView()) // spacer
        stackView.addArrangedSubview(logoutButton)

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func bindViewModel() {
        let appearDriver = rx
            .methodInvoked(#selector(UIViewController.viewWillAppear))
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())

        let logoutTap = logoutButton.rx.tap.asDriver()

        let output = viewModel.transform(input: .init(appear: appearDriver, logoutTap: logoutTap))

        output.title
            .drive(rx.title)
            .disposed(by: disposeBag)

        output.username
            .drive(nameValueLabel.rx.text)
            .disposed(by: disposeBag)

        output.email
            .drive(emailValueLabel.rx.text)
            .disposed(by: disposeBag)

        output.logoutCompleted
            .drive(onNext: { [weak self] in
                self?.navigateToLogin()
            })
            .disposed(by: disposeBag)
    }

    private func navigateToLogin() {
        let loginVC = LoginViewController()
        let nav = UINavigationController(rootViewController: loginVC)

        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = nav
            window.makeKeyAndVisible()
        } else {
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
}


