import FlowWagerMarkets from 0xFLOWWAGER_MARKETS_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_MARKETS_CONTRACT_ADDRESS with actual deployment address.
// This also implies that FlowWagerMarkets contract is deployed and initialized
// with a reference to the main FlowWager contract instance.

/*
Script to get statistics for a specific market creator.

Parameters:
- creatorAddress: Address - The address of the creator.

Returns:
- FlowWagerMarkets.CreatorStats? - A struct containing the creator's statistics,
                                   or nil if the creator is not found or has no stats.
                                   (The CreatorStats struct is defined in FlowWagerMarkets.cdc)
*/

pub fun main(creatorAddress: Address): FlowWagerMarkets.CreatorStats? {
    // Call the getCreatorStats function on the FlowWagerMarkets contract
    let stats = FlowWagerMarkets.getCreatorStats(creatorAddress: creatorAddress)

    if stats == nil {
        log("No stats found for creator: ".concat(creatorAddress.toString()))
    } else {
        log("Creator stats retrieved for: ".concat(creatorAddress.toString()))
        // Example: log("Markets Created: ".concat(stats!.marketsCreated.toString()))
    }

    return stats
}
