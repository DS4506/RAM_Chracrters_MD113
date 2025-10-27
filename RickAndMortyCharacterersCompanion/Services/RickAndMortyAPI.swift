
import SwiftUI
import Foundation

enum APIError: Error, LocalizedError {
    case badURL
    case http(Int)
    case decode
    case unknown

    var errorDescription: String? {
        switch self {
        case .badURL: return "Bad URL"
        case .http(let code): return "HTTP \(code)"
        case .decode: return "Failed to decode response"
        case .unknown: return "Unknown error"
        }
    }
}

struct RickAndMortyAPI {
    static var host: String = "https://rickandmortyapi.com/api"
    
    static func fetchCharacters(page: Int) async throws -> CharactersResponse {
        guard let url = URL(string: "\(RickAndMortyAPI.host)/character?page=\(page)")
        else { throw APIError.badURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }
        guard (200...299).contains(http.statusCode) else { throw APIError.http(http.statusCode) }
        
        do {
            return try JSONDecoder().decode(CharactersResponse.self, from: data)
        } catch {
            throw APIError.decode
        }
    }
}
