// © 2025 faiqadi. All rights reserved.

import UIKit
import RxSwift
import RxCocoa

final class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel
    private let disposeBag = DisposeBag()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let reachedBottomRelay = PublishRelay<Void>()
    private var items: [String] = []

    init(viewModel: HomeViewModel = HomeViewModel()) {
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
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    private func bindViewModel() {
        let appearDriver = rx
            .methodInvoked(#selector(UIViewController.viewWillAppear))
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())

        let output = viewModel.transform(input: .init(
            appear: appearDriver,
            reachedBottom: reachedBottomRelay.asDriver(onErrorDriveWith: .empty())
        ))
        output.title.drive(rx.title).disposed(by: disposeBag)

        output.items
            .drive(onNext: { [weak self] newItems in
                self?.items = newItems
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let title = indexPath.row < items.count ? items[indexPath.row] : ""
        cell.textLabel?.text = title
        cell.selectionStyle = .none
        return cell
    }
}

extension HomeViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        let threshold: CGFloat = 100

        if contentHeight > 0, offsetY + height + threshold >= contentHeight {
            reachedBottomRelay.accept(())
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < items.count else { return }
        let item = items[indexPath.row]
        let vm = DetailViewModel(item: item)
        let vc = DetailViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }
}


