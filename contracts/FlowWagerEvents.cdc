// FlowWagerEvents.cdc
// Purpose: Event definitions for the FlowWager platform

pub contract FlowWagerEvents {

    // MARKET EVENTS
    pub event MarketCreated(id: UInt64, title: String, category: UInt8, creator: Address, creationTime: UFix64, endTime: UFix64, options: [String])
    pub event MarketStatusUpdated(id: UInt64, newStatus: UInt8, timestamp: UFix64) // Generic status update
    // Specific status updates can also be useful:
    // pub event MarketActivated(id: UInt64, timestamp: UFix64) // If there's a separate activation step
    pub event MarketPendingResolution(id: UInt64, timestamp: UFix64) // When endTime is reached
    pub event MarketResolved(id: UInt64, outcome: String, resolver: Address, evidenceURL: String, timestamp: UFix64)
    pub event MarketEmergencyResolved(id: UInt64, outcome: String, resolver: Address, evidenceURL: String, timestamp: UFix64)
    pub event MarketCancelled(id: UInt64, reason: String?, timestamp: UFix64) // If markets can be cancelled

    // BETTING EVENTS (Prediction Events)
    pub event PredictionPlaced(marketId: UInt64, predictor: Address, option: String, amount: UFix64, timestamp: UFix64)
    pub event WinningsClaimed(marketId: UInt64, winner: Address, amount: UFix64, timestamp: UFix64)
    // pub event BetRefunded(marketId: UInt64, predictor: Address, amount: UFix64, reason: String, timestamp: UFix64) // If refunds are possible

    // ADMIN EVENTS
    pub event AdminAdded(adminAddress: Address, permissions: [String], addedBy: Address, timestamp: UFix64)
    pub event AdminRemoved(adminAddress: Address, removedBy: Address, timestamp: UFix64)
    pub event AdminPermissionsUpdated(adminAddress: Address, newPermissions: [String], updatedBy: Address, timestamp: UFix64)
    // This one from the prompt: AdminActionLogged(admin: Address, action: String, marketId: UInt64?, timestamp: UFix64)
    // It's generic. Specific events for admin actions are often more useful for off-chain indexers.
    // However, adhering to the prompt:
    pub event AdminActionLogged(adminAddress: Address, action: String, marketId: UInt64?, targetAddress: Address?, details: {String: String}?, timestamp: UFix64)

    // FINANCIAL EVENTS
    pub event FeesCalculatedForMarket(marketId: UInt64, totalPool: UFix64, platformFee: UFix64, creatorFee: UFix64, timestamp: UFix64)
    pub event CreatorFeePaidOut(marketId: UInt64, creator: Address, amount: UFix64, timestamp: UFix64)
    // This one from the prompt: FeesDistributed(marketId: UInt64, creatorFee: UFix64, platformFee: UFix64, creator: Address, timestamp: UFix64)
    // This seems to imply a single event when both are set aside.
    pub event FeesDistributed(marketId: UInt64, totalPool: UFix64, platformFeeAmount: UFix64, creatorFeeAmount: UFix64, creatorAddress: Address, timestamp: UFix64)

    pub event PlatformFeesWithdrawn(amount: UFix64, withdrawnBy: Address, recipientAddress: Address, timestamp: UFix64)
    // This one from the prompt: CreatorEarningsUpdated(creator: Address, totalEarnings: UFix64, timestamp: UFix64)
    // This would likely be part of a separate analytics contract or system.
    // For now, including as defined. It implies tracking cumulative earnings.
    pub event CreatorEarningsUpdated(creatorAddress: Address, newTotalEarnings: UFix64, marketIdContributing: UInt64?, feeAmountFromMarket: UFix64?, timestamp: UFix64)

    // SECURITY & SYSTEM EVENTS
    pub event ContractInitialized(deployer: Address, timestamp: UFix64)
    pub event EmergencyModeEnabled(adminAddress: Address, reason: String, timestamp: UFix64)
    pub event EmergencyModeDisabled(adminAddress: Address, timestamp: UFix64)
    pub event SystemMaintenanceModeToggled(adminAddress: Address, enabled: Bool, timestamp: UFix64)
    pub event MarketPaused(marketId: UInt64, adminAddress: Address, reason: String, timestamp: UFix64)
    pub event MarketUnpaused(marketId: UInt64, adminAddress: Address, timestamp: UFix64)
    pub event ContractUpgraded(adminAddress: Address, newAddress: Address, timestamp: UFix64) // If applicable

    // Adding specific events from the prompt that might have been slightly different
    // MarketUpdated(id: UInt64, status: UInt8, timestamp: UFix64) -> Covered by MarketStatusUpdated
    // MarketEmergencyResolution(id: UInt64, timestamp: UFix64) -> Covered by MarketEmergencyResolved (which includes more details)
    // If a simpler one is needed:
    pub event MarketEligibleForEmergencyResolution(id: UInt64, timestamp: UFix64)


    // Placeholder for any other events that might arise
    pub event GenericLog(message: String, details: {String: AnyStruct}?)

    init() {
        // Events contract usually doesn't have state or complex init logic
        log("FlowWagerEvents Contract Initialized and events defined.")
    }
}
