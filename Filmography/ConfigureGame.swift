//
//  ConfigureGame.swift
//  Filmography
//
//  Created by Dean Silfen on 12/27/22.
//

import SwiftUI
import TMDbKit

struct Player: Identifiable, Hashable {
    var name: String
    var icon: String

    var id: String {
        name + icon
    }
}

class ConfigureGameModel: ObservableObject, Identifiable {
    var id = UUID()
    var actors = [Actor]()
    @Published var players = [Player]()
    @Published var addPlayer: AddPlayerModel? = nil
    @Published var gameModel: GameModel? = nil

    var endGame: ((Player?) -> Void)?

    func toggleAddPlayer() {
        if addPlayer == nil {
            let model = AddPlayerModel()
            model.commit = { [weak self] newPlayer in
                self?.players.append(newPlayer)
                self?.addPlayer = nil
            }
            addPlayer = model
        } else {
            addPlayer = nil
        }
    }

    func startGame() {
        let newGameModel = GameModel()
        newGameModel.players = players
        newGameModel.endGame = endGame
        newGameModel.actors = actors
        gameModel = newGameModel
    }
}

struct PlayerCell: View {
    @Binding var player: Player
    var body: some View {
        Text(player.icon + " " + player.name)
    }
}
struct ConfigureGame: View {
    @StateObject var model = ConfigureGameModel()
    var body: some View {
        VStack {
            if model.players.isEmpty {
                Button("Add Players", action: model.toggleAddPlayer)
            } else {
                List {
                    ForEach($model.players, editActions: .all) { playerBinding in
                        PlayerCell(player: playerBinding)
                    }
                }
                if model.players.count >= 2 {
                    Button("Start Game", action: model.startGame)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: model.toggleAddPlayer) {
                    Label("Add Player", systemImage: "plus.app")
                }
            }
        }
        .sheet(item: $model.addPlayer) { model in
            AddPlayerView(model: model)
        }
        .fullScreenCover(item: $model.gameModel) { model in
            GameView(model: model)
        }
    }
}


struct ConfigureGame_Previews: PreviewProvider {
    static var previews: some View {
        ConfigureGame()
    }
}
