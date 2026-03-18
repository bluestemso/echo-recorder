import Foundation

struct SaveLocationService {
    private let store: JSONStore
    private static let key = "defaultSaveDirectory"

    static let defaultFallback: URL =
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        ?? FileManager.default.temporaryDirectory

    init(store: JSONStore) {
        self.store = store
    }

    func load() -> URL {
        guard let path = try? store.load(String.self, from: Self.key),
              !path.isEmpty
        else {
            return Self.defaultFallback
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    func save(_ url: URL) throws {
        try store.save(url.path, as: Self.key)
    }
}
