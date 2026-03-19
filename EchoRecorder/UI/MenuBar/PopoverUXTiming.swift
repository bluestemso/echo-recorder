import SwiftUI

enum PopoverUXTiming {
    static let popoverFadeDuration: TimeInterval = 0.075
    static let contentTransitionDuration: TimeInterval = 0.15
    static let postSaveResetDelay: TimeInterval = 1.5
}

enum PopoverPresentationPhase {
    case show
    case close
}

enum PopoverContentTransitionPolicy: Equatable {
    case fadeAndMoveFromBottom
    case opacityOnly

    static func resolve(reduceMotion: Bool) -> PopoverContentTransitionPolicy {
        reduceMotion ? .opacityOnly : .fadeAndMoveFromBottom
    }

    var transition: AnyTransition {
        switch self {
        case .fadeAndMoveFromBottom:
            return AnyTransition.opacity.combined(with: .move(edge: .bottom))
        case .opacityOnly:
            return AnyTransition.opacity
        }
    }
}

enum PopoverAnimationPolicy {
    static let usesSystemPopoverAnimation = false

    static func fadeDuration(for phase: PopoverPresentationPhase) -> TimeInterval {
        switch phase {
        case .show, .close:
            return PopoverUXTiming.popoverFadeDuration
        }
    }
}
