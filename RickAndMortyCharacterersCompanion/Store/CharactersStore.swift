
import Swift
import Foundation

@MainActor
final class CharactersStore: ObservableObject {
    @Published var characters: [RMCharacter] = []
    @Published var isInitialLoading = false
    @Published var errorMessage: String?
    @Published var isLoadingPage = false
    @Published var reachedEnd = false
    private var page = 1

    func initialLoad() async {
        guard characters.isEmpty else { return }
        isInitialLoading = true
        defer { isInitialLoading = false }
        await loadNextPage()
    }

    func refresh() async {
        page = 1
        reachedEnd = false
        characters.removeAll()
        errorMessage = nil
        await loadNextPage()
    }

    func loadMoreIfNeeded(current item: RMCharacter?) async {
        guard !isLoadingPage, !reachedEnd else { return }
        guard let item = item else {
            await loadNextPage()
            return
        }
        let threshold = max(0, characters.count - 4)
        if let idx = characters.firstIndex(where: { $0.id == item.id }),
           idx >= threshold {
            await loadNextPage()
        }
    }

    private func loadNextPage() async {
        guard !isLoadingPage, !reachedEnd else { return }
        isLoadingPage = true
        defer { isLoadingPage = false }
        do {
            let response = try await RickAndMortyAPI.fetchCharacters(page: page)
            if response.results.isEmpty {
                reachedEnd = true
                return
            }
            characters.append(contentsOf: response.results)
            page += 1
            reachedEnd = (response.info.next == nil)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
