// MarketDataProvider.cdc
// This interface represents what FlowWagerMarkets expects the FlowWager contract to provide.

// Import FlowWagerTypes to access the MarketDataView struct.
import FlowWagerTypes from "./FlowWagerTypes.cdc"

access(all) contract interface MarketDataProvider {
    access(all) fun getAllMarketDataViews(): [FlowWagerTypes.MarketDataView]
    access(all) fun getMarketDataView(marketId: UInt64): FlowWagerTypes.MarketDataView?
    access(all) fun getCreatorTotalEarnings(creatorAddress: Address): UFix64
    // TODO: Ensure FlowWager.cdc has a public capability path for this interface, e.g., /public/FlowWagerMarketDataProvider
}
