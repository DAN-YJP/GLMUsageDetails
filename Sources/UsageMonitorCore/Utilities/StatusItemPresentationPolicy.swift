public enum StatusItemClickTrigger: String, Sendable {
    case leftMouseUp
    case rightMouseDown
}

public enum StatusItemPresentationPolicy {
    public static let triggerEvents: Set<StatusItemClickTrigger> = [.leftMouseUp, .rightMouseDown]

    public static func shouldHighlightStatusItem(isPanelVisible: Bool) -> Bool {
        isPanelVisible
    }
}
