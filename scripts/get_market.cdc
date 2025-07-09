import FlowWager from 0xFLOWWAGER_ADDRESS

// TODO: Replace 0xFLOWWAGER_ADDRESS with actual deployment address or flow.json alias.

/*
Script to get detailed information about a specific market.

Parameters:
- marketId: UInt64 - The ID of the market to retrieve.

Returns:
- {String: AnyStruct}? - Market details, or nil if not found.
                         Matches FlowWager.getMarket() return.
*/

access(all) fun main(marketId: UInt64): {String: AnyStruct}? {
    let marketInfo = FlowWager.getMarket(marketId: marketId)

    if marketInfo == nil {
        log("Market with ID ".concat(marketId.toString()).concat(" not found."))
    } else {
        log("Market details retrieved for ID: ".concat(marketId.toString()))
    }

    return marketInfo
}
