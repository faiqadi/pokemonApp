// © 2025 faiqadi. All rights reserved.

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import MBProgressHUD

final class RegistrationViewController: UIViewController {
    private let viewModel: RegistrationViewModel
    private let disposeBag = DisposeBag()

    private let nameField = UITextField()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let registerButton = UIButton(type: .system)

    init(viewModel: RegistrationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Daftar"
    }

    required init?(coder: NSCoder) { return nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        bindViewModel()
    }

    private func setupViews() {
        nameField.placeholder = "Nama"
        nameField.borderStyle = .roundedRect

        emailField.placeholder = "Email"
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.borderStyle = .roundedRect

        passwordField.placeholder = "Password"
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .roundedRect

        registerButton.setTitle("Daftar", for: .normal)
        registerButton.titleLabel?.font = .boldSystemFont(ofSize: 16)

        let stack = UIStackView(arrangedSubviews: [nameField, emailField, passwordField, registerButton])
        stack.axis = .vertical
        stack.spacing = 12
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }

    private func bindViewModel() {
        let input = RegistrationViewModel.Input(
            name: nameField.rx.text.orEmpty.asDriver(),
            email: emailField.rx.text.orEmpty.asDriver(),
            password: passwordField.rx.text.orEmpty.asDriver(),
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

        output.didRegister
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
}


