// FlowWagerSecurity.cdc
// Purpose: Security validation and protection mechanisms for FlowWager

// import FlowWager from "./FlowWager.cdc" // TODO: Uncomment if direct type access like FlowWager.AdminCapabilityPublic is needed from FlowWager.cdc

access(all) contract FlowWagerSecurity {

    access(all) let MAX_BET_AMOUNT: UFix64
    access(all) let MIN_BET_AMOUNT: UFix64
    access(all) let MAX_MARKETS_PER_USER_PER_DAY: UInt64
    access(all) let ADMIN_ACTION_COOLDOWN: UFix64

    access(contract) var userMarketCreationTimestamps: {Address: [UFix64]}
    access(contract) var lastAdminActionTimestamp: {Address: {String: UFix64}}

    access(all) fun validateMarketTitle(title: String): Bool {
        if title.length == 0 {
            return false
        }
        if title.length > 150 {
            return false
        }
        return true
    }

    access(all) fun validateMarketDescription(description: String): Bool {
        if description.length == 0 {
            return false
        }
        if description.length > 2000 {
            return false
        }
        return true
    }

    access(all) fun validateMarketDuration(startTime: UFix64, endTime: UFix64, minDuration: UFix64, maxDuration: UFix64): Bool {
        if endTime <= startTime {
            return false
        }
        let duration = endTime - startTime
        if duration < minDuration {
            return false
        }
        if duration > maxDuration {
            return false
        }
        return true
    }

    access(all) fun validateBetAmount(amount: UFix64): Bool {
        if amount < self.MIN_BET_AMOUNT {
            return false
        }
        if amount > self.MAX_BET_AMOUNT {
            return false
        }
        return true
    }

    access(all) fun validateEvidenceURL(url: String): Bool {
        if url.length == 0 {
            return false
        }
        let httpPrefix = "http://"
        let httpsPrefix = "https://"
        // Basic URL format check
        let startsWithHttp = url.length >= httpPrefix.length && url.slice(from: 0, upTo: httpPrefix.length) == httpPrefix
        let startsWithHttps = url.length >= httpsPrefix.length && url.slice(from: 0, upTo: httpsPrefix.length) == httpsPrefix

        if !startsWithHttp && !startsWithHttps {
            return false
        }
        if url.length > 512 {
             return false
        }
        return true
    }

    // This function assumes AdminCapabilityPublic interface is available
    // and the passed adminCap reference conforms to it.
    access(all) fun validateAdminPermissions(
        adminAddress: Address,
        action: String,
        adminCap: &{AdminCapabilityPublic}
    ): Bool {
        // The AdminCapability resource itself (defined in FlowWager.cdc or a shared types contract)
        // should be the source of truth for `hasPermission`.
        // This function provides a consistent signature for validation if needed by other contracts.
        if !adminCap.hasPermission(permission: action) {
            return false
        }
        return true
    }

    access(all) fun checkRateLimitMarketCreation(user: Address, currentTime: UFix64): Bool {
        let oneDayAgo = currentTime - 86400.0

        var validTimestamps: [UFix64] = []
        if let timestamps = self.userMarketCreationTimestamps[user] {
            for ts in timestamps {
                if ts >= oneDayAgo {
                    validTimestamps.append(ts)
                }
            }
        }

        if UInt64(validTimestamps.length) >= self.MAX_MARKETS_PER_USER_PER_DAY {
            self.userMarketCreationTimestamps[user] = validTimestamps
            return false
        }

        validTimestamps.append(currentTime)
        self.userMarketCreationTimestamps[user] = validTimestamps
        return true
    }

    access(all) fun checkRateLimit(user: Address, action: String, currentTime: UFix64): Bool {
        if action == "create_market" {
            return self.checkRateLimitMarketCreation(user: user, currentTime: currentTime)
        }
        return true
    }

    access(all) fun checkSuspiciousActivity(user: Address): Bool {
        // TODO: Implement more complex suspicious activity detection logic if required.
        log("Suspicious activity check for user ".concat(user.toString()).concat(": Basic implementation."))
        return true
    }

    access(all) fun checkAdminCooldown(admin: Address, action: String, currentTime: UFix64): Bool {
        if let adminActions = self.lastAdminActionTimestamp[admin] {
            if let lastActionTime = adminActions[action] {
                if currentTime < lastActionTime + self.ADMIN_ACTION_COOLDOWN {
                    return false
                }
            }
        }
        if self.lastAdminActionTimestamp[admin] == nil {
            self.lastAdminActionTimestamp[admin] = {}
        }
        var adminActionsRef = self.lastAdminActionTimestamp[admin]!
        adminActionsRef[action] = currentTime
        self.lastAdminActionTimestamp[admin] = adminActionsRef

        return true
    }

    access(all) fun checkMarketIntegrity(marketId: UInt64): Bool {
        // TODO: Implement market integrity checks if required, possibly needing market data access.
        log("Market integrity check for market ".concat(marketId.toString()).concat(": Basic implementation."))
        return true
    }

    access(contract) var isEmergencyModeActive: Bool
    access(contract) var emergencyModeReason: String?
    access(contract) var pausedMarkets: {UInt64: String}

    // Emergency functions require an admin capability that conforms to AdminCapabilityPublic.
    // This capability would typically be from the main FlowWager contract.
    // Event emissions (e.g., FlowWagerEvents.EmergencyModeEnabled) are TODOs.

    access(all) fun enableEmergencyMode(reason: String, adminCap: &{AdminCapabilityPublic}) {
        pre {
            // Assuming "manage_system_state" is a defined permission string.
            adminCap.hasPermission(permission: "manage_system_state"): "Admin lacks permission for emergency mode."
            reason.length > 0 : "Reason for enabling emergency mode must be provided."
        }

        self.isEmergencyModeActive = true
        self.emergencyModeReason = reason
        log("Emergency Mode ENABLED. Reason: ".concat(reason))
        // TODO: Emit FlowWagerEvents.EmergencyModeEnabled
    }

    access(all) fun disableEmergencyMode(adminCap: &{AdminCapabilityPublic}) {
        pre {
            adminCap.hasPermission(permission: "manage_system_state"): "Admin lacks permission for emergency mode."
        }
        self.isEmergencyModeActive = false
        self.emergencyModeReason = nil
        log("Emergency Mode DISABLED.")
        // TODO: Emit FlowWagerEvents.EmergencyModeDisabled
    }

    access(all) fun pauseMarket(marketId: UInt64, reason: String, adminCap: &{AdminCapabilityPublic}) {
        pre {
            // Assuming "pause_market" is a defined permission string.
            adminCap.hasPermission(permission: "pause_market"): "Admin lacks permission to pause markets."
            reason.length > 0 : "Reason for pausing market must be provided."
        }

        if self.pausedMarkets[marketId] != nil {
            panic("Market ".concat(marketId.toString()).concat(" is already paused."))
        }

        self.pausedMarkets[marketId] = reason
        log("Market ".concat(marketId.toString()).concat(" PAUSED. Reason: ").concat(reason))
        // TODO: Emit FlowWagerEvents.MarketPaused
        // FlowWager contract's functions would then need to check:
        // if FlowWagerSecurity.isMarketPaused(marketId) { panic("Market is paused.") }
    }

    access(all) fun unpauseMarket(marketId: UInt64, adminCap: &{AdminCapabilityPublic}) {
        pre {
            adminCap.hasPermission(permission: "pause_market"): "Admin lacks permission to unpause markets."
        }

        if self.pausedMarkets.remove(key: marketId) == nil {
            panic("Market ".concat(marketId.toString()).concat(" was not paused or already unpaused."))
        }

        log("Market ".concat(marketId.toString()).concat(" UNPAUSED."))
        // TODO: Emit FlowWagerEvents.MarketUnpaused
    }

    access(all) fun getIsEmergencyModeActive(): Bool {
        return self.isEmergencyModeActive
    }

    access(all) fun getEmergencyModeReason(): String? {
        return self.emergencyModeReason
    }

    access(all) fun isMarketPaused(marketId: UInt64): Bool {
        return self.pausedMarkets[marketId] != nil
    }

    access(all) fun getMarketPauseReason(marketId: UInt64): String? {
        return self.pausedMarkets[marketId]
    }

    init() {
        self.MAX_BET_AMOUNT = 10000.0
        self.MIN_BET_AMOUNT = 1.0
        self.MAX_MARKETS_PER_USER_PER_DAY = 5
        self.ADMIN_ACTION_COOLDOWN = 60.0

        self.userMarketCreationTimestamps = {}
        self.lastAdminActionTimestamp = {}

        self.isEmergencyModeActive = false
        self.emergencyModeReason = nil
        self.pausedMarkets = {}

        log("FlowWagerSecurity Contract Initialized.")
    }

    // This interface defines the expected public signature for an Admin Capability,
    // allowing this FlowWagerSecurity contract to operate on such capabilities
    // without needing a direct import of the full FlowWager contract (if they were separate).
    // If FlowWager.AdminCapability is intended, FlowWager would need to be imported.
    access(all) resource interface AdminCapabilityPublic {
        access(all) fun hasPermission(permission: String): Bool
        // Cadence 1.0: Interface functions also need access modifiers.
        // Assuming ownerAddress() might be needed if not using the address from the capability passed to validateAdminPermissions
        // access(all) fun ownerAddress(): Address
    }
}
