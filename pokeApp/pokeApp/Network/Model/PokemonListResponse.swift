//
//  PokemonListResponse.swift
//  pokeApp
//
//  Created by Faiq Adi on 06/11/25.
//

import Foundation

struct PokemonListResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Pokemon]
}

struct Pokemon: Codable {
    let name: String
    let url: String
    
    var displayName: String {
        name.prefix(1).uppercased() + name.dropFirst()
    }
}
