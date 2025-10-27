
import SwiftUI

struct CharacterDetailView: View {
    let character: RMCharacter

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: character.image)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    case .empty:
                        ProgressView().frame(height: 120)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }

                Text(character.name)
                    .font(.headline)

                if let species = character.species, !species.isEmpty {
                    Text(species).font(.footnote).foregroundStyle(.secondary)
                }
                if let status = character.status, !status.isEmpty {
                    Text(status).font(.footnote)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .navigationTitle("Details")
    }
}
