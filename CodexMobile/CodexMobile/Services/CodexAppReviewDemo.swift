// FILE: CodexAppReviewDemo.swift
// Purpose: Provides the isolated App Review demo session that does not connect to a real Codex CLI.
// Layer: Service support
// Exports: CodexAppReviewDemo helpers and CodexService demo entrypoints
// Depends on: Foundation

import Foundation

enum CodexAppReviewDemo {
    static let qrPayload = "gogodex://app-review-demo"
    static let manualCode = "REVIEWDEMO"
    static let threadID = "app-review-demo-thread"
    static let workspacePath = "/AppReview/GogodexDemo"

    static func isReviewDemoPayload(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed == qrPayload || normalizedCode(trimmed) == manualCode
    }

    static func isManualCode(_ value: String) -> Bool {
        normalizedCode(value) == manualCode
    }

    static func normalizedCode(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    static func response(for prompt: String) -> String {
        let normalized = prompt.lowercased()
        let intro = """
        This is Gogodex App Review demo mode.

        The prompt was received locally inside the iOS app. For review safety, this demo does not connect to a private computer, does not execute shell commands, and does not access real files.
        """

        if normalized.contains("git") || normalized.contains("commit") || normalized.contains("branch") {
            return intro + """

            Demo Git status:
            - Current branch: main
            - Working tree: clean
            - Remote sync: available in a real paired session

            In production, Gogodex sends this request to Codex CLI running on the user's own computer bridge.
            """
        }

        if normalized.contains("file") || normalized.contains("code") || normalized.contains("修改") || normalized.contains("change") {
            return intro + """

            Demo code workflow:
            1. Inspect the relevant files.
            2. Make a scoped change.
            3. Run verification.
            4. Report changed files.

            Demo file change:
            - DemoApp.swift +12 -0

            No real files were modified in App Review demo mode.
            """
        }

        if normalized.contains("security") || normalized.contains("private") || normalized.contains("安全") {
            return intro + """

            Security note:
            - Review mode is fully local and isolated.
            - Production mode pairs with the user's own computer.
            - The relay cannot read encrypted prompts or source code.
            """
        }

        return intro + """

        Demo response:
        In a real paired session, this message would be sent through the encrypted bridge to Codex CLI on the user's computer, and the streamed response would appear here.
        """
    }
}

extension CodexService {
    func startAppReviewDemoSession() {
        clearSavedRelaySession()
        resetSecureTransportState()
        isAppReviewDemoMode = true
        isConnected = true
        isConnecting = false
        isInitialized = true
        isLoadingThreads = false
        isBootstrappingConnectionSync = false
        connectionRecoveryState = .idle
        lastErrorMessage = nil
        connectedServerIdentity = "Gogodex App Review Demo"
        codexTransportMode = .spawn
        secureConnectionState = .encrypted
        secureMacFingerprint = "APP-REVIEW"

        let now = Date()
        let thread = CodexThread(
            id: CodexAppReviewDemo.threadID,
            title: "Gogodex App Review Demo",
            name: "Gogodex App Review Demo",
            preview: "Safe local demo session for App Review.",
            createdAt: now,
            updatedAt: now,
            cwd: CodexAppReviewDemo.workspacePath,
            syncState: .live
        )
        threads = [thread]
        messagesByThread[CodexAppReviewDemo.threadID] = [
            CodexMessage(
                threadId: CodexAppReviewDemo.threadID,
                role: .assistant,
                text: """
                Welcome to Gogodex App Review demo mode.

                This isolated session lets App Review test pairing, navigation, settings, and chat UI without connecting to a private Mac or executing Codex CLI commands.
                """
            )
        ]
        hydratedThreadIDs.insert(CodexAppReviewDemo.threadID)
        initialTurnsLoadedByThreadID.insert(CodexAppReviewDemo.threadID)
        activeThreadId = CodexAppReviewDemo.threadID
        persistMessages()
        rebuildThreadLookupCaches()
        refreshThreadTimelineState(for: CodexAppReviewDemo.threadID)
    }

    func startAppReviewDemoTurn(userInput: String, threadId: String?) async throws {
        let requestedThreadID = threadId ?? CodexAppReviewDemo.threadID
        if thread(for: requestedThreadID) == nil {
            startAppReviewDemoSession()
        }
        let resolvedThreadID = thread(for: requestedThreadID) == nil
            ? CodexAppReviewDemo.threadID
            : requestedThreadID

        let turnID = "review-demo-turn-\(UUID().uuidString)"
        appendMessage(
            CodexMessage(
                threadId: resolvedThreadID,
                role: .user,
                text: userInput,
                turnId: turnID,
                deliveryState: .confirmed
            )
        )
        appendMessage(
            CodexMessage(
                threadId: resolvedThreadID,
                role: .assistant,
                text: CodexAppReviewDemo.response(for: userInput),
                turnId: turnID,
                deliveryState: .confirmed
            )
        )
        activeThreadId = resolvedThreadID
        lastErrorMessage = nil
        refreshThreadTimelineState(for: resolvedThreadID)
    }
}
