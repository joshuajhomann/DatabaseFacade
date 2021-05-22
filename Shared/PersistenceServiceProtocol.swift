//
//  PersistenceServiceProtocol.swift
//  DatabaseFacade
//
//  Created by Joshua Homann on 5/22/21.
//

import Combine
import Foundation

protocol PersistenceServiceProtocol {
  @discardableResult
  func create(timeStamp: Date) throws -> Item
  func delete(id: Date) throws
  func publisher(for: Item.Query) -> AnyPublisher<[Item], Never>
}

struct Item: Hashable, Identifiable {
  var id: Date { timeStamp }
  var timeStamp: Date
}

extension Item {
  enum Query: Hashable {
    case all
  }
}
