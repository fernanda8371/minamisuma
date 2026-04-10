//
//  SafetyModeController.swift
//  MinamisumaCapitalOne
//
//  Cognitive Decline Safety Mode — pattern detection & mode management
//

import Foundation
import Observation

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
    
    // Caregiver request system — caregiver requests, client must approve
    var pendingRequest: CaregiverRequest? {
        didSet { savePendingRequest() }
    }
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
    private let repeatedTransferWindow: TimeInterval = 3600 // 1 hour
    private let rapidTransactionCount = 3
    private let rapidTransactionWindow: TimeInterval = 300 // 5 minutes
    
    // MARK: - Init
    
    init() {
        self.isCaregiverMode = UserDefaults.standard.bool(forKey: "isCaregiverMode")
        self.hasPendingLimitChangeRequest = UserDefaults.standard.bool(forKey: "pendingLimitChange")
        
        // Load pending request
        if let reqData = UserDefaults.standard.data(forKey: "pendingCaregiverRequest"),
           let saved = try? JSONDecoder().decode(CaregiverRequest.self, from: reqData) {
            self.pendingRequest = saved
        } else {
            self.pendingRequest = nil
        }
        
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
    }
    
    // MARK: - Caregiver Request Flow
    
    /// Caregiver requests activation with a specific permission level
    func requestActivationFromCaregiver(permission: CaregiverPermissionLevel, transferLimit: Double? = nil, withdrawalLimit: Double? = nil) {
        pendingRequest = CaregiverRequest(
            permissionLevel: permission,
            transferLimit: transferLimit,
            withdrawalLimit: withdrawalLimit
        )
    }
    
    /// Client approves the caregiver's request
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
        
        pendingRequest = nil
    }
    
    /// Client denies the caregiver's request
    func denyCaregiver() {
        pendingRequest = nil
    }
    
    /// Whether the client can edit limits (blocked in Co-Pilot mode)
    var clientCanEditLimits: Bool {
        activePermissionLevel != .fullCoPilot
    }
    
    private func savePendingRequest() {
        if let request = pendingRequest,
           let data = try? JSONEncoder().encode(request) {
            UserDefaults.standard.set(data, forKey: "pendingCaregiverRequest")
        } else {
            UserDefaults.standard.removeObject(forKey: "pendingCaregiverRequest")
        }
    }
    
    func updateTransferLimit(_ limit: Double) {
        config.transferLimit = limit
    }
    
    func updateDailyWithdrawalLimit(_ limit: Double) {
        config.dailyWithdrawalLimit = limit
    }
    
    // MARK: - Behavior Detection
    
    /// Call when a withdrawal is made
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
    
    /// Call when a transfer is made
    func trackTransfer(to recipient: String, amount: Double) {
        // Check for repeated transfers
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
    
    /// Check if transaction exceeds safety mode limits
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
