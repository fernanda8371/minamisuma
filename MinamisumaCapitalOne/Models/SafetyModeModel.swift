//
//  SafetyModeModel.swift
//  MinamisumaCapitalOne
//
//  Cognitive Decline Safety Mode — behavior pattern models
//

import Foundation
import SwiftUI

// MARK: - Behavior Flag Type

enum BehaviorFlag: String, Codable, Identifiable {
    case unusualWithdrawal = "Unusual Withdrawal"
    case repeatedTransfer = "Repeated Transfer"
    case confusionPattern = "Confusion Pattern"
    case largeUnusualPurchase = "Large Unusual Purchase"
    case rapidSuccessiveTransactions = "Rapid Successive Transactions"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .unusualWithdrawal: return "exclamationmark.triangle.fill"
        case .repeatedTransfer: return "arrow.triangle.2.circlepath"
        case .confusionPattern: return "questionmark.circle.fill"
        case .largeUnusualPurchase: return "cart.fill.badge.questionmark"
        case .rapidSuccessiveTransactions: return "bolt.fill"
        }
    }
    
    var description: String {
        switch self {
        case .unusualWithdrawal:
            return "Se detectaron retiros fuera de lo habitual"
        case .repeatedTransfer:
            return "La misma transferencia se repitio varias veces"
        case .confusionPattern:
            return "Se detectaron acciones repetidas o canceladas frecuentemente"
        case .largeUnusualPurchase:
            return "Una compra grande fuera del patron normal"
        case .rapidSuccessiveTransactions:
            return "Multiples transacciones en poco tiempo"
        }
    }
}

// MARK: - Safety Mode Configuration

struct SafetyModeConfig: Codable {
    var isEnabled: Bool
    var requireTransactionApproval: Bool
    var notifyTrustedContact: Bool
    var transferLimit: Double
    var dailyWithdrawalLimit: Double
    var activatedAt: Date?
    var activatedBy: String // "user", "caregiver", "system_suggestion"
    
    static let `default` = SafetyModeConfig(
        isEnabled: false,
        requireTransactionApproval: false,
        notifyTrustedContact: false,
        transferLimit: 5000.0,
        dailyWithdrawalLimit: 2000.0,
        activatedAt: nil,
        activatedBy: "user"
    )
}

// MARK: - Behavior Event (tracked locally)

struct BehaviorEvent: Identifiable, Codable {
    let id: UUID
    let flag: BehaviorFlag
    let timestamp: Date
    let detail: String
    let amount: Double?
    
    init(flag: BehaviorFlag, detail: String, amount: Double? = nil) {
        self.id = UUID()
        self.flag = flag
        self.timestamp = Date()
        self.detail = detail
        self.amount = amount
    }
}

// MARK: - Caregiver Permission Level

enum CaregiverPermissionLevel: String, Codable, CaseIterable, Identifiable {
    case viewOnly = "Solo ver movimientos"
    case alertsOnly = "Ver movimientos y recibir alertas"
    case fullCoPilot = "Co-Pilot completo"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .viewOnly: return "eye.fill"
        case .alertsOnly: return "bell.badge.fill"
        case .fullCoPilot: return "shield.checkered"
        }
    }
    
    var color: Color {
        switch self {
        case .viewOnly: return .brandBlue
        case .alertsOnly: return .statusOrange
        case .fullCoPilot: return .permCoPilot
        }
    }
    
    var clientDescription: String {
        switch self {
        case .viewOnly:
            return "Tu cuidador podra ver tus movimientos bancarios. No tendra control sobre tu cuenta."
        case .alertsOnly:
            return "Tu cuidador podra ver tus movimientos y recibira alertas cuando se detecte actividad inusual."
        case .fullCoPilot:
            return "Tu cuidador podra ver movimientos, recibir alertas, y establecer limites de transferencia y retiro. No podras modificar los limites sin su aprobacion."
        }
    }
    
    var permissions: [String] {
        switch self {
        case .viewOnly:
            return [
                "Ver todos tus movimientos",
                "Ver tu balance"
            ]
        case .alertsOnly:
            return [
                "Ver todos tus movimientos",
                "Ver tu balance",
                "Recibir alertas de actividad inusual",
                "Recibir alertas de transacciones grandes"
            ]
        case .fullCoPilot:
            return [
                "Ver todos tus movimientos",
                "Ver tu balance",
                "Recibir alertas de actividad inusual",
                "Establecer limite de transferencias",
                "Establecer limite de retiros diarios",
                "Bloquear transacciones que excedan limites"
            ]
        }
    }
}

// MARK: - Caregiver Request (local)

struct CaregiverRequest: Codable {
    var permissionLevel: CaregiverPermissionLevel
    var transferLimit: Double?
    var withdrawalLimit: Double?
    var requestedAt: Date

    init(permissionLevel: CaregiverPermissionLevel, transferLimit: Double? = nil, withdrawalLimit: Double? = nil) {
        self.permissionLevel = permissionLevel
        self.transferLimit = transferLimit
        self.withdrawalLimit = withdrawalLimit
        self.requestedAt = Date()
    }
}

// MARK: - Caregiver Request (Supabase DB)

struct DBCaregiverRequest: Codable, Identifiable {
    var id: UUID
    var permissionLevel: String
    var transferLimit: Double?
    var withdrawalLimit: Double?
    var status: String // "pending", "approved", "denied"
    var requestedAt: Date?
    var respondedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case permissionLevel = "permission_level"
        case transferLimit = "transfer_limit"
        case withdrawalLimit = "withdrawal_limit"
        case status
        case requestedAt = "requested_at"
        case respondedAt = "responded_at"
    }

    init(permissionLevel: CaregiverPermissionLevel, transferLimit: Double? = nil, withdrawalLimit: Double? = nil) {
        self.id = UUID()
        self.permissionLevel = permissionLevel.rawValue
        self.transferLimit = transferLimit
        self.withdrawalLimit = withdrawalLimit
        self.status = "pending"
        self.requestedAt = Date()
        self.respondedAt = nil
    }

    /// Convert to local CaregiverRequest
    func toLocal() -> CaregiverRequest? {
        guard let level = CaregiverPermissionLevel(rawValue: permissionLevel) else { return nil }
        return CaregiverRequest(
            permissionLevel: level,
            transferLimit: transferLimit,
            withdrawalLimit: withdrawalLimit
        )
    }
}

// MARK: - Safety Mode State

enum SafetyModeState {
    case inactive
    case suggested(flags: [BehaviorEvent])
    case active(config: SafetyModeConfig)
}
