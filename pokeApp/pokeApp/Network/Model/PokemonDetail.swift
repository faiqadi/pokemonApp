//
//  PokemonDetail.swift
//  pokeApp
//
//  Created by Faiq Adi on 06/11/25.
//
import Foundation

struct PokemonDetail: Codable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let types: [PokemonTypeEntry]
    let sprites: PokemonSprites
    
    var displayName: String {
        name.prefix(1).uppercased() + name.dropFirst()
    }
    
    var typesString: String {
        types.map { $0.type.name.capitalized }.joined(separator: ", ")
    }
}

struct PokemonTypeEntry: Codable {
    let slot: Int
    let type: PokemonType
}

struct PokemonType: Codable {
    let name: String
    let url: String
}

struct PokemonSprites: Codable {
    let frontDefault: String?
    
    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}
