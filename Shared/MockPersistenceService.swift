//
//  MockPersistenceService.swift
//  DatabaseFacade
//
//  Created by Joshua Homann on 5/22/21.
//

import Combine
import Foundation

final class MockPersistenceService: PersistenceServiceProtocol {
  @Published var items: [Item] = (0..<10).map { Item(timeStamp: Date.distantFuture + TimeInterval($0)) }
  @discardableResult
  func create(timeStamp: Date) throws -> Item {
    let item = Item(timeStamp: timeStamp)
    items.append(item)
    return item
  }
  func delete(id: Date) throws {
    guard let index = items.firstIndex(where: { $0.timeStamp == id }) else { return }
    items.remove(at: index)
  }
  func publisher(for: Item.Query) -> AnyPublisher<[Item], Never> {
    $items.eraseToAnyPublisher()
  }
}
