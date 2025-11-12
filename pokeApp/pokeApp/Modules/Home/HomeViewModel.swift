// © 2025 faiqadi. All rights reserved.

import Foundation
import RxSwift
import RxCocoa

final class HomeViewModel {
    private let pokemonService: PokemonService
    private let itemsPerPage = 10
    
    struct Input {
        let appear: Driver<Void>
        let reachedBottom: Driver<Void>
    }

    struct Output {
        let title: Driver<String>
        let items: Driver<[Pokemon]>
        let isLoading: Driver<Bool>
        let error: Driver<String?>
    }
    
    init(pokemonService: PokemonService = .shared) {
        self.pokemonService = pokemonService
    }

    func transform(input: Input) -> Output {
        let title = input.appear.map { _ in "Pokémon" }
        
        let itemsRelay = BehaviorRelay<[Pokemon]>(value: [])
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let errorRelay = BehaviorRelay<String?>(value: nil)
        let isLoadingMore = BehaviorRelay<Bool>(value: false)

        // Load initial items on appear
        let initialLoad = input.appear
            .filter { itemsRelay.value.isEmpty }
            .flatMapLatest { [weak self] _ -> Driver<Result<PokemonListResponse, Error>> in
                guard let self = self else { return .empty() }
                isLoadingRelay.accept(true)
                errorRelay.accept(nil)
                
                return self.pokemonService
                    .getPokemonList(limit: self.itemsPerPage, offset: 0)
                    .asObservable()
                    .map { .success($0) }
                    .catch { error in .just(.failure(error)) }
                    .asDriver(onErrorDriveWith: .empty())
            }
            .do(onNext: { _ in isLoadingRelay.accept(false) })

        // Load more when reached bottom
        let loadMore = input.reachedBottom
            .filter { !isLoadingRelay.value && !isLoadingMore.value }
            .do(onNext: { _ in isLoadingMore.accept(true) })
            .flatMapLatest { [weak self] _ -> Driver<Result<PokemonListResponse, Error>> in
                guard let self = self else { return .empty() }
                let current = itemsRelay.value
                let offset = current.count
                
                return self.pokemonService
                    .getPokemonList(limit: self.itemsPerPage, offset: offset)
                    .asObservable()
                    .map { .success($0) }
                    .catch { error in .just(.failure(error)) }
                    .asDriver(onErrorDriveWith: .empty())
            }
            .do(onNext: { _ in isLoadingMore.accept(false) })

        // Handle initial load results
        _ = initialLoad.drive(onNext: { result in
            switch result {
            case .success(let response):
                itemsRelay.accept(response.results)
                errorRelay.accept(nil)
            case .failure(let error):
                if let networkError = error as? NetworkError {
                    errorRelay.accept(networkError.localizedDescription)
                } else {
                    errorRelay.accept(error.localizedDescription)
                }
            }
        })

        // Handle load more results
        _ = loadMore.drive(onNext: { result in
            switch result {
            case .success(let response):
                let current = itemsRelay.value
                itemsRelay.accept(current + response.results)
                errorRelay.accept(nil)
            case .failure(let error):
                if let networkError = error as? NetworkError {
                    errorRelay.accept(networkError.localizedDescription)
                } else {
                    errorRelay.accept(error.localizedDescription)
                }
            }
        })

        return Output(
            title: title,
            items: itemsRelay.asDriver(),
            isLoading: isLoadingRelay.asDriver(),
            error: errorRelay.asDriver()
        )
    }
}
