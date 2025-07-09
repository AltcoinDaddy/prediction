import FlowWager from 0xFLOWWAGER_ADDRESS

// TODO: Replace 0xFLOWWAGER_ADDRESS with actual deployment address or flow.json alias.

/*
Script to get a list of markets filtered by a specific status.

Parameters:
- statusRawValue: UInt8 - The raw UInt8 value for the market status.

Returns:
- [{String: AnyStruct}] - An array of market detail dictionaries with the specified status.
*/

access(all) fun main(statusRawValue: UInt8): [{String: AnyStruct}] {
    // The FlowWager.getMarketsByStatus function will panic if statusRawValue is invalid.
    let markets = FlowWager.getMarketsByStatus(status: statusRawValue)

    log("Retrieved ".concat(markets.length.toString()).concat(" markets for status raw value: ").concat(statusRawValue.toString()))

    return markets
}
