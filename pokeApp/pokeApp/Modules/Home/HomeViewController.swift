// © 2025 faiqadi. All rights reserved.

import UIKit
import RxSwift
import RxCocoa
import MBProgressHUD

final class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel
    private let disposeBag = DisposeBag()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let reachedBottomRelay = PublishRelay<Void>()
    private var items: [Pokemon] = []

    // Keep a minimum row height just in case (very small screens / Split View)
    private let minRowHeight: CGFloat = 44
    // How many rows should fit on screen at once
    private let rowsOnScreen: CGFloat = 10

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

        // We’ll drive height via delegate; disable automatic dimension for predictability.
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 0
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

        output.title
            .drive(rx.title)
            .disposed(by: disposeBag)

        output.items
            .drive(onNext: { [weak self] newItems in
                self?.items = newItems
                self?.tableView.reloadData()
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

    // Recalculate on rotation / split view changes
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        tableView.reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        })
    }

    /// Computes a row height so that exactly `rowsOnScreen` rows fit the safe-area height.
    private func computedRowHeight() -> CGFloat {
        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        let available = max(0, view.bounds.height - safeTop - safeBottom)
        return max(minRowHeight, floor(available / rowsOnScreen))
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if indexPath.row < items.count {
            cell.textLabel?.text = items[indexPath.row].displayName
        } else {
            cell.textLabel?.text = ""
        }
        cell.selectionStyle = .none
        return cell
    }
}

extension HomeViewController: UITableViewDelegate {
    // Force a height so 10 rows fit on screen across devices/orientations.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        computedRowHeight()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        let threshold: CGFloat = 100
        
        // Keep your "load more when nearing bottom" behavior.
        if contentHeight > 0, offsetY + height + threshold >= contentHeight {
            reachedBottomRelay.accept(())
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < items.count else { return }
        let item = items[indexPath.row]
        let vm = DetailViewModel(pokemon: item)
        let vc = DetailViewController(viewModel: vm)
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(vc, animated: true)
    }
}


