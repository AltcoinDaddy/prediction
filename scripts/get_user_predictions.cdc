import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Script to get all predictions made by a specific user across all markets.

Parameters:
- userAddress: Address - The address of the user whose predictions are to be retrieved.

Returns:
- {UInt64: {String: UFix64}}
  A dictionary where keys are market IDs (UInt64) and values are dictionaries
  representing the user's predictions in that market (Option String -> Amount UFix64).
  Example: {101: {"Yes": 50.0, "No": 0.0}, 102: {"OptionA": 25.0}}
*/

pub fun main(userAddress: Address): {UInt64: {String: UFix64}} {
    let userMarketPredictions: {UInt64: {String: UFix64}} = {}

    // To implement this, we need to iterate all markets, then for each market,
    // check if the user has predictions using FlowWager.getUserPredictionsForMarket.

    // First, get all market IDs. FlowWager.getAllMarkets() returns [{String: AnyStruct}].
    // We need a way to get just IDs or iterate through market objects if possible.
    // Let's assume getAllMarkets() is efficient enough for this, or FlowWager provides a getMarketIds(): [UInt64].
    // For now, using getAllMarkets() and extracting IDs.

    let allMarketsInfo = FlowWager.getAllMarkets()
    var marketIds: [UInt64] = []
    for marketInfo in allMarketsInfo {
        marketIds.append(marketInfo["id"] as! UInt64)
    }

    log("Checking ".concat(marketIds.length.toString()).concat(" markets for user predictions by ").concat(userAddress.toString()))

    for marketId in marketIds {
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
