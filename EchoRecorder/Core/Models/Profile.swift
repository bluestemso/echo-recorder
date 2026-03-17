import Foundation

enum CaptureMode: String, Codable {
    case audioOnly
    case audioAndVideo
}

struct Profile: Codable, Equatable {
    let id: String
    let name: String
    let includeSystemAudio: Bool
    let micDeviceID: String?
    let captureMode: CaptureMode

    init(
        id: String,
        name: String,
        includeSystemAudio: Bool = true,
        micDeviceID: String? = "default",
        captureMode: CaptureMode = .audioOnly
    ) {
        self.id = id
        self.name = name
        self.includeSystemAudio = includeSystemAudio
        self.micDeviceID = micDeviceID
        self.captureMode = captureMode
    }

    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case includeSystemAudio
            case micDeviceID
            case captureMode
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        includeSystemAudio = try container.decodeIfPresent(Bool.self, forKey: .includeSystemAudio) ?? true
        micDeviceID = try container.decodeIfPresent(String.self, forKey: .micDeviceID) ?? "default"
        captureMode = try container.decodeIfPresent(CaptureMode.self, forKey: .captureMode) ?? .audioOnly
    }
}
