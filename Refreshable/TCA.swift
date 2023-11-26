//
//  TCA.swift
//  Refreshable
//
//  Created by Daniel Romero on 11/26/23.
//

import ComposableArchitecture
import SwiftUI
import Foundation

extension Model {
    static let test: [Self] = [
        Self(title: "Test 1"),
        Self(title: "Test 2"),
        Self(title: "Test 3")
    ]
    
    static let refresh: [Self] = [
        Self(title: "Pull to refresh 1"),
        Self(title: "Pull to refresh 1"),
        Self(title: "Pull to refresh 1")
    ]
}

@Reducer
public struct AppFeature: Reducer {
    public struct State: Equatable {
        public var isLoading = false
        public var models: [Model] = []
    }
    
    public enum Action: Equatable {
        case onButtonTapped
        case onPullToRefresh
        case modelsRequest(isPullToRefesh: Bool)
        case modelsResponse(TaskResult<[Model]>)
    }
    
    @Dependency(\.mainQueue) var mainQueue
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onButtonTapped:
                return .send(.modelsRequest(isPullToRefesh: false))
                
            case .onPullToRefresh:
                return .send(.modelsRequest(isPullToRefesh: true))
                
            case let .modelsRequest(isPullToRefesh):
                state.isLoading = true
                print("isLoading: \(state.isLoading)")
                return .run { send in
                    print("Sleep")
                    try await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                    print("End Sleep")
                    await send(
                        .modelsResponse(TaskResult { return isPullToRefesh ? Model.refresh : Model.test })
                    )
                }
                
            case let .modelsResponse(result):
                state.isLoading = false
                print("isLoading: \(state.isLoading)")

                state.models = (try? result.value) ?? []
                print("models: \(state.models)")

                return .none
            }
        }
    }
}

public struct AppView: View {
    let store: StoreOf<AppFeature>
    @ObservedObject var viewStore: ViewStore<AppFeature.State, AppFeature.Action>
    
    public init(store: StoreOf<AppFeature>) {
        self.store = store
        self.viewStore = ViewStore(store, observe: { $0 })
    }
    
    public var body: some View {
        VStack {
            ZStack {
                Color.orange.ignoresSafeArea(.all)
                
                ScrollView {
                    VStack {
                        Text(viewStore.isLoading ? "Loading..." : "Models loaded")
                        Button(action: { viewStore.send(.onButtonTapped) } ) {
                            Text("Load other models")
                        }
                        LazyVGrid(columns: [.init(.flexible())], spacing: 1) {
                            ForEach(viewStore.models) { model in
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
                    print("Before task: isCancelled - \(Task.isCancelled)")
                    // This fails the first time, but succeeds the second time, all the time
//                    await viewStore.send(.onPullToRefresh, while: \.isLoading)
                    
                    // This successfully updates the UI with the data, but the loading
                    // indicator goes away immediately
//                    Task {
//                        await viewStore.send(.onPullToRefresh, while: \.isLoading)
//                    }
                    
                    // This works as expected
                    await Task {
                        await viewStore.send(.onPullToRefresh, while: \.isLoading)
                    }.value
                    
                    print("After task: isCancelled - \(Task.isCancelled)")
                }
            }
        }
    }
}
