// © 2025 faiqadi. All rights reserved.

import Foundation
import RxSwift
import RxCocoa

final class DetailViewModel {
    struct Input {}

    struct Output {
        let title: Driver<String>
        let itemText: Driver<String>
    }

    private let item: String

    init(item: String) {
        self.item = item
    }

    func transform(input: Input) -> Output {
        let title = Driver.just("Detail")
        let itemText = Driver.just(item)
        return Output(title: title, itemText: itemText)
    }
}


