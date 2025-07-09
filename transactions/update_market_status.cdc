import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Transaction to manually trigger a status update for a market.
Specifically, this can be used to transition an "Active" market that has passed its
endTime to "PendingResolution" if it hasn't automatically transitioned yet
(e.g., if view functions that do this haven't been called).

Parameters:
- marketId: UInt64 - The ID of the market to update.
*/

transaction(marketId: UInt64) {

    // let flowWagerRef: &FlowWager // Reference to the FlowWager contract or a specific interface.
                                 // For this, we need to call a method on the Market resource.
                                 // FlowWager.cdc would need a public function that gets the market
                                 // and calls trySetToPendingResolution() on it.

    // Let's assume FlowWager.cdc has a function like:
    // pub fun triggerMarketStatusUpdate(marketId: UInt64) {
    //     let market = self.markets[marketId] ?? panic("Market not found")
    //     market.trySetToPendingResolution()
    //     // Potentially other status updates could be triggered here too.
    // }
    // This function would be part of FlowWager.

    prepare(signer: AuthAccount) {
        // No specific signer state needed for this transaction, anyone can trigger it.
        // However, a reference to the contract might be needed if not calling statically.
        // As with previous transactions, assuming FlowWager.triggerMarketStatusUpdate can be called directly.

        // Example of borrowing a contract reference if needed:
        // self.flowWagerRef = getAccount(0xFLOWWAGER_CONTRACT_ADDRESS)
        //    .getCapability<&FlowWager{FlowWager.ContractPublic}>(FlowWager.ContractPublicPath)
        //    .borrow() ?? panic("Could not borrow FlowWager contract reference")
    }

    execute {
        // Call the assumed helper function on the FlowWager contract
        FlowWager.triggerMarketStatusUpdate(marketId: marketId)

        log("Attempted to update status for market ID: ".concat(marketId.toString()))
        log("If the market was Active and past its endTime, it should now be PendingResolution.")
        log("Check market status using a script (e.g., get_market.cdc) to confirm.")

        // Event MarketStatusUpdated (or MarketPendingResolution) might be emitted by the contract
        // if trySetToPendingResolution indeed changes the status.
    }
}

// Note: This transaction relies on a new public function `triggerMarketStatusUpdate(marketId: UInt64)`
// being added to `FlowWager.cdc`.
// The implementation of `FlowWager.triggerMarketStatusUpdate` would be:
//
// pub fun triggerMarketStatusUpdate(marketId: UInt64) {
//     let market = self.markets[marketId] ?? panic("Market not found")
//     // Call the public function on the Market resource
//     market.trySetToPendingResolution()
//     // If MarketStatusUpdated event is desired from this explicit action:
//     // FlowWagerEvents.emitMarketStatusUpdated(id: market.id, newStatus: market.status.rawValue, timestamp: getCurrentBlock().timestamp)
//     // However, trySetToPendingResolution itself should emit if it changes status for consistency.
// }
// The `Market.trySetToPendingResolution()` in `FlowWager.cdc` needs to be made `pub` if it isn't already,
// or this new wrapper function `triggerMarketStatusUpdate` is necessary.
// Currently, `Market.trySetToPendingResolution()` is `pub`. So FlowWager could expose a function:
// pub fun triggerMarketStatusUpdate(marketId: UInt64) {
//    let marketRef = self.markets[marketId] ?? panic("Market not found")
//    marketRef.trySetToPendingResolution() // This is fine.
// }
