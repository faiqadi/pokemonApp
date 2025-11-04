// © 2025 Prodia. All rights reserved.

import Foundation
import RxSwift
import RxCocoa

final class LoginViewModel {
    struct Input {
        let email: Driver<String>
        let password: Driver<String>
        let loginTap: Driver<Void>
        let registerTap: Driver<Void>
    }

    struct Output {
        let isLoading: Driver<Bool>
        let errorMessage: Driver<String>
        let didLogin: Driver<User>
        let openRegister: Driver<Void>
    }

    private let repository: UserRepository
    private let activity = ActivityIndicator()
    private let errorRelay = PublishRelay<String>()
    private let loginRelay = PublishRelay<User>()
    private let disposeBag = DisposeBag()

    init(repository: UserRepository) {
        self.repository = repository
    }

    func transform(input: Input) -> Output {
        let credentials = Driver.combineLatest(input.email, input.password)

        input.loginTap
            .withLatestFrom(credentials)
            .flatMapLatest { [weak self] email, password -> Driver<User> in
                guard let self = self else { return Driver.empty() }
                return Single<User>.create { single in
                    do {
                        let user = try self.repository.login(email: email, password: password)
                        single(.success(user))
                    } catch let err as UserRepositoryError {
                        single(.failure(err))
                    } catch {
                        single(.failure(UserRepositoryError.unknown))
                    }
                    return Disposables.create()
                }
                .trackActivity(self.activity)
                .asDriver(onErrorRecover: { [weak self] error in
                    let message = (error as? LocalizedError)?.errorDescription ?? "Terjadi kesalahan"
                    self?.errorRelay.accept(message)
                    return Driver.empty()
                })
            }
            .drive(onNext: { [weak self] user in
                self?.loginRelay.accept(user)
            })
            .disposed(by: disposeBag)

        return Output(
            isLoading: activity.asDriver(),
            errorMessage: errorRelay.asDriver(onErrorDriveWith: .empty()),
            didLogin: loginRelay.asDriver(onErrorDriveWith: .empty()),
            openRegister: input.registerTap
        )
    }
}

// ActivityIndicator implementation with trackActivity operator for Observable and Single
private final class ActivityIndicator: SharedSequenceConvertibleType {
    typealias Element = Bool
    typealias SharingStrategy = DriverSharingStrategy

    private let lock = NSRecursiveLock()
    private let relay = BehaviorRelay(value: 0)
    private let loading: SharedSequence<SharingStrategy, Bool>

    init() {
        loading = relay.asDriver().map { $0 > 0 }.distinctUntilChanged()
    }

    fileprivate func trackActivityOfObservable<O: ObservableConvertibleType>(_ source: O) -> Observable<O.Element> {
        Observable.using({ () -> ActivityToken in
            self.increment()
            return ActivityToken { self.decrement() }
        }, observableFactory: { _ in
            source.asObservable()
        })
    }

    func asSharedSequence() -> SharedSequence<DriverSharingStrategy, Bool> { loading }
    func asDriver() -> Driver<Bool> { loading }

    private func increment() {
        lock.lock(); relay.accept(relay.value + 1); lock.unlock()
    }

    private func decrement() {
        lock.lock(); relay.accept(max(0, relay.value - 1)); lock.unlock()
    }

    private final class ActivityToken: Disposable {
        private let disposeAction: () -> Void
        init(_ dispose: @escaping () -> Void) { disposeAction = dispose }
        func dispose() { disposeAction() }
    }
}

private extension ObservableConvertibleType {
    func trackActivity(_ activityIndicator: ActivityIndicator) -> Observable<Element> {
        activityIndicator.trackActivityOfObservable(self)
    }
}

private extension PrimitiveSequence where Trait == SingleTrait {
    func trackActivity(_ activityIndicator: ActivityIndicator) -> PrimitiveSequence<Trait, Element> {
        asObservable().trackActivity(activityIndicator).asSingle()
    }
}


