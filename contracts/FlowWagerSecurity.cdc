// FlowWagerSecurity.cdc
// Purpose: Security validation and protection mechanisms for FlowWager

// Import other contracts if necessary, e.g., for accessing admin lists or market states
// import FlowWager from "./FlowWager.cdc" // Avoid circular dependencies if possible.
// It's often better if security functions are pure or take necessary state as arguments.

pub contract FlowWagerSecurity {

    // SECURITY CONSTANTS - Values to be determined and configured
    // These could also be configurable variables set by an admin if needed.
    pub let MAX_BET_AMOUNT: UFix64
    pub let MIN_BET_AMOUNT: UFix64
    pub let MAX_MARKETS_PER_USER_PER_DAY: UInt64 // Requires tracking market creation timestamps and user activity
    pub let ADMIN_ACTION_COOLDOWN: UFix64 // Cooldown period in seconds for certain admin actions by the same admin

    // State for rate limiting and cooldowns - This implies storage, making the contract non-trivial.
    // If FlowWagerSecurity is purely for validation functions, this state would live elsewhere (e.g. FlowWager contract).
    // The prompt lists these under FlowWagerSecurity, so I'll include structures for them.
    access(contract) var userMarketCreationTimestamps: {Address: [UFix64]} // Stores timestamps of market creations by user
    access(contract) var lastAdminActionTimestamp: {Address: {String: UFix64}} // AdminAddr -> ActionName -> Timestamp

    // --- Validation Functions ---

    pub fun validateMarketTitle(title: String): Bool {
        // Basic validation: not empty, reasonable length.
        // Could add profanity filters or other checks if an oracle/service is available.
        if title.length == 0 {
            // panic("Market title cannot be empty.") // Or return false
            return false
        }
        if title.length > 150 { // Arbitrary max length
            // panic("Market title is too long.")
            return false
        }
        // Add more sophisticated checks if needed (e.g., regex for allowed characters)
        return true
    }

    pub fun validateMarketDescription(description: String): Bool {
        if description.length == 0 {
            // panic("Market description cannot be empty.")
            return false
        }
        if description.length > 2000 { // Arbitrary max length
            // panic("Market description is too long.")
            return false
        }
        return true
    }

    pub fun validateMarketDuration(startTime: UFix64, endTime: UFix64, minDuration: UFix64, maxDuration: UFix64): Bool {
        if endTime <= startTime {
            // panic("End time must be after start time.")
            return false
        }
        let duration = endTime - startTime
        if duration < minDuration {
            // panic("Market duration is less than the minimum allowed.")
            return false
        }
        if duration > maxDuration {
            // panic("Market duration is greater than the maximum allowed.")
            return false
        }
        // Could also check if startTime is not too far in the past or future.
        // if startTime < getCurrentBlock().timestamp - 300.0 { // e.g. not older than 5 mins
        //     // panic("Start time is too far in the past.")
        //     return false
        // }
        return true
    }

    pub fun validateBetAmount(amount: UFix64): Bool {
        if amount < self.MIN_BET_AMOUNT {
            // panic("Bet amount is less than the minimum allowed.")
            return false
        }
        if amount > self.MAX_BET_AMOUNT {
            // panic("Bet amount exceeds the maximum allowed.")
            return false
        }
        return true
    }

    pub fun validateEvidenceURL(url: String): Bool {
        // Basic check for non-empty and potentially a simple prefix check.
        // True URL validation is complex and usually handled off-chain or by oracle.
        if url.length == 0 {
            // panic("Evidence URL cannot be empty.")
            return false
        }
        if !url.startsWith("http://") && !url.startsWith("https://") {
            // panic("Evidence URL must be a valid HTTP or HTTPS link.")
            return false
        }
        if url.length > 512 { // Max length for URL
             // panic("Evidence URL is too long.")
            return false
        }
        // Further validation (e.g., accessibility) would require an oracle.
        return true
    }

    // This function would need access to the admin list and their permissions,
    // potentially from the FlowWager contract or passed in.
    // If FlowWagerSecurity is separate, it can't directly access FlowWager's private state.
    // Option 1: Pass admin capabilities or a reference.
    // Option 2: FlowWager calls this with necessary info.
    // For now, let's assume it's a helper that might be called by FlowWager,
    // or FlowWager provides a way to query admin permissions.
    // The prompt implies `admin: Address`, so it needs to look up permissions for that Address.
    // This means FlowWagerSecurity needs a way to see FlowWager's admin setup.
    // This is a structural consideration. For now, I'll write its signature as per prompt.
    pub fun validateAdminPermissions(
        adminAddress: Address,
        action: String,
        // This would require a way to get the admin's capabilities/permissions.
        // E.g., by borrowing a reference to FlowWager.AdminCapability or similar.
        // For simplicity, let's assume this function is called by FlowWager, which supplies the capability.
        adminCap: &{FlowWager.AdminCapabilityPublic} // Assuming a public interface for AdminCapability
    ): Bool {
        // This function is somewhat redundant if the AdminCapability resource itself has `hasPermission`.
        // However, it can centralize the logic or add more layers.
        // if !FlowWager.isAdmin(address: adminAddress) { // This call would require import and public visibility
        //     panic("Address is not a recognized admin.")
        //     return false
        // }
        if !adminCap.hasPermission(permission: action) {
            // panic("Admin does not have the required permission for this action.")
            return false
        }
        return true
    }
    // NOTE: The AdminCapability resource in FlowWager.cdc already has `hasPermission`.
    // So, `FlowWager.AdminCapability.hasPermission(action)` is the direct way.
    // This validateAdminPermissions function might be intended for a different type of check,
    // or it's a layer on top. Given the prompt, I'll keep it, assuming it might evolve.


    // --- Security Checks (potentially stateful) ---

    // Requires state: `userMarketCreationTimestamps`
    pub fun checkRateLimitMarketCreation(user: Address, currentTime: UFix64): Bool {
        let oneDayAgo = currentTime - 86400.0 // 24 hours in seconds

        // Clean up old timestamps for the user
        var validTimestamps: [UFix64] = []
        if let timestamps = self.userMarketCreationTimestamps[user] {
            for ts in timestamps {
                if ts >= oneDayAgo {
                    validTimestamps.append(ts)
                }
            }
        }

        if UInt64(validTimestamps.length) >= self.MAX_MARKETS_PER_USER_PER_DAY {
            // panic("User has exceeded the maximum number of markets they can create per day.")
            self.userMarketCreationTimestamps[user] = validTimestamps // Save cleaned list
            return false
        }

        // Add current timestamp and save
        validTimestamps.append(currentTime)
        self.userMarketCreationTimestamps[user] = validTimestamps
        return true
    }

    // Generic rate limit check - could be expanded
    pub fun checkRateLimit(user: Address, action: String, currentTime: UFix64): Bool {
        // This is a generic placeholder. Specific actions need specific rate limit logic.
        // For market creation, use `checkRateLimitMarketCreation`.
        if action == "create_market" {
            return self.checkRateLimitMarketCreation(user: user, currentTime: currentTime)
        }
        // Add other action-specific rate limits here
        // e.g., limit on number of bets per minute, etc.
        return true // Default to true if no specific limit for the action
    }

    // Placeholder for more complex suspicious activity detection.
    // This would likely involve analyzing patterns of behavior, possibly off-chain or with oracles.
    pub fun checkSuspiciousActivity(user: Address): Bool {
        // Example: Check for very rapid succession of bets, or bets from known malicious addresses.
        // This is highly dependent on available data and heuristics.
        // For an on-chain contract, this would be quite limited.
        log("Suspicious activity check for user ".concat(user.toString()).concat(": Not yet implemented in detail."))
        return true // Default to not suspicious for now
    }

    // Requires state: `lastAdminActionTimestamp`
    pub fun checkAdminCooldown(admin: Address, action: String, currentTime: UFix64): Bool {
        if let adminActions = self.lastAdminActionTimestamp[admin] {
            if let lastActionTime = adminActions[action] {
                if currentTime < lastActionTime + self.ADMIN_ACTION_COOLDOWN {
                    // panic("Admin action is on cooldown for this admin and action type.")
                    return false
                }
            }
        }
        // Update the timestamp for this admin and action
        if self.lastAdminActionTimestamp[admin] == nil {
            self.lastAdminActionTimestamp[admin] = {}
        }
        self.lastAdminActionTimestamp[admin]![action] = currentTime
        return true
    }

    // Placeholder for market integrity checks.
    // This could involve checking consistency of market data, pool sizes, etc.
    // Needs access to the market data (e.g., from FlowWager contract).
    pub fun checkMarketIntegrity(
        marketId: UInt64
        // market: &FlowWager.Market // Needs a way to access market resource or its data
    ): Bool {
        // Example: Ensure total pool matches sum of individual option pools.
        // Ensure participant count seems reasonable for total bets etc.
        // This is highly dependent on what data is available and what defines "integrity".
        // If market data is passed or accessible:
        // if market.totalPool != market.pools.values.reduce(0.0, fun(a: UFix64, b: UFix64): UFix64 { return a + b }) {
        //     panic("Market integrity check failed: totalPool mismatch.")
        //     return false
        // }
        log("Market integrity check for market ".concat(marketId.toString()).concat(": Not yet implemented in detail."))
        return true // Default to true
    }


    // --- Emergency Functions ---
    // These functions imply that FlowWagerSecurity has admin privileges itself,
    // or is called by an admin of FlowWager contract.
    // The prompt implies these are part of FlowWagerSecurity.
    // This suggests FlowWagerSecurity might need its own admin capability or a link to FlowWager's admin system.

    // For these functions to modify state in FlowWager (e.g. pause a market),
    // FlowWagerSecurity needs either:
    // 1. Its own powerful capabilities over FlowWager.
    // 2. To be called by transactions that also provide FlowWager admin capabilities.
    // 3. FlowWager exposes specific functions that FlowWagerSecurity (if authorized) can call.

    // Let's assume these are called by an authorized admin, and this contract provides the logic,
    // but the actual state change happens in FlowWager.cdc, invoked by these.
    // This means these functions might need to take an admin capability for FlowWager as a parameter.

    access(contract) var isEmergencyModeActive: Bool
    access(contract) var emergencyModeReason: String?
    // `pausedMarkets` would ideally live in FlowWager.cdc, associated with the Market resource or main contract state.
    // If FlowWagerSecurity manages this, it needs a way to enforce it on FlowWager operations.
    access(contract) var pausedMarkets: {UInt64: String} // MarketID -> Reason

    // These functions should emit events (defined in FlowWagerEvents)

    pub fun enableEmergencyMode(reason: String, adminCap: &{FlowWager.AdminCapabilityPublic}) {
        // Requires an admin with permission to enable emergency mode.
        // This permission should be defined (e.g., "manage_emergency_mode").
        // For now, assuming a generic high-level admin.
        // FlowWager.validateAdminPermissions(admin: adminCap.owner.address, action: "manage_emergency_mode", adminCap: adminCap)
        pre {
            adminCap.hasPermission(permission: "manage_system_state"): "Admin lacks permission for emergency mode." // Example permission
            reason.length > 0 : "Reason for enabling emergency mode must be provided."
        }

        self.isEmergencyModeActive = true
        self.emergencyModeReason = reason
        log("Emergency Mode ENABLED. Reason: ".concat(reason))
        // Emit FlowWagerEvents.EmergencyModeEnabled
    }

    pub fun disableEmergencyMode(adminCap: &{FlowWager.AdminCapabilityPublic}) {
        pre {
            adminCap.hasPermission(permission: "manage_system_state"): "Admin lacks permission for emergency mode."
        }
        self.isEmergencyModeActive = false
        self.emergencyModeReason = nil
        log("Emergency Mode DISABLED.")
        // Emit FlowWagerEvents.EmergencyModeDisabled
    }

    pub fun pauseMarket(marketId: UInt64, reason: String, adminCap: &{FlowWager.AdminCapabilityPublic}) {
        // This function marks a market as paused within FlowWagerSecurity's state.
        // The FlowWager contract would need to check this status before allowing actions on the market.
        pre {
            adminCap.hasPermission(permission: "pause_market"): "Admin lacks permission to pause markets." // Example permission
            reason.length > 0 : "Reason for pausing market must be provided."
            // Check if market exists in FlowWager (would require call or data access)
        }

        // Check if already paused
        if self.pausedMarkets[marketId] != nil {
            panic("Market ".concat(marketId.toString()).concat(" is already paused."))
        }

        self.pausedMarkets[marketId] = reason
        log("Market ".concat(marketId.toString()).concat(" PAUSED. Reason: ").concat(reason))
        // Emit FlowWagerEvents.MarketPaused
        // FlowWager contract's functions (e.g., placePrediction, resolveMarket) would then need to check:
        // if FlowWagerSecurity.isMarketPaused(marketId) { panic("Market is paused.") }
    }

    pub fun unpauseMarket(marketId: UInt64, adminCap: &{FlowWager.AdminCapabilityPublic}) {
        pre {
            adminCap.hasPermission(permission: "pause_market"): "Admin lacks permission to unpause markets."
        }

        if self.pausedMarkets.remove(key: marketId) == nil {
            panic("Market ".concat(marketId.toString()).concat(" was not paused or already unpaused."))
        }

        log("Market ".concat(marketId.toString()).concat(" UNPAUSED."))
        // Emit FlowWagerEvents.MarketUnpaused
    }

    // --- View functions for security state ---
    pub fun getIsEmergencyModeActive(): Bool {
        return self.isEmergencyModeActive
    }

    pub fun getEmergencyModeReason(): String? {
        return self.emergencyModeReason
    }

    pub fun isMarketPaused(marketId: UInt64): Bool {
        return self.pausedMarkets[marketId] != nil
    }

    pub fun getMarketPauseReason(marketId: UInt64): String? {
        return self.pausedMarkets[marketId]
    }


    init() {
        // Initialize constants with default/placeholder values.
        // These should be configurable during deployment or by an admin.
        self.MAX_BET_AMOUNT = 10000.0 // Example: 10,000 FLOW
        self.MIN_BET_AMOUNT = 1.0     // Example: 1 FLOW
        self.MAX_MARKETS_PER_USER_PER_DAY = 5
        self.ADMIN_ACTION_COOLDOWN = 60.0 // 1 minute

        self.userMarketCreationTimestamps = {}
        self.lastAdminActionTimestamp = {}

        self.isEmergencyModeActive = false
        self.emergencyModeReason = nil
        self.pausedMarkets = {}

        log("FlowWagerSecurity Contract Initialized.")
    }

    // Helper interface if FlowWager.AdminCapability needs to be passed around
    // This should align with the actual AdminCapability in FlowWager.cdc
    pub resource interface AdminCapabilityPublic {
        pub fun hasPermission(permission: String): Bool
    }
}
