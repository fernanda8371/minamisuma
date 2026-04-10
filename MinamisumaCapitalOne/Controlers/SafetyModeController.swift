//
//  SafetyModeController.swift
//  MinamisumaCapitalOne
//
//  Cognitive Decline Safety Mode — pattern detection & mode management
//  Syncs caregiver requests via Supabase for cross-device demo
//

import Foundation
import Observation
import Supabase

@Observable
final class SafetyModeController {

    // MARK: - State

    var config: SafetyModeConfig {
        didSet { saveConfig() }
    }
    var behaviorEvents: [BehaviorEvent] = []
    var showSuggestionAlert: Bool = false
    var isCaregiverMode: Bool {
        didSet { UserDefaults.standard.set(isCaregiverMode, forKey: "isCaregiverMode") }
    }

    // Caregiver request system — synced via Supabase
    var pendingRequest: CaregiverRequest?
    var pendingDBRequestId: UUID?
    var hasPendingCaregiverRequest: Bool { pendingRequest != nil }
    var showPendingRequestAlert: Bool = false

    // Active permission level (after client approved)
    var activePermissionLevel: CaregiverPermissionLevel? {
        didSet {
            if let level = activePermissionLevel {
                UserDefaults.standard.set(level.rawValue, forKey: "activePermissionLevel")
            } else {
                UserDefaults.standard.removeObject(forKey: "activePermissionLevel")
            }
        }
    }

    // When in Co-Pilot mode, client needs caregiver approval to change limits
    var hasPendingLimitChangeRequest: Bool {
        didSet { UserDefaults.standard.set(hasPendingLimitChangeRequest, forKey: "pendingLimitChange") }
    }

    // Thresholds for detection
    private let unusualWithdrawalThreshold: Double = 3000.0
    private let repeatedTransferWindow: TimeInterval = 3600
    private let rapidTransactionCount = 3
    private let rapidTransactionWindow: TimeInterval = 300

    private let dbTable = "caregiver_requests"
    private var pollingTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        self.isCaregiverMode = UserDefaults.standard.bool(forKey: "isCaregiverMode")
        self.hasPendingLimitChangeRequest = UserDefaults.standard.bool(forKey: "pendingLimitChange")

        // Load active permission level
        if let levelStr = UserDefaults.standard.string(forKey: "activePermissionLevel"),
           let level = CaregiverPermissionLevel(rawValue: levelStr) {
            self.activePermissionLevel = level
        } else {
            self.activePermissionLevel = nil
        }

        if let data = UserDefaults.standard.data(forKey: "safetyModeConfig"),
           let saved = try? JSONDecoder().decode(SafetyModeConfig.self, from: data) {
            self.config = saved
        } else {
            self.config = .default
        }

        if let eventsData = UserDefaults.standard.data(forKey: "behaviorEvents"),
           let saved = try? JSONDecoder().decode([BehaviorEvent].self, from: eventsData) {
            self.behaviorEvents = saved
        }

        // Fetch any existing pending request from DB
        Task { await fetchPendingRequest() }
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Safety Mode State

    var currentState: SafetyModeState {
        if config.isEnabled {
            return .active(config: config)
        }
        let recentFlags = recentBehaviorEvents(hours: 24)
        if recentFlags.count >= 2 {
            return .suggested(flags: recentFlags)
        }
        return .inactive
    }

    var isActive: Bool { config.isEnabled }

    // MARK: - Activate / Deactivate

    func activateSafetyMode(by activator: String = "user") {
        config.isEnabled = true
        config.requireTransactionApproval = true
        config.notifyTrustedContact = true
        config.activatedAt = Date()
        config.activatedBy = activator
    }

    func deactivateSafetyMode() {
        config.isEnabled = false
        config.requireTransactionApproval = false
        config.notifyTrustedContact = false
        config.activatedAt = nil
        activePermissionLevel = nil

        // Mark the latest approved request as deactivated in Supabase
        // so polling doesn't re-activate it
        Task {
            do {
                let results: [DBCaregiverRequest] = try await SupabaseManager.client
                    .from(dbTable)
                    .select()
                    .eq("status", value: "approved")
                    .order("requested_at", ascending: false)
                    .limit(1)
                    .execute()
                    .value

                if let req = results.first {
                    try await SupabaseManager.client
                        .from(dbTable)
                        .update(["status": "deactivated"])
                        .eq("id", value: req.id.uuidString)
                        .execute()
                }
            } catch {
                print("Supabase deactivate error: \(error)")
            }
        }
    }

