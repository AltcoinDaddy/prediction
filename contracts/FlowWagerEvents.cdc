// FlowWagerEvents.cdc
// Purpose: Event definitions for the FlowWager platform

access(all) contract FlowWagerEvents {

    // MARKET EVENTS
    access(all) event MarketCreated(id: UInt64, title: String, category: UInt8, creator: Address, creationTime: UFix64, endTime: UFix64, options: [String])
    access(all) event MarketStatusUpdated(id: UInt64, newStatus: UInt8, timestamp: UFix64)
    access(all) event MarketPendingResolution(id: UInt64, timestamp: UFix64)
    access(all) event MarketResolved(id: UInt64, outcome: String, resolver: Address, evidenceURL: String, timestamp: UFix64)
    access(all) event MarketEmergencyResolved(id: UInt64, outcome: String, resolver: Address, evidenceURL: String, timestamp: UFix64)
    access(all) event MarketCancelled(id: UInt64, reason: String?, timestamp: UFix64)

    // BETTING EVENTS (Prediction Events)
    access(all) event PredictionPlaced(marketId: UInt64, predictor: Address, option: String, amount: UFix64, timestamp: UFix64)
    access(all) event WinningsClaimed(marketId: UInt64, winner: Address, amount: UFix64, timestamp: UFix64)

    // ADMIN EVENTS
    access(all) event AdminAdded(adminAddress: Address, permissions: [String], addedBy: Address, timestamp: UFix64)
    access(all) event AdminRemoved(adminAddress: Address, removedBy: Address, timestamp: UFix64)
    access(all) event AdminPermissionsUpdated(adminAddress: Address, newPermissions: [String], updatedBy: Address, timestamp: UFix64)
    access(all) event AdminActionLogged(adminAddress: Address, action: String, marketId: UInt64?, targetAddress: Address?, details: {String: String}?, timestamp: UFix64)

    // FINANCIAL EVENTS
    access(all) event FeesCalculatedForMarket(marketId: UInt64, totalPool: UFix64, platformFee: UFix64, creatorFee: UFix64, timestamp: UFix64)
    access(all) event CreatorFeePaidOut(marketId: UInt64, creator: Address, amount: UFix64, timestamp: UFix64)
    access(all) event FeesDistributed(marketId: UInt64, totalPool: UFix64, platformFeeAmount: UFix64, creatorFeeAmount: UFix64, creatorAddress: Address, timestamp: UFix64)
    access(all) event PlatformFeesWithdrawn(amount: UFix64, withdrawnBy: Address, recipientAddress: Address, timestamp: UFix64)
    access(all) event CreatorEarningsUpdated(creatorAddress: Address, newTotalEarnings: UFix64, marketIdContributing: UInt64?, feeAmountFromMarket: UFix64?, timestamp: UFix64)

    // SECURITY & SYSTEM EVENTS
    access(all) event ContractInitialized(deployer: Address, timestamp: UFix64)
    access(all) event EmergencyModeEnabled(adminAddress: Address, reason: String, timestamp: UFix64)
    access(all) event EmergencyModeDisabled(adminAddress: Address, timestamp: UFix64)
    access(all) event SystemMaintenanceModeToggled(adminAddress: Address, enabled: Bool, timestamp: UFix64)
    access(all) event MarketPaused(marketId: UInt64, adminAddress: Address, reason: String, timestamp: UFix64)
    access(all) event MarketUnpaused(marketId: UInt64, adminAddress: Address, timestamp: UFix64)
    access(all) event ContractUpgraded(adminAddress: Address, newAddress: Address, timestamp: UFix64)
    access(all) event MarketEligibleForEmergencyResolution(id: UInt64, timestamp: UFix64)

    // Placeholder for any other events that might arise
    access(all) event GenericLog(message: String, details: {String: String}?) // Changed AnyStruct to String for Cadence 1.0 compatibility

    init() {
        log("FlowWagerEvents Contract Initialized and events defined.")
    }
}
