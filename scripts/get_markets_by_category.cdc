import FlowWager from "FlowWager"

// Imports are now named and will be resolved by flow.json

/*
Script to get a list of markets filtered by a specific category.

Parameters:
- categoryRawValue: UInt8 - The raw UInt8 value for the market category.

Returns:
- [{String: AnyStruct}] - An array of market detail dictionaries for the specified category.
*/

access(all) fun main(categoryRawValue: UInt8): [{String: AnyStruct}] {
    // The FlowWager.getMarketsByCategory function will panic if categoryRawValue is invalid.
    let markets = FlowWager.getMarketsByCategory(category: categoryRawValue)

    log("Retrieved ".concat(markets.length.toString()).concat(" markets for category raw value: ").concat(categoryRawValue.toString()))

    return markets
}
