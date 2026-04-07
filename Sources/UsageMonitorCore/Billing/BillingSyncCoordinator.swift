import Foundation

/// Coordinates billing sync so that only one sync runs at a time.
/// If a sync is already in progress, subsequent requests are coalesced —
/// the caller simply awaits the existing sync and receives its result.
public actor BillingSyncCoordinator {
    private var activeTask: Task<SyncResult, Error>?

    /// Returns the result of the current (or next) sync.
    /// If a sync is already running, the caller awaits that sync.
    /// If no sync is running, `execute` is called to start one.
    public func sync(
        _ body: @Sendable @escaping () async throws -> SyncResult
    ) async throws -> SyncResult {
        if let task = activeTask {
            return try await task.value
        }

        let task = Task {
            try await body()
        }
        activeTask = task

        do {
            let result = try await task.value
            activeTask = nil
            return result
        } catch {
            activeTask = nil
            throw error
        }
    }

    /// Cancels the active sync and resets coordinator state.
    public func cancelAndReset() {
        activeTask?.cancel()
        activeTask = nil
    }

    /// Whether a sync is currently in flight.
    public var isSyncing: Bool {
        activeTask != nil
    }
}
