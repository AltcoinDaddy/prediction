import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Script to get a list of markets filtered by a specific category.

Parameters:
- categoryRawValue: UInt8 - The raw UInt8 value for the market category to filter by.

Returns:
- [{String: AnyStruct}] - An array of dictionaries, each representing a market in the specified category.
                          The structure matches FlowWager.getMarketsByCategory().
*/

pub fun main(categoryRawValue: UInt8): [{String: AnyStruct}] {
    // Validate if the categoryRawValue is a valid MarketCategory
    // FlowWager.MarketCategory.fromRawValue(categoryRawValue) will panic if invalid inside the contract function.
    // It's good practice for the script to also be aware, or trust the contract to handle it.
    // For now, assume the contract handles invalid raw values.

    let markets = FlowWager.getMarketsByCategory(category: categoryRawValue)

    log("Retrieved ".concat(markets.length.toString()).concat(" markets for category raw value: ").concat(categoryRawValue.toString()))

    return markets
}
