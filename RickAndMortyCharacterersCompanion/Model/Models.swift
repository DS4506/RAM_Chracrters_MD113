
import SwiftUI
import Foundation


struct CharactersResponse: Decodable {
    let results: [RMCharacter]
    let info: Info
    struct Info: Decodable {
       let count: Int
        let pages: Int
        let next: String?
        let prev: String?
    }
}

struct RMCharacter: Decodable, Identifiable {
    let id: Int
    let name: String
    let image: String
    let species: String?
    let status: String?
}
