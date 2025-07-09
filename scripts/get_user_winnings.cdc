import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Script to calculate a user's potential winnings from a specific resolved market.
This does not claim the winnings, only calculates what they would get.

Parameters:
- marketId: UInt64 - The ID of the market.
- userAddress: Address - The address of the user.

Returns:
- UFix64? - The amount of winnings the user is entitled to from this market.
            Returns nil if the market is not found, not resolved, or the user has no winnings.
            Returns 0.0 if the user participated but won nothing.
*/

pub fun main(marketId: UInt64, userAddress: Address): UFix64? {
    // Get the market resource/view first.
    // The FlowWager.Market resource has the getUserWinnings function.
    // We need a way to call this. FlowWager.cdc would need a public function:
    // pub fun calculateUserWinningsForMarket(marketId: UInt64, userAddress: Address): UFix64? {
    //     let market = self.markets[marketId]
    //     if market == nil { return nil }
    //     if market!.status != MarketStatus.Resolved && market!.status != MarketStatus.EmergencyResolved { return nil } // Or some other indicator for not claimable yet
    //     // Note: getUserWinnings itself has pre-conditions for status and outcome.
    //     // It might panic. A script-friendly version should handle this gracefully.
    //     // For now, assume if market is not resolved, getUserWinnings might panic or this check is sufficient.
    //     // A better approach:
    //     // if (market!.status == MarketStatus.Resolved || market!.status == MarketStatus.EmergencyResolved) && market!.outcome != nil {
    //     //    return market!.getUserWinnings(user: userAddress)
    //     // }
    //     // return 0.0 // or nil if not resolved / no winnings
    // }
    // For now, let's assume such a helper function exists in FlowWager.cdc for safe calling.

    // Let's name the assumed function in FlowWager: `getUserWinningsFromMarket`
    // pub fun getUserWinningsFromMarket(marketId: UInt64, userAddress: Address): UFix64? {
    //     let market = self.markets[marketId]
    //     if market == nil {
    //         log("Market not found")
    //         return nil
    //     }
    //     // Check if market is resolved, otherwise getUserWinnings might panic or return incorrect results.
    //     if (market!.status != MarketStatus.Resolved && market!.status != MarketStatus.EmergencyResolved) || market!.outcome == nil {
    //         log("Market is not resolved or outcome not set.")
    //         // Depending on desired behavior, could return 0.0 or nil.
    //         // Let's return nil if not in a claimable state for winnings.
    //         return nil
    //     }
    //     // If user has already claimed (predictions removed from market.predictions), getUserWinnings will return 0.0
    //     return market!.getUserWinnings(user: userAddress)
    // }

    let winningsAmount = FlowWager.getUserWinningsFromMarket(marketId: marketId, userAddress: userAddress)

    if winningsAmount == nil {
        log("Could not calculate winnings for user ".concat(userAddress.toString()).concat(" from market ID ").concat(marketId.toString()).concat(". Market might not exist, not be resolved, or user did not participate."))
    } else {
        if winningsAmount! > 0.0 {
            log("User ".concat(userAddress.toString()).concat(" has potential winnings of ").concat(winningsAmount!.toString()).concat(" from market ID ").concat(marketId.toString()))
        } else {
            log("User ".concat(userAddress.toString()).concat(" has no winnings (0.0) from market ID ").concat(marketId.toString()).concat(" or has already claimed."))
        }
    }

    return winningsAmount
}

// Note: This script relies on a new public function `getUserWinningsFromMarket(marketId: UInt64, userAddress: Address): UFix64?`
// being added to `FlowWager.cdc`. This function would safely wrap the call to the market resource's `getUserWinnings` method,
// checking market status to prevent panics and returning nil if conditions aren't met.
// The `Market.getUserWinnings()` in `FlowWager.cdc` is `pub`, so FlowWager could expose a function:
// pub fun getUserWinningsFromMarket(marketId: UInt64, userAddress: Address): UFix64? {
//    let marketRef = self.markets[marketId]
//    if marketRef == nil { return nil }
//    if (marketRef.status != MarketStatus.Resolved && marketRef.status != MarketStatus.EmergencyResolved) || marketRef.outcome == nil {
//        return nil
//    }
//    return marketRef.getUserWinnings(user: userAddress)
// }
