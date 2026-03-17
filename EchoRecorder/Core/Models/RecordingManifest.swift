import Foundation

struct RecordingManifest: Codable, Equatable {
    let profileID: String
    let recordingFileNames: [String]
    let isFinalized: Bool
    let captureMode: CaptureMode

    init(
        profileID: String,
        recordingFileNames: [String],
        isFinalized: Bool = false,
        captureMode: CaptureMode = .audioOnly
    ) {
        self.profileID = profileID
        self.recordingFileNames = recordingFileNames
        self.isFinalized = isFinalized
        self.captureMode = captureMode
    }

    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case profileID
            case recordingFileNames
            case isFinalized
            case captureMode
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        profileID = try container.decode(String.self, forKey: .profileID)
        recordingFileNames = try container.decode([String].self, forKey: .recordingFileNames)
        isFinalized = try container.decodeIfPresent(Bool.self, forKey: .isFinalized) ?? false
        captureMode = try container.decodeIfPresent(CaptureMode.self, forKey: .captureMode) ?? .audioOnly
    }
}
