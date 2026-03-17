import Foundation

enum RecordingFinalizerError: Error, Equatable {
    case emptyFileName
    case invalidFileName(String)
}

struct RecordingFinalizer {
    let fileWriter: any FileWriting
    let defaultDirectory: URL

    func finalize(fileName: String, overrideDirectory: URL?) throws -> URL {
        let sanitizedFileName = try validate(fileName: fileName)
        let directory = overrideDirectory ?? defaultDirectory
        return fileWriter.outputURL(fileName: sanitizedFileName, directory: directory)
    }

    private func validate(fileName: String) throws -> String {
        let trimmedName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            throw RecordingFinalizerError.emptyFileName
        }

        guard !trimmedName.contains("/"),
              !trimmedName.contains("\\"),
              !trimmedName.contains("..")
        else {
            throw RecordingFinalizerError.invalidFileName(fileName)
        }

        return trimmedName
    }
}
