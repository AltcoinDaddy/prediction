import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Script to get detailed information about a specific market.

Parameters:
- marketId: UInt64 - The ID of the market to retrieve.

Returns:
- {String: AnyStruct}? - A dictionary containing market details, or nil if not found.
                         The structure matches the one returned by FlowWager.getMarket().
                         This includes calling market.trySetToPendingResolution() before returning info.
*/

pub fun main(marketId: UInt64): {String: AnyStruct}? {
    // Call the getMarket view function on the FlowWager contract
    let marketInfo = FlowWager.getMarket(marketId: marketId)

    if marketInfo == nil {
        log("Market with ID ".concat(marketId.toString()).concat(" not found."))
    } else {
        log("Market details retrieved for ID: ".concat(marketId.toString()))
    }

    return marketInfo
}
