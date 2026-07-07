import Foundation
import Combine

@MainActor
final class Store: ObservableObject {
    @Published var entries: [TripinsureEntry] = []
    @Published var isPro: Bool = false

    /// Free-tier cap. Always set safely above the seed count so a fresh
    /// install never hits the paywall immediately.
    static let freeLimit = 8

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("tripinsure_entries.json")
        load()
    }

    var canAddMore: Bool {
        isPro || entries.count < Store.freeLimit
    }

    @discardableResult
    func add(field1: String, field2: String, field3: String) -> Bool {
        guard canAddMore else { return false }
        let entry = TripinsureEntry(field1: field1, field2: field2, field3: field3)
        entries.insert(entry, at: 0)
        save()
        return true
    }

    func update(_ entry: TripinsureEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = entry
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func delete(_ entry: TripinsureEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([TripinsureEntry].self, from: data) {
            entries = decoded
        } else {
            entries = [
            TripinsureEntry(field1: "Sample Policy Number 1", field2: "Sample Provider 1", field3: "Sample Coverage End Date 1"),
            TripinsureEntry(field1: "Sample Policy Number 2", field2: "Sample Provider 2", field3: "Sample Coverage End Date 2"),
            TripinsureEntry(field1: "Sample Policy Number 3", field2: "Sample Provider 3", field3: "Sample Coverage End Date 3")
            ]
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
