import FlowWager from "FlowWager"

// Imports are now named and will be resolved by flow.json

/*
Script to calculate a user's potential winnings from a specific resolved market.
This does not claim the winnings, only calculates what they would get.

Parameters:
- marketId: UInt64 - The ID of the market.
- userAddress: Address - The address of the user.

Returns:
- UFix64? - The amount of winnings, or nil if market not found/resolved or no winnings.
*/

access(all) fun main(marketId: UInt64, userAddress: Address): UFix64? {
    // This script relies on a helper function in FlowWager.cdc:
    // access(all) fun getUserWinningsFromMarket(marketId: UInt64, userAddress: Address): UFix64?
    // This helper should safely call the market resource's getUserWinnings method,
    // checking market status to prevent panics and returning nil if conditions aren't met.
    // Example implementation in FlowWager.cdc:
    //
    // access(all) fun getUserWinningsFromMarket(marketId: UInt64, userAddress: Address): UFix64? {
    //    // self.markets is access(self), so need to borrow through a capability or make it more accessible if called from outside.
    //    // However, since this is a script calling a public function on the *same* contract,
    //    // the contract function itself can access its own private state.
    //    let market = self.markets[marketId] // This is fine if called from within FlowWager contract
    //    if market == nil { return nil }
    //    // Ensure the market variable is treated as a reference if it's a resource.
    //    // If self.markets stores resources directly (e.g. @{UInt64: Market}), then 'market' is a reference.
    //    let marketRef = market!
    //    if (marketRef.status != MarketStatus.Resolved && marketRef.status != MarketStatus.EmergencyResolved) || marketRef.outcome == nil {
    //        return nil
    //    }
    //    return marketRef.getUserWinnings(user: userAddress)
    // }
    // The key is that `FlowWager.getUserWinningsFromMarket` must be implemented in FlowWager.cdc.

    let winningsAmount = FlowWager.getUserWinningsFromMarket(marketId: marketId, userAddress: userAddress)

    if winningsAmount == nil {
        log("Could not calculate winnings for user ".concat(userAddress.toString()).concat(" from market ID ").concat(marketId.toString()).concat(". Market might not exist, not be resolved, or user did not participate."))
    } else if winningsAmount! > 0.0 {
        log("User ".concat(userAddress.toString()).concat(" has potential winnings of ").concat(winningsAmount!.toString()).concat(" from market ID ").concat(marketId.toString()))
    } else {
        log("User ".concat(userAddress.toString()).concat(" has no winnings (0.0) from market ID ").concat(marketId.toString()).concat(" or has already claimed."))
    }

    return winningsAmount
}
