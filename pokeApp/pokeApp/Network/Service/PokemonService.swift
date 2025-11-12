//
//  PokemonService.swift
//  pokeApp
//
//  Created by Faiq Adi on 06/11/25.
//
import RxSwift

class PokemonService {
    static let shared = PokemonService()
    private let network = NetworkService.shared
    
    private init() {}
    
    func getPokemonList(limit: Int = 20, offset: Int = 0) -> Single<PokemonListResponse> {
        let endpoint = PokemonAPI.pokemonList(limit: limit, offset: offset)
        return network.requestSingle(endpoint, responseType: PokemonListResponse.self)
    }
    
    func getPokemonDetail(id: Int) -> Single<PokemonDetail> {
        let endpoint = PokemonAPI.pokemonDetail(id: id)
        return network.requestSingle(endpoint, responseType: PokemonDetail.self)
    }
    
    func getPokemonDetail(name: String) -> Single<PokemonDetail> {
        let endpoint = PokemonAPI.pokemonDetail(name: name)
        return network.requestSingle(endpoint, responseType: PokemonDetail.self)
    }
}
