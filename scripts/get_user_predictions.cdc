import FlowWager from "FlowWager"

// Imports are now named and will be resolved by flow.json

/*
Script to get all predictions made by a specific user across all markets.

Parameters:
- userAddress: Address - The address of the user whose predictions are to be retrieved.

Returns:
- {UInt64: {String: UFix64}}
  A dictionary where keys are market IDs and values are dictionaries
  of the user's predictions in that market (Option String -> Amount UFix64).
*/

access(all) fun main(userAddress: Address): {UInt64: {String: UFix64}} {
    let userMarketPredictions: {UInt64: {String: UFix64}} = {}

    // This script iterates all markets to find user-specific predictions.
    // For a large number of markets, this could be inefficient if called frequently.
    // Off-chain indexing might be better for high-performance user history.

    let allMarketsInfo = FlowWager.getAllMarkets()
    var marketIds: [UInt64] = []
    for marketInfo in allMarketsInfo {
        // Type assertion ensures we get UInt64, will panic if "id" is missing or not UInt64.
        // This is expected as getMarketInfo() from FlowWager.Market defines "id" as UInt64.
        marketIds.append(marketInfo["id"] as! UInt64)
    }

    log("Checking ".concat(marketIds.length.toString()).concat(" markets for user predictions by ").concat(userAddress.toString()))

    for marketId in marketIds {
        // FlowWager.getUserPredictionsForMarket is expected to return {String: UFix64}?
        let predictionsInMarket = FlowWager.getUserPredictionsForMarket(marketId: marketId, userAddress: userAddress)
        if predictionsInMarket != nil {
            userMarketPredictions[marketId] = predictionsInMarket!
        }
    }

    if userMarketPredictions.keys.length == 0 {
        log("No predictions found for user ".concat(userAddress.toString()).concat(" in any market."))
    } else {
        log("Found predictions in ".concat(userMarketPredictions.keys.length.toString()).concat(" markets for user ").concat(userAddress.toString()))
    }

    return userMarketPredictions
}
