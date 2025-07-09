import FlowWagerMarkets from 0xFLOWWAGER_MARKETS_ADDRESS
// TODO: Replace 0xFLOWWAGER_MARKETS_ADDRESS with actual deployment address or flow.json alias.
// This script also assumes FlowWagerMarkets has been correctly initialized with the
// address of the FlowWager contract and the public path to its MarketDataProvider capability.

/*
Script to get statistics for a specific market creator.

Parameters:
- creatorAddress: Address - The address of the creator.

Returns:
- FlowWagerMarkets.CreatorStats? - Creator's statistics, or nil if not found.
                                   (CreatorStats struct is defined in FlowWagerMarkets.cdc)
*/

access(all) fun main(creatorAddress: Address): FlowWagerMarkets.CreatorStats? {
    let stats = FlowWagerMarkets.getCreatorStats(creatorAddress: creatorAddress)

    if stats == nil {
        log("No stats found for creator: ".concat(creatorAddress.toString()))
    } else {
        log("Creator stats retrieved for: ".concat(creatorAddress.toString()))
        // Example: log("Markets Created: ".concat(stats!.marketsCreated.toString()))
    }

    return stats
}
