//
//  PokemonAPI.swift
//  pokeApp
//
//  Created by Faiq Adi on 06/11/25.
//
import Foundation
import Alamofire

enum PokemonAPI: NetworkRequest {
    case pokemonList(limit: Int, offset: Int)
    case pokemonDetail(id: Int)
    case pokemonDetail(name: String)
    
    var baseURL: String {
        "https://pokeapi.co/api/v2"
    }
    
    var path: String {
        switch self {
        case .pokemonList:
            return "/pokemon"
        case .pokemonDetail(let id):
            return "/pokemon/\(id)"
        case .pokemonDetail(let name):
            return "/pokemon/\(name)"
        default: return "/pokemon"
        }
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var parameters: Parameters? {
        switch self {
        case .pokemonList(let limit, let offset):
            return ["limit": limit, "offset": offset]
        default:
            return nil
        }
    }
}