    // MARK: - Supabase Caregiver Request Flow

    /// Caregiver sends a request — writes to Supabase DB
    func requestActivationFromCaregiver(permission: CaregiverPermissionLevel, transferLimit: Double? = nil, withdrawalLimit: Double? = nil) {
        let dbRequest = DBCaregiverRequest(
            permissionLevel: permission,
            transferLimit: transferLimit,
            withdrawalLimit: withdrawalLimit
        )

        Task {
            do {
                try await SupabaseManager.client
                    .from(dbTable)
                    .insert(dbRequest)
                    .execute()
                await fetchPendingRequest()
            } catch {
                print("Supabase insert caregiver request error: \(error)")
            }
        }
    }

    /// Fetch the latest request from Supabase (pending, approved, or denied)
    @MainActor
    func fetchPendingRequest() async {
        do {
            // Fetch the most recent request regardless of status
            let results: [DBCaregiverRequest] = try await SupabaseManager.client
                .from(dbTable)
                .select()
                .order("requested_at", ascending: false)
                .limit(1)
                .execute()
                .value

            guard let dbReq = results.first else {
                self.pendingRequest = nil
                self.pendingDBRequestId = nil
                return
            }

            switch dbReq.status {
            case "pending":
                if let local = dbReq.toLocal() {
                    self.pendingRequest = local
                    self.pendingDBRequestId = dbReq.id
                }
            case "approved":
                // Client approved — activate safety mode on caregiver side too
                if !self.isActive || self.pendingDBRequestId == dbReq.id {
                    if let level = CaregiverPermissionLevel(rawValue: dbReq.permissionLevel) {
                        self.activePermissionLevel = level
                        self.config.isEnabled = true
                        self.config.activatedAt = Date()
                        self.config.activatedBy = "caregiver_\(level.rawValue)"
                        if let limit = dbReq.transferLimit {
                            self.config.transferLimit = limit
                        }
                        if let limit = dbReq.withdrawalLimit {
                            self.config.dailyWithdrawalLimit = limit
                        }
                        switch level {
                        case .viewOnly:
                            self.config.notifyTrustedContact = false
                            self.config.requireTransactionApproval = false
                        case .alertsOnly:
                            self.config.notifyTrustedContact = true
                            self.config.requireTransactionApproval = false
                        case .fullCoPilot:
                            self.config.notifyTrustedContact = true
                            self.config.requireTransactionApproval = true
                        }
                    }
                }
                self.pendingRequest = nil
                self.pendingDBRequestId = nil
            case "denied":
                // Client denied — clear pending state
                self.pendingRequest = nil
                self.pendingDBRequestId = nil
            default:
                break
            }
        } catch {
            print("Supabase fetch request error: \(error)")
        }
    }

    /// Client approves — updates DB status to "approved"
    func approveCaregiver() {
        guard let request = pendingRequest else { return }

        activePermissionLevel = request.permissionLevel

        switch request.permissionLevel {
        case .viewOnly:
            config.isEnabled = true
            config.notifyTrustedContact = false
            config.requireTransactionApproval = false
            config.activatedAt = Date()
            config.activatedBy = "caregiver_view"
        case .alertsOnly:
            config.isEnabled = true
            config.notifyTrustedContact = true
            config.requireTransactionApproval = false
            config.activatedAt = Date()
            config.activatedBy = "caregiver_alerts"
        case .fullCoPilot:
            config.isEnabled = true
            config.notifyTrustedContact = true
            config.requireTransactionApproval = true
            if let limit = request.transferLimit {
                config.transferLimit = limit
            }
            if let limit = request.withdrawalLimit {
                config.dailyWithdrawalLimit = limit
            }
            config.activatedAt = Date()
            config.activatedBy = "caregiver_copilot"
        }

        // Update DB status
        if let dbId = pendingDBRequestId {
            Task {
                do {
                    try await SupabaseManager.client
                        .from(dbTable)
                        .update(["status": "approved", "responded_at": ISO8601DateFormatter().string(from: Date())])
                        .eq("id", value: dbId.uuidString)
                        .execute()
                } catch {
                    print("Supabase approve error: \(error)")
                }
            }
        }

        pendingRequest = nil
        pendingDBRequestId = nil
    }

