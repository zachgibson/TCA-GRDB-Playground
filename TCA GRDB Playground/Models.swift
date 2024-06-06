//
//  Models.swift
//  TCA GRDB Playground
//
//  Created by Zachary Gibson on 6/4/24.
//

import ComposableArchitecture
import GRDB

struct Person: Equatable, Identifiable, Codable {
    var id: Int?
    let name: String
    var age: Int
//    var house: House
//    
//    enum House: String, Codable {
//        case ravenclaw
//        case gryffindor
//        case hufflepuff
//        case slytherin
//    }
}

extension Person: TableRecord, PersistableRecord, FetchableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
      self.id = Int(inserted.rowID)
    }
}

extension PersistenceReaderKey where Self == PersistenceKeyDefault<GRDBQueryKey<PeopleRequest>> {
    static var people: Self {
        PersistenceKeyDefault(.query(PeopleRequest()), [])
    }
}

struct PeopleRequest: GRDBQuery {
    func fetch(_ db: Database) throws -> IdentifiedArrayOf<Person> {
        try Person.all().fetchIdentifiedArray(db)
    }
}
