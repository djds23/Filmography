//
//  AddPlayerView.swift
//  Filmography
//
//  Created by Dean Silfen on 12/27/22.
//

import Foundation
import SwiftUI


class AddPlayerModel: ObservableObject, Identifiable {
    var id = UUID()
    var name: String = ""
    var icon: String = ""
    var commit: ((Player) -> Void)?
    func save() {
        if (name.isEmpty && icon.isEmpty) == false {
            commit?(Player(name: name, icon: icon))
        }
    }
}

struct AddPlayerView: View {
    enum Field: Hashable {
        case username
        case icon
        case submit
    }

    @FocusState private var shouldFocus: Bool
    @StateObject var model = AddPlayerModel()
    var body: some View {
        Form {
            Section("Who is Playing") {
                TextField("Player Name", text: $model.name)
                    .tag(Field.username)
                    .padding()
                    .onSubmit {
                        shouldFocus = false
                    }
                    .focused($shouldFocus)
                TextField("Choose an Emioji 💘", text: $model.icon)
                    .tag(Field.icon)
                    .padding()
            }

            Section {
                Button("Save Player") {
                    model.save()
                }
                .tag(Field.submit)
            }
        }
        .padding()
        .onAppear {
            shouldFocus = true
        }
    }
}
