// FlowWagerMarkets.cdc
// Purpose: Advanced market management, analytics, and creator statistics for FlowWager

import FlowWager from "FlowWager" // Import the main FlowWager contract, resolved by flow.json
import FlowWagerTypes from "FlowWagerTypes" // Import the shared types by name
import MarketDataProvider from "MarketDataProvider" // Import the interface by name

// MarketDataProvider interface is now in its own file.
// MarketDataView struct is now in FlowWagerTypes.cdc

access(all) contract FlowWagerMarkets {

    // --- Structs for Analytics Data ---
    access(all) struct MarketAnalytics {
        access(all) let marketId: UInt64
        access(all) let totalVolume: UFix64
        access(all) let participantCount: UInt64
        access(all) let averageBetSize: UFix64
        access(all) let totalPredictionsCount: UInt64
        access(all) let createdAt: UFix64
        access(all) let endedAt: UFix64
        access(all) let resolvedAt: UFix64?
        access(all) let category: UInt8 // This is FlowWagerTypes.MarketCategory.rawValue
        access(all) let creator: Address
        access(all) let resolutionTime: UFix64?

        init(
            marketId: UInt64, totalVolume: UFix64, participantCount: UInt64, totalPredictionsCount: UInt64,
            createdAt: UFix64, endedAt: UFix64, resolvedAt: UFix64?, category: UInt8, creator: Address
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
            if resolvedAt != nil && endedAt < resolvedAt! { // Ensure resolvedAt is after endedAt
                self.resolutionTime = resolvedAt! - endedAt
            } else {
                self.resolutionTime = nil
            }
        }
    }

    access(all) struct CreatorStats {
        access(all) let address: Address
        access(all) let marketsCreated: UInt64
        access(all) let totalVolumeGenerated: UFix64
        access(all) let totalEarnings: UFix64
        access(all) let averageResolutionTime: UFix64?
        access(all) let successRate: UFix64 // % of created markets that got resolved
        access(all) let resolvedMarketsCount: UInt64

        init(
            address: Address, marketsCreated: UInt64, totalVolumeGenerated: UFix64, totalEarnings: UFix64,
            resolvedMarketsCount: UInt64, totalResolutionDurationForResolvedMarkets: UFix64
        ) {
            self.address = address
            self.marketsCreated = marketsCreated
            self.totalVolumeGenerated = totalVolumeGenerated
            self.totalEarnings = totalEarnings
            self.resolvedMarketsCount = resolvedMarketsCount

            if resolvedMarketsCount > 0 && marketsCreated > 0 { // Ensure marketsCreated is not zero for successRate
                self.averageResolutionTime = totalResolutionDurationForResolvedMarkets / UFix64(resolvedMarketsCount)
                self.successRate = (UFix64(resolvedMarketsCount) / UFix64(marketsCreated)) * 100.0
            } else {
                self.averageResolutionTime = nil
                self.successRate = 0.0
            }
        }
    }

    // MarketDataView struct is now defined in FlowWagerTypes.cdc

    // Local struct for sorting markets by volume, used in getMarketsByVolume
    access(all) struct MarketVol {
        access(all) let id: UInt64
        access(all) let volume: UFix64
        init(id: UInt64, volume: UFix64) { self.id = id; self.volume = volume }
    }

    access(all) let flowWagerContractAddress: Address
    // Define the public capability path where FlowWager is expected to publish its MarketDataProvider capability.
    access(all) let marketDataProviderPublicPath: PublicPath

    access(all) fun getMarketDataProvider(): &{MarketDataProvider.MarketDataProvider} {
        return getAccount(self.flowWagerContractAddress)
            .capabilities.borrow<&{MarketDataProvider.MarketDataProvider}>(self.marketDataProviderPublicPath)
            ?? panic("Could not borrow MarketDataProvider capability from FlowWager contract. Ensure it's published.")
    }

    access(all) fun getMarketAnalytics(marketId: UInt64): MarketAnalytics? {
        let provider = self.getMarketDataProvider()
        let marketView = provider.getMarketDataView(marketId: marketId)

        if marketView == nil { return nil }
        let mv = marketView!

        return MarketAnalytics(
            marketId: mv.id, totalVolume: mv.totalPool, participantCount: mv.participantCount,
            totalPredictionsCount: mv.totalPredictionsCount, createdAt: mv.creationTime,
            endedAt: mv.endTime, resolvedAt: mv.resolutionTimestamp, category: mv.category.rawValue, creator: mv.creator
        )
    }

    access(all) fun getCreatorStats(creatorAddress: Address): CreatorStats? {
        let provider = self.getMarketDataProvider()
        let allMarketViews = provider.getAllMarketDataViews()
        var marketsCreatedCount: UInt64 = 0
        var totalVolumeGenerated: UFix64 = 0.0
        var resolvedMarketsCount: UInt64 = 0
        var totalResolutionDurationForResolved: UFix64 = 0.0

        for mv in allMarketViews {
            if mv.creator == creatorAddress {
                marketsCreatedCount = marketsCreatedCount + 1
                totalVolumeGenerated = totalVolumeGenerated + mv.totalPool
                if mv.status == FlowWagerTypes.MarketStatus.Resolved || mv.status == FlowWagerTypes.MarketStatus.EmergencyResolved {
                    resolvedMarketsCount = resolvedMarketsCount + 1
                    if mv.resolutionTimestamp != nil && mv.endTime < mv.resolutionTimestamp! {
                        totalResolutionDurationForResolved = totalResolutionDurationForResolved + (mv.resolutionTimestamp! - mv.endTime)
                    }
                }
            }
        }

        if marketsCreatedCount == 0 { return nil }
        let totalEarnings = provider.getCreatorTotalEarnings(creatorAddress: creatorAddress)

        return CreatorStats(
            address: creatorAddress, marketsCreated: marketsCreatedCount, totalVolumeGenerated: totalVolumeGenerated,
            totalEarnings: totalEarnings, resolvedMarketsCount: resolvedMarketsCount,
            totalResolutionDurationForResolvedMarkets: totalResolutionDurationForResolved
        )
    }

    access(all) fun getTopCreators(limit: UInt64, sortBy: String): [CreatorStats] {
        log("getTopCreators: WARNING - This function is computationally expensive on-chain.")
        let provider = self.getMarketDataProvider()
        let allMarketViews = provider.getAllMarketDataViews()
        let creatorAddresses: {Address: Bool} = {}
        for mv in allMarketViews { creatorAddresses[mv.creator] = true }

        var allCreatorStats: [CreatorStats] = []
        for address in creatorAddresses.keys {
            if let stats = self.getCreatorStats(creatorAddress: address) {
                allCreatorStats.append(stats)
            }
        }

        // On-chain sorting is complex and gas-heavy. This is a simplified, inefficient sort.
        // For production, off-chain sorting is recommended.
        var n = allCreatorStats.length
        if n > 1 {
            for i in 0..<(n-1) {
                for j in 0..<(n-i-1) {
                    var swap = false
                    if sortBy == "marketsCreated" { swap = allCreatorStats[j].marketsCreated < allCreatorStats[j+1].marketsCreated }
                    else if sortBy == "totalVolumeGenerated" { swap = allCreatorStats[j].totalVolumeGenerated < allCreatorStats[j+1].totalVolumeGenerated }
                    else if sortBy == "totalEarnings" { swap = allCreatorStats[j].totalEarnings < allCreatorStats[j+1].totalEarnings }

                    if swap {
                        let temp = allCreatorStats[j]
                        allCreatorStats[j] = allCreatorStats[j+1]
                        allCreatorStats[j+1] = temp
                    }
                }
            }
        }

        var result: [CreatorStats] = []
        var count: UInt64 = 0
        for stat in allCreatorStats {
            if count < limit { result.append(stat); count = count + 1 } else { break }
        }
        return result
    }

    access(all) fun getCategoryStats(): {UInt8: {String: AnyStruct}} {
        let provider = self.getMarketDataProvider()
        let allMarketViews = provider.getAllMarketDataViews()
        let categoryData: {UInt8: {String: AnyStruct}} = {}

        for mv in allMarketViews {
            let categoryRaw = mv.category.rawValue
            if categoryData[categoryRaw] == nil {
                categoryData[categoryRaw] = {
                    "category": categoryRaw, "totalMarkets": 0 as UInt64, "totalVolume": 0.0,
                    "totalParticipants": 0 as UInt64, "activeMarkets": 0 as UInt64
                }
            }

            var currentData = categoryData[categoryRaw]!
            currentData["totalMarkets"] = (currentData["totalMarkets"] as! UInt64) + 1
            currentData["totalVolume"] = (currentData["totalVolume"] as! UFix64) + mv.totalPool
            currentData["totalParticipants"] = (currentData["totalParticipants"] as! UInt64) + mv.participantCount
            if mv.status == FlowWagerTypes.MarketStatus.Active {
                 currentData["activeMarkets"] = (currentData["activeMarkets"] as! UInt64) + 1
            }
            categoryData[categoryRaw] = currentData
        }
        return categoryData
    }

    access(all) fun getMarketsByVolume(limit: UInt64): [UInt64] {
        log("getMarketsByVolume: WARNING - This function is computationally expensive on-chain.")
        let provider = self.getMarketDataProvider()
        let allMarketViews = provider.getAllMarketDataViews()

        // MarketVol struct is now defined at the contract level
        var marketsWithVol: [MarketVol] = []
        for mv in allMarketViews { marketsWithVol.append(MarketVol(id: mv.id, volume: mv.totalPool)) }

        var n = marketsWithVol.length
        if n > 1 { /* Simplified bubble sort */
            for i in 0..<(n-1) {
                for j in 0..<(n-i-1) {
                    if marketsWithVol[j].volume < marketsWithVol[j+1].volume {
                        let temp = marketsWithVol[j]; marketsWithVol[j] = marketsWithVol[j+1]; marketsWithVol[j+1] = temp
                    }
                }
            }
        }

        var resultMarketIds: [UInt64] = []
        var count: UInt64 = 0
        for mvInfo in marketsWithVol {
            if count < limit { resultMarketIds.append(mvInfo.id); count = count + 1 } else { break }
        }
        return resultMarketIds
    }

    access(all) fun getPlatformAnalytics(): {String: AnyStruct} {
        let provider = self.getMarketDataProvider()
        let allMarketViews = provider.getAllMarketDataViews()
        var totalMarkets: UInt64 = 0; var totalPlatformVolume: UFix64 = 0.0
        var activeMarkets: UInt64 = 0; var resolvedMarkets: UInt64 = 0
        // TODO: True unique participant count requires different data source or aggregation logic from FlowWager.

        for mv in allMarketViews {
            totalMarkets = totalMarkets + 1
            totalPlatformVolume = totalPlatformVolume + mv.totalPool
            if mv.status == FlowWagerTypes.MarketStatus.Active { activeMarkets = activeMarkets + 1 }
            else if mv.status == FlowWagerTypes.MarketStatus.Resolved || mv.status == FlowWagerTypes.MarketStatus.EmergencyResolved { resolvedMarkets = resolvedMarkets + 1 }
        }

        return {
            "totalMarkets": totalMarkets, "totalPlatformVolume": totalPlatformVolume,
            "activeMarkets": activeMarkets, "resolvedMarkets": resolvedMarkets,
            "uniqueParticipantsEstimate": "DataNotAvailable: Sum of per-market counts"
            // TODO: Add totalCreatorEarningsPaid, totalPlatformFeesCollected if data source available
        }
    }

    init(flowWagerAddr: Address, providerPath: PublicPath) {
        self.flowWagerContractAddress = flowWagerAddr
        self.marketDataProviderPublicPath = providerPath
        // Ensure capability exists at init or handle gracefully.
        // Borrowing here would fail if FlowWager isn't fully set up or capability not published.
        // It's better to borrow on demand in each function.
        log("FlowWagerMarkets Contract Initialized. FlowWager address: ".concat(flowWagerAddr.toString()))
    }
}
