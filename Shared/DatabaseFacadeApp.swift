//
//  DatabaseFacadeApp.swift
//  Shared
//
//  Created by Joshua Homann on 5/22/21.
//

import SwiftUI

@main
struct DatabaseFacadeApp: App {
  @StateObject private var services = Services()
  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: .init(persistenceService: services.persistenceService) )
    }
  }
}
