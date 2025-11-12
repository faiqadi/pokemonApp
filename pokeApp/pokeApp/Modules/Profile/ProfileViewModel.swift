// © 2025 faiqadi. All rights reserved.

import Foundation
import RxSwift
import RxCocoa

final class ProfileViewModel {
    private let repository: UserRepository
    private let userRelay = BehaviorRelay<User?>(value: nil)

    struct Input {
        let appear: Driver<Void>
        let logoutTap: Driver<Void>
    }

    struct Output {
        let title: Driver<String>
        let username: Driver<String>
        let email: Driver<String>
        let logoutCompleted: Driver<Void>
    }

    init(repository: UserRepository = SQLiteUserRepository()) {
        self.repository = repository
    }

    func transform(input: Input) -> Output {
        _ = input.appear
            .drive(onNext: { [weak self] _ in
                self?.loadCurrentUser()
            })

        let title = input.appear.map { _ in "Profile" }

        let username = userRelay
            .asDriver()
            .map { $0?.name ?? "-" }

        let email = userRelay
            .asDriver()
            .map { $0?.email ?? "-" }

        let logoutCompleted = input.logoutTap
            .do(onNext: { [weak self] in
                self?.repository.logout()
            })
            .map { _ in () }

        return Output(
            title: title,
            username: username,
            email: email,
            logoutCompleted: logoutCompleted
        )
    }

    private func loadCurrentUser() {
        let user = repository.getCurrentUser()
        userRelay.accept(user)
    }
}


