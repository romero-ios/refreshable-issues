//
//  RefreshableApp.swift
//  Refreshable
//
//  Created by Daniel Romero on 11/26/23.
//

import SwiftUI
import Foundation

enum AppSelection: Int, CaseIterable {
    case vanilla = 0
    case tca
    
    var title: String {
        switch self {
        case .vanilla: return "Vanilla App"
        case .tca: return "TCA App"
        }
    }
}
@main
struct RefreshableApp: App {
    @State var selection: AppSelection = .vanilla
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack {
                    Picker("Select app to run", selection: $selection) {
                        ForEach(AppSelection.allCases, id: \.self) { selection in
                            Text(selection.title)
                        }
                    }
                    switch selection {
                    case .vanilla:
                        Vanilla()
                        
                    case .tca:
                        AppView(
                            store: .init(
                                initialState: .init(),
                                reducer: {
                                    AppFeature()
                                }
                            )
                        )
                    }
                }
                .navigationTitle("Refreshable Demo")
            }
        }
    }
}
