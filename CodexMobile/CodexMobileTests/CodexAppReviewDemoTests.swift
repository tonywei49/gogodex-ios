// FILE: CodexAppReviewDemoTests.swift
// Purpose: Verifies App Review demo mode stays local and usable.
// Layer: Unit Test
// Exports: CodexAppReviewDemoTests
// Depends on: XCTest, CodexMobile

import XCTest
@testable import CodexMobile

@MainActor
final class CodexAppReviewDemoTests: XCTestCase {
    private static var retainedServices: [CodexService] = []

    func testStartingDemoSessionCreatesConnectedLocalThread() {
        let service = makeService()

        service.startAppReviewDemoSession()

        XCTAssertTrue(service.isAppReviewDemoMode)
        XCTAssertTrue(service.isConnected)
        XCTAssertEqual(service.activeThreadId, CodexAppReviewDemo.threadID)
        XCTAssertEqual(service.threads.first?.cwd, CodexAppReviewDemo.workspacePath)
        XCTAssertEqual(service.messages(for: CodexAppReviewDemo.threadID).first?.role, .assistant)
    }

    func testDemoTurnAppendsLocalUserAndAssistantMessages() async throws {
        let service = makeService()
        service.startAppReviewDemoSession()

        try await service.startTurn(
            userInput: "please show git status",
            threadId: CodexAppReviewDemo.threadID
        )

        let messages = service.messages(for: CodexAppReviewDemo.threadID)
        XCTAssertEqual(messages.filter { $0.role == .user }.count, 1)
        XCTAssertTrue(messages.contains { $0.role == .assistant && $0.text.contains("Demo Git status") })
        XCTAssertTrue(messages.contains { $0.text.contains("does not connect to a private computer") })
    }

    private func makeService() -> CodexService {
        let suiteName = "CodexAppReviewDemoTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        let service = CodexService(defaults: defaults)
        Self.retainedServices.append(service)
        return service
    }
}
