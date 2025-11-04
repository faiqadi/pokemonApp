// © 2025 faiqadi. All rights reserved.

import Foundation
import RxSwift
import RxCocoa

final class HomeViewModel {
    struct Input {
        let appear: Driver<Void>
        let reachedBottom: Driver<Void>
    }

    struct Output {
        let title: Driver<String>
        let items: Driver<[String]>
    }

    func transform(input: Input) -> Output {
        let title = input.appear.map { _ in "Home" }

        let itemsRelay = BehaviorRelay<[String]>(value: [])

        // Load initial items on appear
        _ = input.appear.drive(onNext: { _ in
            if itemsRelay.value.isEmpty {
                let initial = Self.generateItems(start: 0, count: 10)
                itemsRelay.accept(initial)
            }
        })

        // Load more when reached bottom
        _ = input.reachedBottom.drive(onNext: { _ in
            let current = itemsRelay.value
            let nextStart = current.count
            let more = Self.generateItems(start: nextStart, count: 10)
            itemsRelay.accept(current + more)
        })

        return Output(
            title: title,
            items: itemsRelay.asDriver()
        )
    }

    private static func generateItems(start: Int, count: Int) -> [String] {
        guard count > 0 else { return [] }
        let endExclusive = start + count
        return (start..<endExclusive).map { index in
            "Item \(index + 1)"
        }
    }
}


