import FlowWagerMarkets from 0xFLOWWAGER_MARKETS_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_MARKETS_CONTRACT_ADDRESS with actual deployment address.
// This also implies that FlowWagerMarkets contract is deployed and initialized.

/*
Script to get analytics for a specific market.

Parameters:
- marketId: UInt64 - The ID of the market.

Returns:
- FlowWagerMarkets.MarketAnalytics? - A struct containing analytics for the market,
                                      or nil if the market is not found.
                                      (The MarketAnalytics struct is defined in FlowWagerMarkets.cdc)
*/

pub fun main(marketId: UInt64): FlowWagerMarkets.MarketAnalytics? {
    // Call the getMarketAnalytics function on the FlowWagerMarkets contract
    let analytics = FlowWagerMarkets.getMarketAnalytics(marketId: marketId)

    if analytics == nil {
        log("No analytics found for market ID: ".concat(marketId.toString()))
    } else {
        log("Market analytics retrieved for ID: ".concat(marketId.toString()))
        // Example: log("Total Volume: ".concat(analytics!.totalVolume.toString()))
    }

    return analytics
}
