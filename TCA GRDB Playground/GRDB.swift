//
//  GRDB.swift
//  TCA GRDB Playground
//
//  Created by Zachary Gibson on 6/3/24.
//

import ComposableArchitecture
import GRDB

public protocol GRDBQuery: Hashable {
    associatedtype Value
    func fetch(_ db: Database) throws -> Value
}

extension PersistenceReaderKey {
    public static func query<Query: GRDBQuery>(_ query: Query) -> Self
    where Self == GRDBQueryKey<Query> {
        Self(query)
    }
}

public struct GRDBQueryKey<Query: GRDBQuery>: PersistenceReaderKey {
    let query: Query
    
    public init(_ query: Query) {
        self.query = query
    }
    
    public var id: Query {
        return query
    }
    
    public func load(initialValue: Query.Value?) -> Query.Value? {
        do {
            @Dependency(\.defaultDatabaseQueue) var defaultDatabaseQueue
            return try defaultDatabaseQueue.read { db in
                return try query.fetch(db)
            }
        } catch {
            // TODO: Handle error
            return initialValue
        }
    }
    
    public func subscribe(
        initialValue: Query.Value?,
        didSet: @Sendable @escaping (_ newValue: Query.Value?) -> Void
    ) -> Shared<Query.Value>.Subscription {
        @Dependency(\.defaultDatabaseQueue) var defaultDatabaseQueue
        let observation = ValueObservation.tracking { db in
            try query.fetch(db)
        }
        let cancellable = observation.start(in: defaultDatabaseQueue) { error in
            // TODO: Handle error
        } onChange: { newValue in
            print(newValue)
            didSet(newValue)
        }
        return Shared.Subscription {
            cancellable.cancel()
        }
    }
}

private enum GRDBDefaultDatabaseQueueKey: TestDependencyKey {
    static var testValue: DatabaseQueue {
        try! DatabaseQueue()
    }
}

extension DependencyValues {
    public var defaultDatabaseQueue: DatabaseQueue {
        get { self[GRDBDefaultDatabaseQueueKey.self] }
        set { self[GRDBDefaultDatabaseQueueKey.self] = newValue }
    }
}

extension FetchRequest where RowDecoder: FetchableRecord & Identifiable {
    public func fetchIdentifiedArray(_ db: Database) throws -> IdentifiedArrayOf<RowDecoder> {
        try IdentifiedArray(fetchCursor(db))
    }
}
