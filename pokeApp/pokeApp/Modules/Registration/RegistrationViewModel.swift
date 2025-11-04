// © 2025 Prodia. All rights reserved.

import Foundation
import RxSwift
import RxCocoa

final class RegistrationViewModel {
    struct Input {
        let name: Driver<String>
        let email: Driver<String>
        let password: Driver<String>
        let registerTap: Driver<Void>
    }

    struct Output {
        let isLoading: Driver<Bool>
        let errorMessage: Driver<String>
        let didRegister: Driver<User>
    }

    private let repository: UserRepository
    private let activity = PublishRelay<Bool>()
    private let errorRelay = PublishRelay<String>()
    private let registerRelay = PublishRelay<User>()
    private let disposeBag = DisposeBag()

    init(repository: UserRepository) {
        self.repository = repository
    }

    func transform(input: Input) -> Output {
        let info = Driver.combineLatest(input.name, input.email, input.password)

        input.registerTap
            .withLatestFrom(info)
            .drive(onNext: { [weak self] name, email, password in
                guard let self = self else { return }
                self.activity.accept(true)
                do {
                    let user = try self.repository.register(name: name, email: email, password: password)
                    self.registerRelay.accept(user)
                } catch let err as LocalizedError {
                    self.errorRelay.accept(err.errorDescription ?? "Terjadi kesalahan")
                } catch {
                    self.errorRelay.accept("Terjadi kesalahan")
                }
                self.activity.accept(false)
            })
            .disposed(by: disposeBag)

        return Output(
            isLoading: activity.asDriver(onErrorJustReturn: false),
            errorMessage: errorRelay.asDriver(onErrorDriveWith: .empty()),
            didRegister: registerRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}


