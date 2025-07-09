import FlowWager from 0xFLOWWAGER_ADDRESS

// TODO: Replace 0xFLOWWAGER_ADDRESS with actual deployment address or flow.json alias.

/*
Script to get a list of all markets with their detailed information.

Returns:
- [{String: AnyStruct}] - An array of market detail dictionaries.
                          Matches FlowWager.getAllMarkets() return.
*/

access(all) fun main(): [{String: AnyStruct}] {
    let allMarkets = FlowWager.getAllMarkets()

    log("Retrieved ".concat(allMarkets.length.toString()).concat(" markets."))

    return allMarkets
}
