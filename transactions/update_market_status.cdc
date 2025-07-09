import FlowWager from 0xFLOWWAGER_ADDRESS

// TODO: Replace 0xFLOWWAGER_ADDRESS with actual deployment address or flow.json alias.

/*
Transaction to manually trigger a status update for a market.
This can transition an "Active" market past its endTime to "PendingResolution".

Parameters:
- marketId: UInt64 - The ID of the market to update.
*/

transaction(marketId: UInt64) {

    // This transaction assumes a public function `triggerMarketStatusUpdate` exists on FlowWager.cdc.
    // access(all) fun triggerMarketStatusUpdate(marketId: UInt64) {
    //     let market = self.markets[marketId] ?? panic("Market not found")
    //     market.trySetToPendingResolution() // Market.trySetToPendingResolution should be access(all)
    //     // TODO: Consider emitting MarketStatusUpdated event here or ensure trySetToPendingResolution does.
    // }

    prepare(signer: AuthAccount) {
        // No specific signer state needed for this transaction as anyone can trigger it,
        // provided the target `triggerMarketStatusUpdate` function is public.
    }

    execute {
        FlowWager.triggerMarketStatusUpdate(marketId: marketId)

        log("Attempted to update status for market ID: ".concat(marketId.toString()))
        // MarketStatusUpdated or MarketPendingResolution event should be emitted by FlowWager contract
        // if the status was changed by trySetToPendingResolution.
    }
}
