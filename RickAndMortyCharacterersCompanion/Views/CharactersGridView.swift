
import SwiftUI

struct CharactersGridView: View {
    @EnvironmentObject private var store: CharactersStore

    // Two columns that fit well on Apple Watch
    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]

    var body: some View {
        Group {
            // Initial loading state
            if store.isInitialLoading && store.characters.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading…")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

            // Error state (with retry)
            } else if let message = store.errorMessage, store.characters.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.yellow)
                    Text(message)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await store.refresh() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
                .padding(.horizontal, 8)

            // Normal content (scrollable grid)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(store.characters) { character in
                            NavigationLink {
                                CharacterDetailView(character: character)
                            } label: {
                                CharacterTile(character: character)
                            }
                            .buttonStyle(.plain)
                            // ⬇️ Trigger pagination as we near the bottom
                            .task { await store.loadMoreIfNeeded(current: character) }
                        }

                        // Footer: spinner while loading next page, or an end marker
                        if store.isLoadingPage {
                            HStack {
                                Spacer()
                                ProgressView().controlSize(.mini)
                                Spacer()
                            }
                        } else if store.reachedEnd, !store.characters.isEmpty {
                            Text("No more results")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 6)  // keep within safe bounds
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Characters")
    }
}
