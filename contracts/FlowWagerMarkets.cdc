// FlowWagerMarkets.cdc
// Purpose: Advanced market management, analytics, and creator statistics for FlowWager

// Import other contracts if necessary
// import FlowWager from "./FlowWager.cdc" // To access market data

pub contract FlowWagerMarkets {

    // --- Structs for Analytics Data ---

    pub struct MarketAnalytics {
        pub let marketId: UInt64 // Added for clarity, though function takes marketId
        pub let totalVolume: UFix64        // Total FLOW wagered in the market
        pub let participantCount: UInt64   // Number of unique addresses that placed predictions
        pub let averageBetSize: UFix64     // totalVolume / totalPredictions (if totalPredictions > 0)
        pub let totalPredictionsCount: UInt64 // Total number of prediction transactions
        pub let createdAt: UFix64          // Timestamp of market creation
        pub let endedAt: UFix64            // Timestamp market was supposed to end (endTime from Market resource)
        pub let resolvedAt: UFix64?        // Timestamp market was actually resolved
        pub let category: UInt8            // Market category
        pub let creator: Address           // Market creator's address
        pub let resolutionTime: UFix64?    // Duration between endedAt and resolvedAt (if resolved)

        init(
            marketId: UInt64,
            totalVolume: UFix64,
            participantCount: UInt64,
            totalPredictionsCount: UInt64,
            createdAt: UFix64,
            endedAt: UFix64,
            resolvedAt: UFix64?,
            category: UInt8,
            creator: Address
        ) {
            self.marketId = marketId
            self.totalVolume = totalVolume
            self.participantCount = participantCount
            self.totalPredictionsCount = totalPredictionsCount
            self.averageBetSize = (totalPredictionsCount > 0) ? totalVolume / UFix64(totalPredictionsCount) : 0.0
            self.createdAt = createdAt
            self.endedAt = endedAt
            self.resolvedAt = resolvedAt
            self.category = category
            self.creator = creator
            if resolvedAt != nil && resolvedAt! > endedAt {
                self.resolutionTime = resolvedAt! - endedAt
            } else {
                self.resolutionTime = nil
            }
        }
    }

    pub struct CreatorStats {
        pub let address: Address
        pub let marketsCreated: UInt64
        pub let totalVolumeGenerated: UFix64 // Sum of totalVolume from all markets created by this user
        pub let totalEarnings: UFix64        // Total fees earned by this creator
        pub let averageResolutionTime: UFix64? // Average time taken to resolve their markets after endTime
        pub let successRate: UFix64          // Placeholder: e.g., % of markets resolved without issue, or % correctly predicted if they also bet. Needs definition.
                                             // For now, let's interpret as % of their markets that reached "Resolved" status.
        pub let resolvedMarketsCount: UInt64 // Number of markets created that are now resolved

        init(
            address: Address,
            marketsCreated: UInt64,
            totalVolumeGenerated: UFix64,
            totalEarnings: UFix64,
            resolvedMarketsCount: UInt64,
            totalResolutionDurationForResolvedMarkets: UFix64 // Sum of (resolvedAt - endTime) for their resolved markets
            // successDefinitionCriteria...
        ) {
            self.address = address
            self.marketsCreated = marketsCreated
            self.totalVolumeGenerated = totalVolumeGenerated
            self.totalEarnings = totalEarnings // This data needs to be tracked and passed in
            self.resolvedMarketsCount = resolvedMarketsCount

            if resolvedMarketsCount > 0 {
                self.averageResolutionTime = totalResolutionDurationForResolvedMarkets / UFix64(resolvedMarketsCount)
                self.successRate = UFix64(resolvedMarketsCount) / UFix64(marketsCreated) * 100.0 // % of created markets that got resolved
            } else {
                self.averageResolutionTime = nil
                self.successRate = 0.0
            }
        }
    }

    // --- Contract State (Optional) ---
    // This contract could be purely for on-demand calculation by reading FlowWager state.
    // Or, it could store aggregated/cached data for performance, updated by events or hooks.
    // For now, let's assume it primarily computes stats on-demand by accessing FlowWager.
    // Storing creator earnings here would be redundant if FlowWager tracks it for payouts.

    // Example of state if we were to cache creator earnings (requires updates):
    // access(contract) let creatorCumulativeEarnings: {Address: UFix64}

    // --- Functions ---

    // To implement these functions, FlowWagerMarkets needs read-access to FlowWager's state,
    // particularly the `markets` dictionary and details within each `Market` resource.
    // This typically means FlowWager.cdc would need public functions to expose this data safely.
    // For example, `FlowWager.getMarketView(marketId: UInt64): MarketView?` where MarketView is a struct.

    // For the purpose of this implementation, I'll assume such accessor functions exist on FlowWager.cdc,
    // or that this contract is deployed by the same account and can borrow directly if structured carefully.
    // Let's define a simplified public view of a market that FlowWager could provide.
    // This is a common pattern to avoid exposing entire resources.

    pub struct MarketDataView {
        pub let id: UInt64
        pub let totalPool: UFix64 // == totalVolume for analytics
        pub let participantCount: UInt64 // Derived from market.participants.keys.length
        pub let totalPredictionsCount: UInt64 // Needs to be tracked in Market resource or calculated
        pub let creationTime: UFix64
        pub let endTime: UFix64
        pub let resolutionTimestamp: UFix64?
        pub let category: FlowWager.MarketCategory // Assuming direct access to enum type
        pub let creator: Address
        pub let status: FlowWager.MarketStatus

        init(id: UInt64, totalPool: UFix64, participantCount: UInt64, totalPredictionsCount: UInt64, creationTime: UFix64, endTime: UFix64, resolutionTimestamp: UFix64?, category: FlowWager.MarketCategory, creator: Address, status: FlowWager.MarketStatus) {
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

    // This interface represents what FlowWagerMarkets expects FlowWager contract to provide.
    // FlowWager contract would implement this interface.
    pub contract interface MarketDataProvider {
        pub fun getAllMarketDataViews(): [FlowWagerMarkets.MarketDataView]
        pub fun getMarketDataView(marketId: UInt64): FlowWagerMarkets.MarketDataView?
        // Function to get creator earnings if tracked in FlowWager
        pub fun getCreatorTotalEarnings(creatorAddress: Address): UFix64
    }

    // Reference to the FlowWager contract instance that provides market data.
    // This needs to be configured at deployment.
    access(self) var flowWagerRef: &{MarketDataProvider}

    pub fun getMarketAnalytics(marketId: UInt64): MarketAnalytics? {
        let marketView = self.flowWagerRef.getMarketDataView(marketId: marketId)

        if marketView == nil {
            return nil
        }
        let mv = marketView!

        return MarketAnalytics(
            marketId: mv.id,
            totalVolume: mv.totalPool,
            participantCount: mv.participantCount,
            totalPredictionsCount: mv.totalPredictionsCount, // Assuming MarketDataView provides this
            createdAt: mv.creationTime,
            endedAt: mv.endTime,
            resolvedAt: mv.resolutionTimestamp,
            category: mv.category.rawValue,
            creator: mv.creator
        )
    }

    pub fun getCreatorStats(creatorAddress: Address): CreatorStats? {
        let allMarketViews = self.flowWagerRef.getAllMarketDataViews()
        var marketsCreatedCount: UInt64 = 0
        var totalVolumeGenerated: UFix64 = 0.0
        var resolvedMarketsCount: UInt64 = 0
        var totalResolutionDurationForResolved: UFix64 = 0.0

        for mv in allMarketViews {
            if mv.creator == creatorAddress {
                marketsCreatedCount = marketsCreatedCount + 1
                totalVolumeGenerated = totalVolumeGenerated + mv.totalPool
                if mv.status == FlowWager.MarketStatus.Resolved || mv.status == FlowWager.MarketStatus.EmergencyResolved {
                    resolvedMarketsCount = resolvedMarketsCount + 1
                    if mv.resolutionTimestamp != nil && mv.resolutionTimestamp! > mv.endTime {
                        totalResolutionDurationForResolved = totalResolutionDurationForResolved + (mv.resolutionTimestamp! - mv.endTime)
                    }
                }
            }
        }

        if marketsCreatedCount == 0 {
            return nil // Creator not found or no markets created
        }

        // This part requires FlowWager to track and expose total earnings per creator.
        let totalEarnings = self.flowWagerRef.getCreatorTotalEarnings(creatorAddress: creatorAddress)

        return CreatorStats(
            address: creatorAddress,
            marketsCreated: marketsCreatedCount,
            totalVolumeGenerated: totalVolumeGenerated,
            totalEarnings: totalEarnings,
            resolvedMarketsCount: resolvedMarketsCount,
            totalResolutionDurationForResolvedMarkets: totalResolutionDurationForResolved
        )
    }

    // Returns top N creators based on a specified metric (e.g., total volume generated, markets created)
    // This is computationally intensive on-chain. Usually done off-chain.
    // For an on-chain version, it would be very gas-heavy for many creators/markets.
    // Simplified: Get all creators, calculate stats, then sort. Highly inefficient.
    pub fun getTopCreators(limit: UInt64, sortBy: String): [CreatorStats] {
        // sortBy: "totalVolumeGenerated", "marketsCreated", "totalEarnings"
        // WARNING: This is extremely inefficient on-chain for large datasets.
        // Off-chain systems are better suited for "top N" queries.
        log("getTopCreators: This function is computationally expensive and may hit gas limits with many creators/markets.")

        let allMarketViews = self.flowWagerRef.getAllMarketDataViews()
        let creatorAddresses: {Address: Bool} = {}
        for mv in allMarketViews {
            creatorAddresses[mv.creator] = true
        }

        var allCreatorStats: [CreatorStats] = []
        for address in creatorAddresses.keys {
            if let stats = self.getCreatorStats(creatorAddress: address) {
                allCreatorStats.append(stats)
            }
        }

        // Sort (simplified sort logic, proper sort is complex)
        // Cadence arrays don't have a built-in sort method that takes a custom comparator easily.
        // This part would need a proper sorting algorithm implemented or a very limited N.
        // For now, returning unsorted or sorted by a simple aspect if possible.

        // Example: Simple sort by marketsCreated (descending) - highly inefficient bubble sort for illustration
        var n = allCreatorStats.length
        if n > 1 {
            for i in 0..<(n-1) {
                for j in 0..<(n-i-1) {
                    var shouldSwap = false
                    if sortBy == "marketsCreated" {
                        shouldSwap = allCreatorStats[j].marketsCreated < allCreatorStats[j+1].marketsCreated
                    } else if sortBy == "totalVolumeGenerated" {
                        shouldSwap = allCreatorStats[j].totalVolumeGenerated < allCreatorStats[j+1].totalVolumeGenerated
                    } else if sortBy == "totalEarnings" {
                        shouldSwap = allCreatorStats[j].totalEarnings < allCreatorStats[j+1].totalEarnings
                    } // Add other sort criteria

                    if shouldSwap {
                        let temp = allCreatorStats[j]
                        allCreatorStats[j] = allCreatorStats[j+1]
                        allCreatorStats[j+1] = temp
                    }
                }
            }
        }

        // Return top 'limit'
        var result: [CreatorStats] = []
        var count: UInt64 = 0
        for stat in allCreatorStats {
            if count < limit {
                result.append(stat)
                count = count + 1
            } else {
                break
            }
        }
        return result
    }

    pub fun getCategoryStats(): {UInt8: {String: AnyStruct}} {
        // Returns stats per category: e.g., total volume, number of markets, avg participants.
        let allMarketViews = self.flowWagerRef.getAllMarketDataViews()
        let categoryData: {UInt8: {String: AnyStruct}} = {}

        for mv in allMarketViews {
            let categoryRaw = mv.category.rawValue
            if categoryData[categoryRaw] == nil {
                categoryData[categoryRaw] = {
                    "category": categoryRaw,
                    "totalMarkets": UInt64(0),
                    "totalVolume": 0.0,
                    "totalParticipants": UInt64(0),
                    "activeMarkets": UInt64(0)
                }
            }

            var currentCategoryData = categoryData[categoryRaw]!
            currentCategoryData["totalMarkets"] = (currentCategoryData["totalMarkets"] as! UInt64) + 1
            currentCategoryData["totalVolume"] = (currentCategoryData["totalVolume"] as! UFix64) + mv.totalPool
            currentCategoryData["totalParticipants"] = (currentCategoryData["totalParticipants"] as! UInt64) + mv.participantCount
            if mv.status == FlowWager.MarketStatus.Active {
                 currentCategoryData["activeMarkets"] = (currentCategoryData["activeMarkets"] as! UInt64) + 1
            }
            categoryData[categoryRaw] = currentCategoryData
        }
        return categoryData
    }

    // Returns market IDs sorted by total volume (descending).
    // Similar to getTopCreators, this is very inefficient on-chain.
    pub fun getMarketsByVolume(limit: UInt64): [UInt64] {
        log("getMarketsByVolume: This function is computationally expensive.")
        let allMarketViews = self.flowWagerRef.getAllMarketDataViews()

        // Create a temporary array of structs to sort, containing id and volume
        struct MarketVol {
            pub let id: UInt64
            pub let volume: UFix64
            init(id: UInt64, volume: UFix64) { self.id = id; self.volume = volume }
        }
        var marketsWithVol: [MarketVol] = []
        for mv in allMarketViews {
            marketsWithVol.append(MarketVol(id: mv.id, volume: mv.totalPool))
        }

        // Sort by volume (descending) - using inefficient bubble sort for illustration
        var n = marketsWithVol.length
        if n > 1 {
            for i in 0..<(n-1) {
                for j in 0..<(n-i-1) {
                    if marketsWithVol[j].volume < marketsWithVol[j+1].volume {
                        let temp = marketsWithVol[j]
                        marketsWithVol[j] = marketsWithVol[j+1]
                        marketsWithVol[j+1] = temp
                    }
                }
            }
        }

        var resultMarketIds: [UInt64] = []
        var count: UInt64 = 0
        for mvInfo in marketsWithVol {
            if count < limit {
                resultMarketIds.append(mvInfo.id)
                count = count + 1
            } else {
                break
            }
        }
        return resultMarketIds
    }

    pub fun getPlatformAnalytics(): {String: AnyStruct} {
        // Aggregates overall platform statistics.
        let allMarketViews = self.flowWagerRef.getAllMarketDataViews()
        var totalMarkets: UInt64 = 0
        var totalPlatformVolume: UFix64 = 0.0
        var uniqueParticipantsPlatformWide: {Address: Bool} = {} // To count unique users across all markets
        var activeMarkets: UInt64 = 0
        var resolvedMarkets: UInt64 = 0

        for mv in allMarketViews {
            totalMarkets = totalMarkets + 1
            totalPlatformVolume = totalPlatformVolume + mv.totalPool
            // This part is tricky: participantCount in MarketDataView is per-market.
            // To get platform-wide unique participants, we'd need access to the actual participant lists or FlowWager would need to provide this.
            // For now, I'll sum up market-level participant counts, which is NOT unique platform users.
            // A true unique count requires iterating all participants of all markets.
            // Or FlowWager contract maintains a global set of users.

            if mv.status == FlowWager.MarketStatus.Active {
                activeMarkets = activeMarkets + 1
            } else if mv.status == FlowWager.MarketStatus.Resolved || mv.status == FlowWager.MarketStatus.EmergencyResolved {
                resolvedMarkets = resolvedMarkets + 1
            }
            // To get unique participants, FlowWager itself would need a function like:
            // pub fun getAllParticipants(): {Address: Bool}
            // Then: uniqueParticipantsPlatformWide = FlowWager.getAllParticipants().keys.length
        }

        // Placeholder for unique participant count
        let approxTotalParticipants = "DataNotAvailable: Sum of per-market counts, not unique users"

        return {
            "totalMarkets": totalMarkets,
            "totalPlatformVolume": totalPlatformVolume,
            "activeMarkets": activeMarkets,
            "resolvedMarkets": resolvedMarkets,
            "uniqueParticipantsEstimate": approxTotalParticipants // Needs better data source
            // "totalCreatorEarningsPaid": UFix64 // Needs data source
            // "totalPlatformFeesCollected": UFix64 // Needs data source (e.g. from FlowWager.platformVault balance if only fees go there)
        }
    }

    // --- Initialization ---
    // This function needs to be called by the deployer, providing a capability to the FlowWager contract.
    init(flowWagerProvider: &{MarketDataProvider}) {
        self.flowWagerRef = flowWagerProvider
        log("FlowWagerMarkets Contract Initialized.")
    }
}

// Assume FlowWager.cdc has these enums defined and they are accessible.
// If not, they need to be redefined or imported carefully.
// For simplicity, I'm assuming FlowWager.MarketCategory and FlowWager.MarketStatus can be referenced
// if this contract is imported correctly by FlowWager or they share types.
// A common pattern is to define shared enums/structs in a separate contract.
// For now, using FlowWager.MarketCategory as a placeholder for the type.

// Example of how FlowWager.cdc might expose data (simplified):
/*
pub contract FlowWager {
    ...
    pub enum MarketCategory: UInt8 {...}
    pub enum MarketStatus: UInt8 {...}

    pub resource Market { ...
        // Add this field or calculate it:
        access(self) var totalPredictionTransactions: UInt64
    }

    // This function would be part of FlowWager implementing FlowWagerMarkets.MarketDataProvider
    pub fun getAllMarketDataViews(): [FlowWagerMarkets.MarketDataView] {
        let views: [FlowWagerMarkets.MarketDataView] = []
        for id in self.markets.keys {
            let market = self.markets[id]!
            // market.totalPredictionTransactions needs to be tracked in your Market resource
            views.append(
                FlowWagerMarkets.MarketDataView(
                    id: market.id,
                    totalPool: market.totalPool,
                    participantCount: UInt64(market.participants.keys.length),
                    totalPredictionsCount: market.totalPredictionTransactions, // NEWLY ADDED field assumption
                    creationTime: market.creationTime,
                    endTime: market.endTime,
                    resolutionTimestamp: market.resolutionTimestamp,
                    category: market.category,
                    creator: market.creator,
                    status: market.status
                )
            )
        }
        return views
    }
    // Similarly for getMarketDataView(marketId) and getCreatorTotalEarnings(creatorAddress)
}
*/
