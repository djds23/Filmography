//
//  ContentView.swift
//  Filmography
//
//  Created by Dean Silfen on 12/27/22.
//

import SwiftUI
import TMDbKit


actor ContentStore {
    var lastUpdated: Date? = Date()
    var actors: Set<Actor> = []

    func update(updatedAt: Date, newActors: Set<Actor>) {
        actors.formUnion(newActors)
        lastUpdated = updatedAt
    }
}

struct ContentCache: Codable {
    var lastUpdated: Date? = Date()
    var actors: Set<Actor> = []
}

class ContentModel: ObservableObject {
    enum Content {
        case loading
        case ready
    }

    var previousWinner: Player?

    @Published var content = Content.loading
    @Published var path = [UUID]()

    var movieService = MovieService.live
    var store = ContentStore()
    var contentCache: ContentCache?

    func configureGameModel(uuid: UUID) -> ConfigureGameModel {
        let model = ConfigureGameModel()
        model.id = uuid
        model.actors = contentCache!.actors.filter { movieActor in
            movieActor.popularity > 20
        }.shuffled()

        model.endGame = { [weak self] winner in
            self?.previousWinner = winner
            self?.path.removeAll()
        }
        return model
    }

    // This is broken, unit test this.
    @MainActor
    func onAppear() async throws {
        let path = Bundle.main.path(forResource: "Keys", ofType: "plist")
        guard let path else {
            fatalError("No Keys.plist file in Filmography directory")
        }

        let filename = "comFilmographyActors.json"
        let cacheURL = URL.cachesDirectory.appending(path: filename)
        let cachePath = cacheURL.path()
        if let data = FileManager.default.contents(atPath: cachePath) {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(ContentCache.self, from: data)
            if let updatedAt = cache.lastUpdated,
               Date().distance(to: updatedAt) > (60 * 60 * 24) {
                contentCache = cache
                content = .ready
                return
            }
        } else {
            let keys = NSDictionary(contentsOfFile: path)
            guard let tmdbKey = keys?["TMDB_Key"] as? String else {
                fatalError("No TMDB_Key Provided")
            }
            let actors = try await movieService.fetchActors(tmdbKey)
            let updatedAt = Date()
            await store.update(updatedAt: updatedAt, newActors: actors)
            let cache = ContentCache(lastUpdated: updatedAt, actors: actors)
            let encoder = JSONEncoder()
            let data = try encoder.encode(cache)
            try data.write(to: cacheURL)
            contentCache = cache
            content = .ready
        }
    }
}

struct ContentView: View {
    @StateObject var model = ContentModel()
    var body: some View {
        NavigationStack(path: $model.path) {
            VStack {
                if let previousWinner = model.previousWinner {
                    Text("Congrats \(previousWinner.name) on your win!")
                }
                if model.content == .ready {
                    NavigationLink("Start Game", value: UUID())
                } else {
                    ProgressView()
                }
            }
            .padding()
            .navigationDestination(for: UUID.self) { id in
                ConfigureGame(model: model.configureGameModel(uuid: id))
            }
            .task { try! await model.onAppear() }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
