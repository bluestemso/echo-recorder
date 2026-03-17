import Foundation

struct AppSettings: Codable, Equatable {
    let activeProfileID: String?
    let captureMode: CaptureMode

    init(activeProfileID: String? = nil, captureMode: CaptureMode = .audioOnly) {
        self.activeProfileID = activeProfileID
        self.captureMode = captureMode
    }

    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case activeProfileID
            case captureMode
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeProfileID = try container.decodeIfPresent(String.self, forKey: .activeProfileID)
        captureMode = try container.decodeIfPresent(CaptureMode.self, forKey: .captureMode) ?? .audioOnly
    }
}
