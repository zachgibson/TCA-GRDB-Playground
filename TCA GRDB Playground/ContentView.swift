//
//  ContentView.swift
//  TCA GRDB Playground
//
//  Created by Zachary Gibson on 6/2/24.
//

import ComposableArchitecture
import GRDB
import SwiftUI

@Reducer
struct Feature {
    @ObservableState
    struct State: Equatable {
        @SharedReader(.people) var people
    }
    
    enum Action {
        case addPersonButtonTapped(Person)
        case personDeleted(Person.ID)
        case `init`
        case updatePersonAge(Person.ID, Int)
    }
    
    @Dependency(\.defaultDatabaseQueue) var databaseQueue
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .addPersonButtonTapped(person):
                return .run { _ in
                    do {
                        try await databaseQueue.write { db in
                            try person.insert(db)
                        }
                    } catch {
                        // TODO: Handle error
                    }
                }
            case .`init`:
                return .run { _ in
                    var migrator = DatabaseMigrator()
                    migrator.registerMigration("Create people") { db in
                        try db.create(table: Person.databaseTableName) { t in
                            t.autoIncrementedPrimaryKey("id")
                            t.column("name", .text)
                            t.column("age", .integer)
                        }
                    }
//                    migrator.registerMigration("Add house") { db in
//                        try db.alter(table: Person.databaseTableName) { t in
//                            t.add(column: "house", .text).defaults(to: "Gryffindor")
//                        }
//                    }
                    try migrator.migrate(databaseQueue)
                }
            case let .updatePersonAge(id, newAge):
                return .run { [state] send in
                    try await databaseQueue.write { db in
                        guard var person = state.people[id: id] else { return }
                        person.age = newAge
                        try person.update(db)
                    }
                }
            case let .personDeleted(personID):
                return .run { [state] send in
                    try await databaseQueue.write { db in
                        guard let person = state.people[id: personID] else { return }
                        try person.delete(db)
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @Bindable var store: StoreOf<Feature>
    @State var age = 0
    @State var selectedPerson: Person? = nil
    
    var body: some View {
        VStack {
            Text("Wonderful Wizards")
            Button("Add Random Wizard") {
                let person = Person(name: ["Ron Weasley", "Harry Potter", "Hermione Grainger", "Dumbledore"].randomElement()!, age: 30)
                store.send(.addPersonButtonTapped(person))
            }
            List {
                ForEach(store.people) { person in
                    Button("Name: \(person.name) Age: \(person.age) House: ") {
                        self.selectedPerson = person
                        self.age = person.age
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let id = store.people.elements[index].id
                        store.send(.personDeleted(id))
                    }
                }
            }
        }
        .padding()
        .sheet(item: self.$selectedPerson) { person in
            NavigationView {
                Form {
                    TextField(
                        "Person Name",
                        text: Binding(get: {
                            "\(person.age)"
                        }, set: { newValue in
                            if let newAge = Int(newValue) {
                                self.age = newAge
                            }
                        })
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            store.send(.updatePersonAge(person.id, self.age))
                            self.selectedPerson = nil
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView(
        store: Store(initialState: Feature.State()) {
            Feature()
        }
    )
}
