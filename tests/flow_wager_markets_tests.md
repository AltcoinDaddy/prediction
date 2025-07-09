# Unit Tests for FlowWagerMarkets.cdc

This document outlines test cases for the `FlowWagerMarkets.cdc` smart contract. These tests heavily rely on a mockable or accessible `MarketDataProvider` interface, which would typically be implemented by `FlowWager.cdc`.

## Setup
- Deploy `FlowWager.cdc` (or a mock implementing `MarketDataProvider` interface defined in `FlowWagerMarkets.cdc`).
- The `FlowWager` contract instance (or mock) must publish its `MarketDataProvider` capability at a known `PublicPath` (e.g., `/public/FlowWagerMarketDataProvider`).
- Deploy `FlowWagerMarkets.cdc`, initializing it with the `Address` of the `FlowWager` contract and the `PublicPath` of its `MarketDataProvider` capability.
- Define mock `FlowWagerMarkets.MarketDataView` structs for test data. These structs would be returned by the mocked `MarketDataProvider`.
    - `MarketDataView1`: id=1, creator=0xCREATOR_A, category=0 (use `FlowWager.MarketCategory.Sports.rawValue`), totalPool=100.0, participantCount=10, totalPredictionsCount=15, creationTime=T1, endTime=T2, resolutionTimestamp=T3, status=`FlowWager.MarketStatus.Resolved`
    - `MarketDataView2`: id=2, creator=0xCREATOR_B, category=1 (use `FlowWager.MarketCategory.Politics.rawValue`), totalPool=200.0, participantCount=20, totalPredictionsCount=25, creationTime=T1, endTime=T3, resolutionTimestamp=nil, status=`FlowWager.MarketStatus.Active`
    - `MarketDataView3`: id=3, creator=0xCREATOR_A, category=0, totalPool=50.0, participantCount=5, totalPredictionsCount=5, creationTime=T2, endTime=T4, resolutionTimestamp=T5, status=`FlowWager.MarketStatus.Resolved`
- Mock `MarketDataProvider.getCreatorTotalEarnings(creatorAddress)` to return predefined earnings. E.g., `0xCREATOR_A` -> 10.0 FLOW, `0xCREATOR_B` -> 5.0 FLOW.
- (Assumes `FlowWager.cdc` is imported by `FlowWagerMarkets.cdc` for enum access like `FlowWager.MarketCategory`).

## 1. Initialization

1.  **Test Case: Contract Deployment and Initialization**
    *   **Action:** Deploy `FlowWagerMarkets.cdc` with the address of `FlowWager` and the public path to its `MarketDataProvider` capability.
    *   **Assertions:**
        *   Contract deploys successfully.
        *   `flowWagerContractAddress` and `marketDataProviderPublicPath` are set correctly.
        *   Attempting `getMarketDataProvider()` should succeed if the capability is correctly published by `FlowWager`.

## 2. `getMarketAnalytics()`

1.  **Test Case: Successful Analytics Retrieval for Resolved Market**
    *   **Mock Setup:** `MarketDataProvider` (borrowed from `flowWagerContractAddress`) returns `MarketDataView1` for `getMarketDataView(1)`.
    *   **Action:** Call `FlowWagerMarkets.getMarketAnalytics(marketId: 1)`.
    *   **Assertions:**
        *   Returns a `MarketAnalytics` struct.
        *   Fields match data from `MarketDataView1`:
            *   `marketId = 1`
            *   `totalVolume = 100.0`
            *   `participantCount = 10`
            *   `totalPredictionsCount = 15`
            *   `averageBetSize = 100.0 / 15.0`
            *   `createdAt = T1`, `endedAt = T2`, `resolvedAt = T3`
            *   `category = MarketDataView1.category.rawValue`
            *   `creator = 0xCREATOR_A`
            *   `resolutionTime = T3 - T2` (assuming T3 > T2)

