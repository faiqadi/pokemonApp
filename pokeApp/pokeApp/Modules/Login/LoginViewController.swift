// © 2025 faiqadi. All rights reserved.

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import MBProgressHUD

final class LoginViewController: UIViewController {
    private let viewModel: LoginViewModel
    private let disposeBag = DisposeBag()

    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)

    init(viewModel: LoginViewModel = LoginViewModel(repository: SQLiteUserRepository())) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Login"
    }

    required init?(coder: NSCoder) { return nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        bindViewModel()
    }

    private func setupViews() {
        emailField.placeholder = "Email"
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.borderStyle = .roundedRect

        passwordField.placeholder = "Password"
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .roundedRect

        loginButton.setTitle("Masuk", for: .normal)
        loginButton.titleLabel?.font = .boldSystemFont(ofSize: 16)

        registerButton.setTitle("Daftar", for: .normal)

        let stack = UIStackView(arrangedSubviews: [emailField, passwordField, loginButton, registerButton])
        stack.axis = .vertical
        stack.spacing = 12
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }

    private func bindViewModel() {
        let input = LoginViewModel.Input(
            email: emailField.rx.text.orEmpty.asDriver(),
            password: passwordField.rx.text.orEmpty.asDriver(),
            loginTap: loginButton.rx.tap.asDriver(),
            registerTap: registerButton.rx.tap.asDriver()
        )
        let output = viewModel.transform(input: input)

        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                } else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            })
            .disposed(by: disposeBag)

        output.errorMessage
            .drive(onNext: { [weak self] message in
                guard let self = self else { return }
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            })
            .disposed(by: disposeBag)

        output.didLogin
            .drive(onNext: { [weak self] _ in
                self?.showHome()
            })
            .disposed(by: disposeBag)

        output.openRegister
            .drive(onNext: { [weak self] in
                self?.openRegister()
            })
            .disposed(by: disposeBag)
    }

    private func openRegister() {
        let vm = RegistrationViewModel(repository: SQLiteUserRepository())
        let vc = RegistrationViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showHome() {
        let tabBar = MainTabBarController()
        navigationController?.setViewControllers([tabBar], animated: true)
    }
}


