// FlowWagerAdmin.cdc
// Purpose: Advanced admin management, resolution tools, and logging for FlowWager

// Import other contracts if necessary
// import FlowWager from "./FlowWager.cdc" // For admin checks, market data
// import FlowWagerEvents from "./FlowWagerEvents.cdc" // For emitting admin-related events

pub contract FlowWagerAdmin {

    // ADMIN ROLES
    // These roles can be used to define granular permissions within AdminCapability in FlowWager.cdc
    // Or, this contract can manage roles which then map to sets of permissions.
    // The prompt for FlowWager.cdc uses `permissions: [String]`, which is flexible.
    // These enums can serve as standardized strings for those permissions.
    pub enum AdminRole: UInt8 {
        case Deployer      // 0 - Full control, typically implicit "all" permission
        case SuperAdmin    // 1 - Broad operational control (e.g., manage_system_state, manage_admins)
        case ResolveAdmin  // 2 - Can resolve markets (general or category-specific)
        case CategoryAdmin // 3 - Category-specific resolution (may need category field in AdminCapability)
        case FeeAdmin      // 4 - Can manage fee withdrawals
        case ModeratorAdmin// 5 - Limited permissions (e.g., pause markets, manage content)
        // Add more roles as needed
    }

    // RESOLUTION EVIDENCE
    // This struct defines the structure for evidence submitted during market resolution.
    pub struct Evidence {
        pub let url: String
        pub let description: String // Optional description or context for the URL
        pub let timestamp: UFix64   // Submission time of this piece of evidence
        pub let submitter: Address  // Address of the admin/user who submitted this evidence
        pub let marketId: UInt64    // Market this evidence pertains to
        // pub let category: UInt8 // Category of the market, if relevant for evidence context (from prompt)
                                // This might be redundant if marketId is present, as category can be fetched from market.

        init(url: String, description: String, submitter: Address, marketId: UInt64, /* category: UInt8 */ ) {
            // Basic validation for evidence fields
            // More robust URL validation could be in FlowWagerSecurity
            pre {
                url.length > 0 : "Evidence URL cannot be empty."
                // description can be empty if allowed
                // FlowWagerSecurity.validateEvidenceURL(url) // Ideally
            }
            self.url = url
            self.description = description
            self.timestamp = getCurrentBlock().timestamp
            self.submitter = submitter
            self.marketId = marketId
            // self.category = category
        }
    }

    // ADMIN ACTIONS LOG
    // Structure for logging actions performed by admins for auditability.
    pub struct AdminAction {
        pub let actionId: UInt64 // Unique ID for the log entry
        pub let adminAddress: Address
        pub let actionType: String   // e.g., "resolve_market", "add_admin", "pause_market"
        pub let marketId: UInt64?  // Optional, if the action is market-specific
        pub let targetAddress: Address? // Optional, if action targets another user/admin
        pub let timestamp: UFix64
        pub let details: {String: String} // Using String:String for simplicity as AnyStruct is not directly storable in arrays/dictionaries for events if not careful.
                                         // If complex details needed, consider serializing to JSON string or specific structs.
        pub let success: Bool // Was the action successful?
        pub let reason: String? // Reason for failure or additional notes

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

    // --- Contract State for Logging ---
    // These logs could grow large. Consider strategies for managing storage if this becomes an issue (e.g., archiving, off-chain indexing).
    access(contract) var adminActionsLog: [AdminAction]
    access(contract) var nextAdminActionId: UInt64

    // Storage for evidence submitted for markets. MarketID -> [Evidence]
    // This could also become large.
    access(contract) var marketEvidenceStore: {UInt64: [Evidence]}

    // --- Functions ---

    // Function to create and store an Evidence struct.
    // This would typically be called by an admin when resolving a market or as part of an evidence submission process.
    pub fun submitEvidence(
        marketId: UInt64,
        url: String,
        description: String,
        submitterAdminCap: &{FlowWager.AdminCapabilityPublic} // Requires admin capability
        // category: UInt8 // from prompt, but redundant if marketId is there
    ): Evidence {
        pre {
            // submitterAdminCap.hasPermission(permission: "submit_evidence") // Or part of "resolve_market"
            url.length > 0 : "Evidence URL cannot be empty" // Basic check
            // Potentially check if market exists and is in a state that accepts evidence
            // let market = FlowWager.getMarket(marketId: marketId) ?? panic("Market not found")
            // assert(market.status == FlowWager.MarketStatus.PendingResolution, message: "Market not in state to accept evidence")
        }

        // let marketInfo = FlowWager.getMarket(marketId: marketId) // To get category if needed
        // let actualCategory = marketInfo?["category"] as? UInt8 ?? panic("Could not get market category")
        // if category != actualCategory { panic("Provided category does not match market's category") }

        let newEvidence = Evidence(
            url: url,
            description: description,
            submitter: submitterAdminCap.ownerAddress(), // Assuming AdminCapabilityPublic has ownerAddress()
            marketId: marketId
            // category: category
        )

        if self.marketEvidenceStore[marketId] == nil {
            self.marketEvidenceStore[marketId] = []
        }
        self.marketEvidenceStore[marketId]!.append(newEvidence)

        // Log this action as well
        self.logAdminActionInternal(
            adminAddress: submitterAdminCap.ownerAddress(),
            actionType: "submit_evidence",
            marketId: marketId,
            targetAddress: nil,
            details: {"url": url, "description": description},
            success: true,
            reason: nil
        )

        // Emit an event for evidence submission if needed
        // FlowWagerEvents.emitEvidenceSubmitted(evidenceId: ..., marketId: marketId, ...)

        return newEvidence
    }

    // The prompt's `createEvidence` seems to be a factory, not necessarily storing it.
    // The one above `submitEvidence` creates and stores. If a pure factory is needed:
    pub fun createEvidenceObject(marketId: UInt64, url: String, description: String, submitter: Address /*, category: UInt8 */): Evidence {
        return Evidence(url: url, description: description, submitter: submitter, marketId: marketId /*, category: category */)
    }


    // Validate evidence - This function's utility depends on what "validation" means.
    // If it means checking URL format, FlowWagerSecurity.validateEvidenceURL is better.
    // If it means an admin "approves" a piece of evidence, that's a different process.
    // The prompt's version takes an Evidence struct.
    pub fun validateEvidence(evidence: Evidence): Bool {
        // This could check against a set of rules, e.g., is the submitter a valid admin for this market?
        // Is the URL format correct (can use FlowWagerSecurity.validateEvidenceURL)?
        // Is the evidence relevant to the market's category or options? (complex logic)

        // Example: Basic URL format check using a helper (if FlowWagerSecurity is not imported)
        if !evidence.url.startsWith("http://") && !evidence.url.startsWith("https://") {
            log("Evidence validation failed: URL format invalid for evidence related to market ".concat(evidence.marketId.toString()))
            return false
        }
        // Further checks are application-specific.
        // For now, this is a simple validation.
        log("Evidence for market ".concat(evidence.marketId.toString()).concat(" passed basic validation."))
        return true
    }

    // Internal function to log admin actions, callable by other functions in FlowWager ecosystem.
    // The public `logAdminAction` is also available if direct logging is needed.
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
            actionId: self.nextAdminActionId,
            adminAddress: adminAddress,
            actionType: actionType,
            timestamp: getCurrentBlock().timestamp,
            marketId: marketId,
            targetAddress: targetAddress,
            details: details,
            success: success,
            reason: reason
        )
        self.adminActionsLog.append(action)
        self.nextAdminActionId = self.nextAdminActionId + 1

        // Emit the generic AdminActionLogged event from FlowWagerEvents
        // FlowWagerEvents.emitAdminActionLogged(
        //    adminAddress: adminAddress,
        //    action: actionType,
        //    marketId: marketId,
        //    targetAddress: targetAddress, // Event needs to support this
        //    details: details, // Event needs to support this
        //    timestamp: action.timestamp
        // )
    }

    // Public function to allow explicit logging of an admin action.
    // Requires admin capability to ensure only admins (or the system on their behalf) can log.
    pub fun logAdminAction(
        adminCap: &{FlowWager.AdminCapabilityPublic}, // The admin performing the action or authorizing the log
        actionType: String,
        marketId: UInt64?,
        targetAddress: Address?,
        details: {String: String},
        success: Bool,
        reason: String?
    ) {
        // No specific permission check here, as any admin might need to log an action they performed.
        // The capability itself proves they are an admin.
        let adminAddress = adminCap.ownerAddress() // Assuming this method exists

        self.logAdminActionInternal(
            adminAddress: adminAddress,
            actionType: actionType,
            marketId: marketId,
            targetAddress: targetAddress,
            details: details,
            success: success,
            reason: reason
        )
    }

    pub fun getAdminActions(adminAddress: Address): [AdminAction] {
        let actions: [AdminAction] = []
        for action in self.adminActionsLog {
            if action.adminAddress == adminAddress {
                actions.append(action)
            }
        }
        return actions // Could be very large, consider pagination in practice for script calls
    }

    pub fun getMarketResolutionHistory(marketId: UInt64): [AdminAction] {
        let actions: [AdminAction] = []
        for action in self.adminActionsLog {
            if action.marketId == marketId && (action.actionType == "resolve_market" || action.actionType == "emergency_resolve_market" || action.actionType == "submit_evidence") {
                actions.append(action)
            }
        }
        return actions // Could be large
    }

    pub fun getSubmittedEvidenceForMarket(marketId: UInt64): [Evidence] {
        return self.marketEvidenceStore[marketId] ?? []
    }

    // Placeholder for admin performance metrics.
    // This would require defining what "performance" means (e.g., resolution speed, accuracy, disputes handled).
    // Likely involves more complex data aggregation, possibly off-chain or via another analytics contract.
    pub fun getAdminPerformance(adminAddress: Address): {String: AnyStruct} {
        // Example metrics (would need data to calculate these):
        // - Markets resolved: Count
        // - Average resolution time: UFix64
        // - Disputes related to resolutions: Count (if disputes are tracked)
        // - Actions logged: Count

        let actionsCount = self.getAdminActions(adminAddress: adminAddress).length

        // These are just illustrative. True performance metrics are more involved.
        let performanceReport: {String: AnyStruct} = {
            "adminAddress": adminAddress,
            "totalActionsLogged": UInt64(actionsCount),
            "placeholder_metric_1": "Value for metric 1 (e.g., markets resolved)",
            "placeholder_metric_2": "Value for metric 2 (e.g., avg resolution time)"
        }
        log("Admin performance report for ".concat(adminAddress.toString()).concat(": Not yet implemented in detail."))
        return performanceReport
    }

    // --- Initialization ---
    init() {
        self.adminActionsLog = []
        self.nextAdminActionId = 1
        self.marketEvidenceStore = {}
        log("FlowWagerAdmin Contract Initialized.")
    }

    // Helper interface for FlowWager.AdminCapability if needed for function signatures
    // This should align with the actual AdminCapability in FlowWager.cdc
    pub resource interface AdminCapabilityPublic {
        pub fun hasPermission(permission: String): Bool
        pub fun ownerAddress(): Address // Added this assumption
    }
}
