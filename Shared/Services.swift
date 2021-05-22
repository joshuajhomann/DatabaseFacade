//
//  Services.swift
//  DatabaseFacade
//
//  Created by Joshua Homann on 5/22/21.
//

import Combine

final class Services: ObservableObject {
  let persistenceService: PersistenceServiceProtocol = PersistenceService()
}
