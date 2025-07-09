// FlowWagerTypes.cdc
// This contract defines shared enums and structs for the FlowWager ecosystem.

access(all) contract FlowWagerTypes {

    access(all) enum MarketCategory: UInt8 {
        case Sports = 0
        case Politics = 1
        case Cryptocurrency = 2
        case Economics = 3
        case Entertainment = 4
        case Technology = 5
        case Science = 6
        case Lifestyle = 7
        case Weather = 8
        case Gaming = 9
        case Other = 10
        case Meta = 11 // For markets about FlowWager itself
    }

    access(all) enum MarketStatus: UInt8 {
        case Active = 0
        case PendingResolution = 1
        case Resolved = 2
        case Cancelled = 3
        case EmergencyResolved = 4
    }

    // MarketDataView struct, previously in FlowWagerMarkets.cdc
    // Now references MarketCategory and MarketStatus from this FlowWagerTypes contract.
    access(all) struct MarketDataView {
        access(all) let id: UInt64
        access(all) let totalPool: UFix64
        access(all) let participantCount: UInt64
        access(all) let totalPredictionsCount: UInt64
        access(all) let creationTime: UFix64
        access(all) let endTime: UFix64
        access(all) let resolutionTimestamp: UFix64?
        access(all) let category: MarketCategory // Now refers to FlowWagerTypes.MarketCategory
        access(all) let creator: Address
        access(all) let status: MarketStatus   // Now refers to FlowWagerTypes.MarketStatus

        init(
            id: UInt64,
            totalPool: UFix64,
            participantCount: UInt64,
            totalPredictionsCount: UInt64,
            creationTime: UFix64,
            endTime: UFix64,
            resolutionTimestamp: UFix64?,
            category: MarketCategory, // Parameter type also updated
            creator: Address,
            status: MarketStatus // Parameter type also updated
        ) {
            self.id = id
            self.totalPool = totalPool
            self.participantCount = participantCount
            self.totalPredictionsCount = totalPredictionsCount
            self.creationTime = creationTime
            self.endTime = endTime
            self.resolutionTimestamp = resolutionTimestamp
            self.category = category
            self.creator = creator
            self.status = status
        }
    }

    // Note: FlowWagerTypes contract itself doesn't have an init() function
    // as it's primarily a container for type definitions.
    // If it were to hold state, an init() would be needed.
    // For just types, Cadence allows contracts without init.
}
