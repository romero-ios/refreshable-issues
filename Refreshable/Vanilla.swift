//
//  Vanilla.swift
//  Refreshable
//
//  Created by Daniel Romero on 11/26/23.
//

import SwiftUI
import Foundation

public struct Model: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    
    public init(title: String) {
        self.title = title
    }
}

final class AppViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var models: [Model] = []
    
    func onButtonTapped() {
        isLoading = true
        print("isLoading: \(isLoading)")

        Task {
            print("Sleep")
            try await Task.sleep(nanoseconds: 3 * 1_000_000_000)
            print("End Sleep")
            
            await MainActor.run { [weak self] in
                self?.models = [
                    Model(title: "Test"),
                    Model(title: "Test 2"),
                    Model(title: "Test 3")
                ]
                print("models: \(self?.models)")
                
                self?.isLoading = false
                print("isLoading: \(self?.isLoading)")
            }
        }
    }
    
    // Delay Doesn't work, loading indicator goes away instantly and data shows instantly
    func onPullToRefreshAsync() async {
        await MainActor.run { [weak self] in
            self?.isLoading = true
            print("isLoading: \(self?.isLoading)")
        }
        
        print("Sleep")
        try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
        print("End Sleep")

        await MainActor.run { [weak self] in
            self?.models = [
                Model(title: "Pull to refresh 1"),
                Model(title: "Pull to refresh 2"),
                Model(title: "Pull to refresh 3")
            ]
            print("models: \(self?.models)")

            self?.isLoading = false
            print("isLoading: \(self?.isLoading)")
        }
    }
    
    // Also doesn't work
    @MainActor
    func onPullToRefreshMainActor() async {
        isLoading = true
        print("isLoading: \(isLoading)")
        
        print("Sleep")
        try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
        print("End Sleep")
        
        models = [
            Model(title: "Pull to refresh 1"),
            Model(title: "Pull to refresh 2"),
            Model(title: "Pull to refresh 3")
        ]
        print("models: \(models)")

        isLoading = false
        print("isLoading: \(isLoading)")
    }
}

struct Vanilla: View {
    @StateObject var viewModel = AppViewModel()
    @State var viewLoading = false
    
    var body: some View {
        Self._printChanges()
        return VStack {
            ZStack {
                Color.yellow.ignoresSafeArea(.all)
                
                ScrollView {
                    VStack {
                        Text(viewModel.isLoading ? "Loading..." : "Models loaded")
                        Button(action: { viewModel.onButtonTapped() } ) {
                            Text("Load other models")
                        }
                        LazyVGrid(columns: [.init(.flexible())], spacing: 1) {
                            ForEach(viewModel.models) { model in
                                Text(model.title)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    }
                }
                .refreshable {
                    // This works
                    await Task {
                        print("Before task: isCancelled - \(Task.isCancelled)")
                        await viewModel.onPullToRefreshAsync()
                        print("After task: isCancelled - \(Task.isCancelled)")
                    }.value
                    
//                     Doesn't Work
//                        Task {
//                            print("Before task: isCancelled - \(Task.isCancelled)")
//                            await viewModel.onPullToRefreshAsync()
//                            print("After task: isCancelled - \(Task.isCancelled)")
//                        }
                }
            }
        }
    }
    
    // Why does this work??
    private func onPullToRefreshViewLogic() async {
        viewLoading = true
        print("viewLoading: \(viewLoading)")
        
        print("Sleep")
        try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
        print("End Sleep")
        
        viewModel.models = [
            Model(title: "View load 1"),
            Model(title: "View load 2"),
            Model(title: "View load 3")
        ]
        print("models: \(viewModel.models)")

        
        viewLoading = false
        print("viewLoading: \(viewLoading)")
    }
    
    // This also doesn't work
    private func onPullToRefreshViewLogicWithViewModelProperties() async {
        viewModel.isLoading = true
        print("isLoading from view: \(viewModel.isLoading)")
        
        print("Sleep")
        try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
        print("End Sleep")
        
        viewModel.models = [
            Model(title: "View load 1"),
            Model(title: "View load 2"),
            Model(title: "View load 3")
        ]
        print("models: \(viewModel.models)")
        
        viewModel.isLoading = false
        print("isLoading from view: \(viewModel.isLoading)")
    }
}
