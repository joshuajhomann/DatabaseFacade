//
//  PersistenceService.swift
//  Shared
//
//  Created by Joshua Homann on 5/22/21.
//

import CoreData
import Combine

final class PersistenceService: NSObject, PersistenceServiceProtocol {

  // MARK: - PersistenceServiceProtocol

  @discardableResult
  func create(timeStamp: Date) throws -> Item {
    let newItem = ManagedItem(context: container.viewContext)
    newItem.timeStamp = .init()
    try container.viewContext.save()
    return .init(from: newItem)
  }

  func delete(id: Date) throws {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedItem.description())
    let sort = NSSortDescriptor(key: "timeStamp", ascending: false)
    request.sortDescriptors = [sort]
    request.predicate = NSPredicate(format: "timeStamp = %@", id as NSDate)
    guard let toDelete = try container.viewContext.fetch(request).first as? NSManagedObject else { return }
    container.viewContext.delete(toDelete)
  }

  func publisher(for query: Item.Query) -> AnyPublisher<[Item], Never> {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedItem.description())
    let sort = NSSortDescriptor(key: "timeStamp", ascending: false)
    request.sortDescriptors = [sort]
    let controller = controllers[query] ?? {
      let controller = NSFetchedResultsController<NSFetchRequestResult>(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
      controller.delegate = self
      try? controller.performFetch()
      return controller
    }()
    let subject = publishers[controller] ?? PassthroughSubject<[Item], Never>()
    publishers[controller] = subject
    controllers[query] = controller
    queryCount[query, default: 0] += 1
    let initial = (try? container.viewContext.fetch(request).compactMap { ($0 as? ManagedItem).map(Item.init(from:)) }) ?? []
    return subject
      .handleEvents(
        receiveCancel: { [weak self] in
        guard let self = self else { return }
        self.queryCount[query, default: 0] -= 1
        guard let count = self.queryCount[query], count < 1 else { return }
        self.publishers.removeValue(forKey: controller)
        self.controllers.removeValue(forKey: query)
        self.queryCount.removeValue(forKey: query)
      })
      .prepend(initial)
      .eraseToAnyPublisher()
  }

  // MARK: - Instance

  private var publishers: [NSFetchedResultsController<NSFetchRequestResult>: PassthroughSubject<[Item], Never>] = [:]
  private var controllers: [Item.Query: NSFetchedResultsController<NSFetchRequestResult>] = [:]
  private var queryCount: [Item.Query: Int] = [:]
  private let container: NSPersistentContainer
  
  override init() {
    container = NSPersistentContainer(name: "DatabaseFacade")
    super.init()
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
  }
}

// MARK: - NSFetchedResultsControllerDelegate
extension PersistenceService: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    guard let subject = publishers[controller],
          let items = controller.fetchedObjects?.compactMap({ ($0 as? ManagedItem).map(Item.init(from:)) }) else {
      return
    }
    subject.send(items)
  }
}


// MARK: - CoreData Initializer
private extension Item {
  init(from managedItem: ManagedItem) {
    timeStamp = managedItem.timeStamp ?? Date()
  }
}
