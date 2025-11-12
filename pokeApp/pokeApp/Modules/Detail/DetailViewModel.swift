// © 2025 faiqadi. All rights reserved.

import Foundation
import RxSwift
import RxCocoa

final class DetailViewModel {
    private let pokemonService: PokemonService
    private let pokemon: Pokemon
    private let disposeBag = DisposeBag()

    private let detailRelay = BehaviorRelay<PokemonDetail?>(value: nil)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    struct Input {
        let appear: Driver<Void>
    }

    struct Output {
        let title: Driver<String>
        let itemText: Driver<String>
        let isLoading: Driver<Bool>
        let error: Driver<String?>
        let imageURL: Driver<URL?>
    }

    init(pokemon: Pokemon, pokemonService: PokemonService = .shared) {
        self.pokemon = pokemon
        self.pokemonService = pokemonService
    }

    func transform(input: Input) -> Output {
        _ = input.appear
            .drive(onNext: { [weak self] in
                self?.loadDetailIfNeeded()
            })

        let title = detailRelay
            .asDriver()
            .map { [weak self] detail -> String in
                if let detail = detail {
                    return detail.displayName
                }
                return self?.pokemon.displayName ?? "Detail"
            }

        let itemText = detailRelay
            .asDriver()
            .map { detail -> String in
                guard let detail = detail else { return "Loading..." }
                return """
                #\(detail.id)

                Height: \(detail.height) dm
                Weight: \(detail.weight) hg
                Types: \(detail.typesString)
                """
            }

        let imageURL = detailRelay
            .asDriver()
            .map { detail -> URL? in
                guard let urlString = detail?.sprites.frontDefault else { return nil }
                return URL(string: urlString)
            }

        return Output(
            title: title,
            itemText: itemText,
            isLoading: isLoadingRelay.asDriver(),
            error: errorRelay.asDriver(),
            imageURL: imageURL
        )
    }

    private func loadDetailIfNeeded() {
        guard detailRelay.value == nil, !isLoadingRelay.value else { return }

        isLoadingRelay.accept(true)
        errorRelay.accept(nil)

        pokemonService
            .getPokemonDetail(name: pokemon.name)
            .subscribe(
                onSuccess: { [weak self] detail in
                    self?.isLoadingRelay.accept(false)
                    self?.detailRelay.accept(detail)
                },
                onFailure: { [weak self] error in
                    self?.isLoadingRelay.accept(false)
                    if let networkError = error as? NetworkError {
                        self?.errorRelay.accept(networkError.localizedDescription)
                    } else {
                        self?.errorRelay.accept(error.localizedDescription)
                    }
                }
            )
            .disposed(by: disposeBag)
    }
}
