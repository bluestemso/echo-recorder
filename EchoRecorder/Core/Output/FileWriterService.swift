import Foundation

protocol FileWriting {
    func outputURL(fileName: String, directory: URL) -> URL
}

struct FileWriterService: FileWriting {
    func outputURL(fileName: String, directory: URL) -> URL {
        directory.appendingPathComponent(fileName, isDirectory: false)
    }
}
