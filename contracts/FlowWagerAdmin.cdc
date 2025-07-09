// FlowWagerAdmin.cdc
// Purpose: Advanced admin management, resolution tools, and logging for FlowWager

// TODO: Import necessary contracts if type references are external
// import FlowWager from "./FlowWager.cdc"
// import FlowWagerEvents from "./FlowWagerEvents.cdc"

access(all) contract FlowWagerAdmin {

    access(all) enum AdminRole: UInt8 {
        case Deployer      // 0
        case SuperAdmin    // 1
        case ResolveAdmin  // 2
        case CategoryAdmin // 3
        case FeeAdmin      // 4
        case ModeratorAdmin// 5
    }

    access(all) struct Evidence {
        access(all) let url: String
        access(all) let description: String
        access(all) let timestamp: UFix64
        access(all) let submitter: Address
        access(all) let marketId: UInt64

        init(url: String, description: String, submitter: Address, marketId: UInt64) {
            pre {
                url.length > 0 : "Evidence URL cannot be empty."
                // TODO: Consider calling FlowWagerSecurity.validateEvidenceURL(url)
            }
            self.url = url
            self.description = description
            self.timestamp = getCurrentBlock().timestamp
            self.submitter = submitter
            self.marketId = marketId
        }
    }

    access(all) struct AdminAction {
        access(all) let actionId: UInt64
        access(all) let adminAddress: Address
        access(all) let actionType: String
        access(all) let marketId: UInt64?
        access(all) let targetAddress: Address?
        access(all) let timestamp: UFix64
        access(all) let details: {String: String}
        access(all) let success: Bool
        access(all) let reason: String?

        init(actionId: UInt64, adminAddress: Address, actionType: String, timestamp: UFix64, marketId: UInt64?, targetAddress: Address?, details: {String: String}, success: Bool, reason: String?) {
            self.actionId = actionId
            self.adminAddress = adminAddress
            self.actionType = actionType
            self.timestamp = timestamp
            self.marketId = marketId
            self.targetAddress = targetAddress
            self.details = details
            self.success = success
            self.reason = reason
        }
    }

    access(contract) var adminActionsLog: [AdminAction]
    access(contract) var nextAdminActionId: UInt64
    access(contract) var marketEvidenceStore: {UInt64: [Evidence]}

    // Interface for an Admin Capability, expected to be passed for authorized actions.
    // This allows decoupling from the concrete AdminCapability resource if needed.
    access(all) resource interface AdminCapabilityPublic {
        access(all) fun hasPermission(permission: String): Bool
        access(all) fun ownerAddress(): Address
    }

    access(all) fun submitEvidence(
        marketId: UInt64,
        url: String,
        description: String,
        submitterAdminCap: &{AdminCapabilityPublic}
    ): Evidence {
        pre {
            // TODO: Add permission check if "submit_evidence" is a distinct permission
            // submitterAdminCap.hasPermission(permission: "submit_evidence")
            url.length > 0 : "Evidence URL cannot be empty"
            // TODO: Optionally check if market exists and is in a state that accepts evidence
        }

        let newEvidence = Evidence(
            url: url,
            description: description,
            submitter: submitterAdminCap.ownerAddress(),
            marketId: marketId
        )

        if self.marketEvidenceStore[marketId] == nil {
            self.marketEvidenceStore[marketId] = []
        }
        var evidenceList = self.marketEvidenceStore[marketId]!
        evidenceList.append(newEvidence)
        self.marketEvidenceStore[marketId] = evidenceList

        self.logAdminActionInternal(
            adminAddress: submitterAdminCap.ownerAddress(),
            actionType: "submit_evidence",
            marketId: marketId,
            targetAddress: nil,
            details: {"url": url, "description": description},
            success: true,
            reason: nil
        )

        // TODO: Emit an event for evidence submission
        // FlowWagerEvents.emitEvidenceSubmitted(...)
        return newEvidence
    }

    access(all) fun createEvidenceObject(marketId: UInt64, url: String, description: String, submitter: Address): Evidence {
        return Evidence(url: url, description: description, submitter: submitter, marketId: marketId)
    }

    access(all) fun validateEvidence(evidence: Evidence): Bool {
        // Basic URL format check; more robust validation can be in FlowWagerSecurity
        // Assuming String.startsWith is available
        if !evidence.url.startsWith("http://") && !evidence.url.startsWith("https://") {
            log("Evidence validation failed: URL format invalid for evidence related to market ".concat(evidence.marketId.toString()))
            return false
        }
        log("Evidence for market ".concat(evidence.marketId.toString()).concat(" passed basic validation."))
        return true
    }

    access(contract) fun logAdminActionInternal(
        adminAddress: Address,
        actionType: String,
        marketId: UInt64?,
        targetAddress: Address?,
        details: {String: String},
        success: Bool,
        reason: String?
    ) {
        let action = AdminAction(
            actionId: self.nextAdminActionId, adminAddress: adminAddress, actionType: actionType,
            timestamp: getCurrentBlock().timestamp, marketId: marketId, targetAddress: targetAddress,
            details: details, success: success, reason: reason
        )
        self.adminActionsLog.append(action)
        self.nextAdminActionId = self.nextAdminActionId + 1

        // TODO: Emit FlowWagerEvents.AdminActionLogged
    }

    access(all) fun logAdminAction(
        adminCap: &{AdminCapabilityPublic},
        actionType: String,
        marketId: UInt64?,
        targetAddress: Address?,
        details: {String: String},
        success: Bool,
        reason: String?
    ) {
        let adminAddress = adminCap.ownerAddress()

        self.logAdminActionInternal(
            adminAddress: adminAddress, actionType: actionType, marketId: marketId,
            targetAddress: targetAddress, details: details, success: success, reason: reason
        )
    }

    access(all) fun getAdminActions(adminAddress: Address): [AdminAction] {
        let actions: [AdminAction] = []
        for action in self.adminActionsLog {
            if action.adminAddress == adminAddress {
                actions.append(action)
            }
        }
        return actions
    }

    access(all) fun getMarketResolutionHistory(marketId: UInt64): [AdminAction] {
        let actions: [AdminAction] = []
        for action in self.adminActionsLog {
            if action.marketId == marketId &&
               (action.actionType == "resolve_market" || action.actionType == "emergency_resolve_market" || action.actionType == "submit_evidence") {
                actions.append(action)
            }
        }
        return actions
    }

    access(all) fun getSubmittedEvidenceForMarket(marketId: UInt64): [Evidence] {
        return self.marketEvidenceStore[marketId] ?? []
    }

    access(all) fun getAdminPerformance(adminAddress: Address): {String: AnyStruct} {
        // TODO: Implement meaningful admin performance metrics.
        let actionsCount = self.getAdminActions(adminAddress: adminAddress).length
        let performanceReport: {String: AnyStruct} = {
            "adminAddress": adminAddress,
            "totalActionsLogged": UInt64(actionsCount)
            // Add more metrics here
        }
        log("Admin performance report for ".concat(adminAddress.toString()).concat(": Basic implementation."))
        return performanceReport
    }

    init() {
        self.adminActionsLog = []
        self.nextAdminActionId = 1
        self.marketEvidenceStore = {}
        log("FlowWagerAdmin Contract Initialized.")
    }
}