2.  **Test Case: Successful Analytics Retrieval for Active Market**
    *   **Mock Setup:** `MarketDataProvider` returns `MarketDataView2` for `getMarketDataView(2)`.
    *   **Action:** Call `FlowWagerMarkets.getMarketAnalytics(marketId: 2)`.
    *   **Assertions:**
        *   Returns a `MarketAnalytics` struct.
        *   `resolvedAt` is `nil`.
        *   `resolutionTime` is `nil`.
        *   Other fields match `MarketDataView2`.

3.  **Test Case: Market Not Found**
    *   **Mock Setup:** `MarketDataProvider.getMarketDataView(999)` returns `nil`.
    *   **Action:** Call `FlowWagerMarkets.getMarketAnalytics(marketId: 999)`.
    *   **Assertions:** Returns `nil`.

## 3. `getCreatorStats()`

1.  **Test Case: Successful Stats Retrieval for Creator A**
    *   **Mock Setup:** `MarketDataProvider.getAllMarketDataViews()` returns `[MarketDataView1, MarketDataView2, MarketDataView3]`. `MarketDataProvider.getCreatorTotalEarnings(0xCREATOR_A)` returns `10.0`.
    *   **Action:** Call `FlowWagerMarkets.getCreatorStats(creatorAddress: 0xCREATOR_A)`.
    *   **Assertions:**
        *   Returns a `CreatorStats` struct.
        *   `address = 0xCREATOR_A`.
        *   `marketsCreated = 2`.
        *   `totalVolumeGenerated = 150.0`.
        *   `totalEarnings = 10.0`.
        *   `resolvedMarketsCount = 2`.
        *   `averageResolutionTime` calculated correctly.
        *   `successRate = 100.0`.

2.  **Test Case: Creator Not Found / No Markets**
    *   **Action:** Call `FlowWagerMarkets.getCreatorStats(creatorAddress: 0xUNKNOWN_CREATOR)`.
    *   **Assertions:** Returns `nil`.

## 4. `getTopCreators()` (Acknowledging inefficiency)

1.  **Test Case: Get Top 1 Creator by Volume**
    *   **Mock Setup:** (As above).
    *   **Action:** Call `FlowWagerMarkets.getTopCreators(limit: 1, sortBy: "totalVolumeGenerated")`.
    *   **Assertions:** Returns array with 1 `CreatorStats` element for `0xCREATOR_B`.

## 5. `getCategoryStats()`

1.  **Test Case: Statistics for All Categories**
    *   **Mock Setup:** (As above).
    *   **Action:** Call `FlowWagerMarkets.getCategoryStats()`.
    *   **Assertions:** Returns dictionary with correct aggregated stats per category.

## 6. `getMarketsByVolume()` (Acknowledging inefficiency)

1.  **Test Case: Get Top 2 Markets by Volume**
    *   **Mock Setup:** (As above).
    *   **Action:** Call `FlowWagerMarkets.getMarketsByVolume(limit: 2)`.
    *   **Assertions:** Returns `[MarketDataView2.id, MarketDataView1.id]`.

## 7. `getPlatformAnalytics()`

1.  **Test Case: Overall Platform Analytics**
    *   **Mock Setup:** (As above).
    *   **Action:** Call `FlowWagerMarkets.getPlatformAnalytics()`.
    *   **Assertions:** Correct `totalMarkets`, `totalPlatformVolume`, `activeMarkets`, `resolvedMarkets`.

## TODO for `FlowWagerMarkets.cdc` and `FlowWager.cdc` based on tests:
-   **`FlowWager.cdc` MUST implement the `MarketDataProvider` interface and publish the capability at the path specified in `FlowWagerMarkets.init`.**
-   `FlowWager.Market` resource needs to track `totalPredictionTransactions`.
-   `FlowWager.cdc` needs to provide `getCreatorTotalEarnings(creatorAddress)`.
-   Gas implications for iterating functions need to be kept in mind for production.

---
This completes the conceptual unit tests for `FlowWagerMarkets.cdc` with adjustments for Cadence 1.0 structure.
