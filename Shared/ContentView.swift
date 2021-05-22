//
//  ContentView.swift
//  Shared
//
//  Created by Joshua Homann on 5/22/21.
//

import Combine
import CoreData
import SwiftUI

// MARK: - ViewModel
final class ViewModel: ObservableObject {
  
  // MARK: - Instance
  @Published private(set) var cells: [Cell] = []
  // MARK: - Private
  private var subscriptions: Set<AnyCancellable> = []
  private let persistenceService: PersistenceServiceProtocol
  struct Cell: Hashable, Identifiable {
    var title: String
    var id: Date
  }
  // MARK: - Init
  init(persistenceService: PersistenceServiceProtocol = PersistenceService()) {
    self.persistenceService = persistenceService
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .medium
    persistenceService
      .publisher(for: .all)
      .map { items in
        items.map { item in Cell(title: formatter.string(from: item.timeStamp), id: item.timeStamp) }
      }
      .assign(to: &$cells)
  }

  func addItem() {
    _ = try? persistenceService.create(timeStamp: Date())
  }

  func deleteItems(at offsets: IndexSet) {
    offsets.forEach { offset in
      try? persistenceService.delete(id: cells[offset].id)
    }
  }
}

struct ContentView: View {
  @StateObject private var viewModel: ViewModel
  init(viewModel: ViewModel) {
    _viewModel = .init(wrappedValue: viewModel)
  }
  var body: some View {
    let view = List {
      ForEach(viewModel.cells) { cell in
        Text(cell.title)
      }
      .onDelete(perform: viewModel.deleteItems(at:))
    }
    .toolbar {
      Button(action: viewModel.addItem) {
        Label("Add Item", systemImage: "plus")
      }
    }
    .navigationTitle("Demo")
    #if os(iOS)
    return NavigationView {
      view
    }
    #else
    return view
    #endif
  }
}

struct ContentMacPreview: PreviewProvider {
  static var platform: PreviewPlatform? { .macOS }
  static var previews: some View {
    Group {
      ContentView(viewModel: .init(persistenceService: MockPersistenceService()))
        .previewDevice("Mac")
        .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/400.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/400.0/*@END_MENU_TOKEN@*/))
    }
  }
}

struct ContentPreview: PreviewProvider {
  static var platform: PreviewPlatform? { .iOS }
  static var previews: some View {
    Group {
      ContentView(viewModel: .init(persistenceService: MockPersistenceService()))
        .previewDevice("iPhone 8")
      ContentView(viewModel: .init(persistenceService: MockPersistenceService()))
        .previewLayout(.device)
        .preferredColorScheme(.dark)
        .environment(\.sizeCategory, .accessibilityLarge)

        .previewDevice("iPhone 8")
    }
  }
}


