import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Script to get a list of markets filtered by a specific status.

Parameters:
- statusRawValue: UInt8 - The raw UInt8 value for the market status to filter by (e.g., Active, Resolved).

Returns:
- [{String: AnyStruct}] - An array of dictionaries, each representing a market with the specified status.
                          The structure matches FlowWager.getMarketsByStatus().
*/

pub fun main(statusRawValue: UInt8): [{String: AnyStruct}] {
    // Validate if the statusRawValue is a valid MarketStatus
    // FlowWager.MarketStatus.fromRawValue(statusRawValue) will panic if invalid inside the contract function.
    // For now, assume the contract handles invalid raw values.

    let markets = FlowWager.getMarketsByStatus(status: statusRawValue)

    log("Retrieved ".concat(markets.length.toString()).concat(" markets for status raw value: ").concat(statusRawValue.toString()))

    return markets
}
