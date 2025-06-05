
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let welcome = try? JSONDecoder().decode(Welcome.self, from: jsonData)

import Foundation

// MARK: - Ad
struct Ad: Codable, Identifiable {
    let id: String
    let image: String
    let link: String
    let title: String
    let text: String
}
