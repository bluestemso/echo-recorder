import Foundation

enum JSONStoreError: Error {
    case invalidKey(String)
    case saveFailed(key: String, underlying: Error)
    case loadFailed(key: String, underlying: Error)
}

struct JSONStore {
    private let baseDirectory: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseDirectory: URL,
        fileManager: FileManager = .default
    ) {
        self.baseDirectory = baseDirectory
        self.fileManager = fileManager
        self.encoder = JSONStore.makeEncoder()
        self.decoder = JSONDecoder()
    }

    func save<Value: Encodable>(_ value: Value, as key: String) throws {
        do {
            let targetURL = try fileURL(for: key)
            try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
            let data = try encoder.encode(value)
            try data.write(to: targetURL, options: [.atomic])
        } catch {
            if let storeError = error as? JSONStoreError {
                throw storeError
            }
            throw JSONStoreError.saveFailed(key: key, underlying: error)
        }
    }

    func load<Value: Decodable>(_ type: Value.Type, from key: String) throws -> Value {
        do {
            let sourceURL = try fileURL(for: key)
            let data = try Data(contentsOf: sourceURL)
            return try decoder.decode(type, from: data)
        } catch {
            if let storeError = error as? JSONStoreError {
                throw storeError
            }
            throw JSONStoreError.loadFailed(key: key, underlying: error)
        }
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private func fileURL(for key: String) throws -> URL {
        try validate(key: key)
        return baseDirectory.appendingPathComponent(key).appendingPathExtension("json")
    }

    private func validate(key: String) throws {
        guard !key.isEmpty,
              !key.contains("/"),
              !key.contains("\\"),
              !key.contains("..")
        else {
            throw JSONStoreError.invalidKey(key)
        }
    }
}