    /// Client denies — updates DB status to "denied"
    func denyCaregiver() {
        if let dbId = pendingDBRequestId {
            Task {
                do {
                    try await SupabaseManager.client
                        .from(dbTable)
                        .update(["status": "denied", "responded_at": ISO8601DateFormatter().string(from: Date())])
                        .eq("id", value: dbId.uuidString)
                        .execute()
                } catch {
                    print("Supabase deny error: \(error)")
                }
            }
        }
        pendingRequest = nil
        pendingDBRequestId = nil
    }

    /// Whether the client can edit limits (blocked in Co-Pilot mode)
    var clientCanEditLimits: Bool {
        activePermissionLevel != .fullCoPilot
    }

    // MARK: - Polling (for cross-device sync)

    /// Start polling Supabase every few seconds — call when view appears
    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.fetchPendingRequest()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    /// Stop polling — call when view disappears
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func updateTransferLimit(_ limit: Double) {
        config.transferLimit = limit
    }

    func updateDailyWithdrawalLimit(_ limit: Double) {
        config.dailyWithdrawalLimit = limit
    }

    // MARK: - Behavior Detection

    func trackWithdrawal(amount: Double) {
        if amount > unusualWithdrawalThreshold {
            let event = BehaviorEvent(
                flag: .unusualWithdrawal,
                detail: "Retiro de $\(Int(amount)) detectado — superior al limite habitual",
                amount: amount
            )
            addEvent(event)
        }
        checkForRapidTransactions(amount: amount)
    }

    func trackTransfer(to recipient: String, amount: Double) {
        let recentTransfers = behaviorEvents.filter {
            $0.flag == .repeatedTransfer &&
            $0.timestamp.timeIntervalSinceNow > -repeatedTransferWindow
        }
        if recentTransfers.count >= 2 {
            let event = BehaviorEvent(
                flag: .repeatedTransfer,
                detail: "Transferencia repetida a \(recipient) por $\(Int(amount))",
                amount: amount
            )
            addEvent(event)
        }

        if amount > unusualWithdrawalThreshold {
            let event = BehaviorEvent(
                flag: .largeUnusualPurchase,
                detail: "Transferencia grande de $\(Int(amount)) a \(recipient)",
                amount: amount
            )
            addEvent(event)
        }

        checkForRapidTransactions(amount: amount)
    }

    func isTransferAllowed(amount: Double) -> Bool {
        guard config.isEnabled else { return true }
        return amount <= config.transferLimit
    }

    func isWithdrawalAllowed(amount: Double) -> Bool {
        guard config.isEnabled else { return true }
        return amount <= config.dailyWithdrawalLimit
    }

    // MARK: - Simulate Patterns (for demo)

    func simulateUnusualBehavior() {
        let events: [BehaviorEvent] = [
            BehaviorEvent(
                flag: .unusualWithdrawal,
                detail: "Retiro inusual de $4,500 en cajero desconocido",
                amount: 4500
            ),
            BehaviorEvent(
                flag: .repeatedTransfer,
                detail: "Misma transferencia de $800 enviada 3 veces en 1 hora",
                amount: 800
            ),
            BehaviorEvent(
                flag: .confusionPattern,
                detail: "Se iniciaron y cancelaron 5 operaciones en 10 minutos"
            )
        ]

        for event in events {
            addEvent(event)
        }
        showSuggestionAlert = true
    }

    // MARK: - Private Helpers

    private func addEvent(_ event: BehaviorEvent) {
        behaviorEvents.append(event)
        saveEvents()

        let recentFlags = recentBehaviorEvents(hours: 24)
        if recentFlags.count >= 2 && !config.isEnabled {
            showSuggestionAlert = true
        }
    }

    private func checkForRapidTransactions(amount: Double) {
        let recent = behaviorEvents.filter {
            $0.timestamp.timeIntervalSinceNow > -rapidTransactionWindow
        }
        if recent.count >= rapidTransactionCount {
            let event = BehaviorEvent(
                flag: .rapidSuccessiveTransactions,
                detail: "\(recent.count + 1) transacciones en menos de 5 minutos",
                amount: amount
            )
            behaviorEvents.append(event)
            saveEvents()
        }
    }

    private func recentBehaviorEvents(hours: Int) -> [BehaviorEvent] {
        let cutoff = Date().addingTimeInterval(-Double(hours) * 3600)
        return behaviorEvents.filter { $0.timestamp > cutoff }
    }

    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "safetyModeConfig")
        }
    }

    private func saveEvents() {
        if let data = try? JSONEncoder().encode(behaviorEvents) {
            UserDefaults.standard.set(data, forKey: "behaviorEvents")
        }
    }

    func clearEvents() {
        behaviorEvents.removeAll()
        saveEvents()
    }
}
