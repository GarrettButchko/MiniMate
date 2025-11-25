//
//  GameRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//

protocol GameRepository {
    func save(_ game: Game, completion: @escaping (Bool) -> Void)
    func fetch(id: String, completion: @escaping (Game?) -> Void)
    func fetchAll(completion: @escaping ([Game]) -> Void)
    func delete(id: String, completion: @escaping (Bool) -> Void)
}
