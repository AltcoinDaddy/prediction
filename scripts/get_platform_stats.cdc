import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Script to get overall platform statistics.

Returns:
- {String: AnyStruct} - A dictionary containing platform-wide statistics,
                         as returned by FlowWager.getPlatformStats().
*/

pub fun main(): {String: AnyStruct} {
    let stats = FlowWager.getPlatformStats()

    log("Platform statistics retrieved:")
    // Example of logging some stats, if needed for CLI output.
    // log("- Total Markets: ".concat((stats["totalMarkets"] as! UInt64).toString()))
    // log("- Active Markets: ".concat((stats["activeMarkets"] as! UInt64).toString()))
    // log("- Platform Vault Balance: ".concat((stats["platformVaultBalance"] as! UFix64).toString()))

    return stats
}
