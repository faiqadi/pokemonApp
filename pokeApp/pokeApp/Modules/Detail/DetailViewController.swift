// © 2025 faiqadi. All rights reserved.

import UIKit
import RxSwift
import RxCocoa
import Kingfisher
import MBProgressHUD

final class DetailViewController: UIViewController {
    private let viewModel: DetailViewModel
    private let disposeBag = DisposeBag()

    private let imageView = UIImageView()
    private let label = UILabel()
    private let stackView = UIStackView()
    private let placeholderImage = UIImage(systemName: "photo")

    init(viewModel: DetailViewModel) {
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
        stackView.spacing = 24
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.kf.indicatorType = .activity

        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            imageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    private func bindViewModel() {
        let appearDriver = rx
            .methodInvoked(#selector(UIViewController.viewWillAppear))
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())

        let output = viewModel.transform(input: .init(appear: appearDriver))

        output.title
            .drive(rx.title)
            .disposed(by: disposeBag)

        output.itemText
            .drive(label.rx.text)
            .disposed(by: disposeBag)

        output.imageURL
            .drive(onNext: { [weak self] url in
                guard let self = self else { return }
                if let url = url {
                    self.imageView.kf.setImage(with: url, placeholder: self.placeholderImage)
                } else {
                    self.imageView.image = self.placeholderImage
                }
            })
            .disposed(by: disposeBag)

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
    }
}


