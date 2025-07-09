import FlowWager from 0xFLOWWAGER_ADDRESS

// TODO: Replace 0xFLOWWAGER_ADDRESS with actual deployment address or flow.json alias.

/*
Script to get overall platform statistics.

Returns:
- {String: AnyStruct} - Platform-wide statistics from FlowWager.getPlatformStats().
*/

access(all) fun main(): {String: AnyStruct} {
    let stats = FlowWager.getPlatformStats()

    log("Platform statistics retrieved.")
    // Example logging:
    // log("Total Markets: ".concat((stats["totalMarkets"] as! UInt64).toString()))

    return stats
}
