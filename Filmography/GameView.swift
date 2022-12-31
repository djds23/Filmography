//
//  GameView.swift
//  Filmography
//
//  Created by Dean Silfen on 12/27/22.
//

import SwiftUI
import TMDbKit

class GameModel: ObservableObject, Identifiable {
    let id = UUID()
    var players = [Player]()
    @Published var currentActor: Actor? = nil
    var actors: [Actor] = []
    var score = [Player: Int]()

    var endGame: ((Player?) -> Void)?

    func award(player: Player) {
        score[player, default: 0] += 1
        nextActor()
    }

    func nextActor() {
        currentActor = actors.popLast()
    }

    func scoreFor(player: Player) -> Int {
        score[player, default: 0]
    }

    func commitEndGame() {
        let winner = score.max { lhs, rhs in
            lhs.value > rhs.value
        }?.key
        endGame?(winner)
    }
}

struct GameView: View {
    @StateObject var model = GameModel()
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    AsyncImage(url: model.currentActor?.profileURL)
                    Text(model.currentActor?.name ?? "N/A")
                }
                .padding()
                List {
                    ForEach(model.players) { player in
                        Button(
                            "\(player.icon) \(player.name) \(model.scoreFor(player: player))") {
                                model.award(player: player)
                            }
                    }
                }
                .padding()
                Button(role: .destructive) {
                    model.nextActor()
                } label: {
                    Label("Skip Actor", systemImage: "arrowshape.right")
                }
            }
            .toolbar {
                ToolbarItem {
                    Button("End Game") {
                        model.commitEndGame()
                    }
                }
            }
            .onAppear(perform: model.nextActor)
        }
    }
}

extension Actor {
    var profileURL: URL? {
        let base = "https://image.tmdb.org/t/p/w200"
        return profile_path.flatMap { path in
            URL(string: base + path)
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
