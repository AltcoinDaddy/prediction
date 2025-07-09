import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Script to get a list of all markets with their detailed information.

Returns:
- [{String: AnyStruct}] - An array of dictionaries, each representing a market.
                          The structure matches FlowWager.getAllMarkets().
                          This includes calling market.trySetToPendingResolution() for relevant markets.
*/

pub fun main(): [{String: AnyStruct}] {
    let allMarkets = FlowWager.getAllMarkets()

    log("Retrieved ".concat(allMarkets.length.toString()).concat(" markets."))

    return allMarkets
}
