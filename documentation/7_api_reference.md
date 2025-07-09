# FlowWager Platform - API Reference (Conceptual)

This document provides a conceptual overview of the "API" for interacting with the FlowWager smart contracts. In the context of smart contracts, the API consists of:

1.  **Public Contract Functions:** Functions callable directly on deployed contracts (often view functions or initialization).
2.  **Transactions:** Cadence code that users sign to propose state changes.
3.  **Scripts:** Cadence code used to read data from the blockchain without proposing state changes.

A full, detailed API reference would typically be generated or viewed using tools that understand Cadence and Flow Interaction Templates (FLIX), if available for the project. This guide lists the key interaction points.

## I. Contract Public Functions (View/Read Functions)

These are functions directly callable on the deployed contracts, primarily for reading state. They are used by scripts.

**From `FlowWager.cdc`:**
*   `getMarket(marketId: UInt64): {String: AnyStruct}?`
*   `getAllMarkets(): [{String: AnyStruct}]`
*   `getMarketsByCategory(category: UInt8): [{String: AnyStruct}]`
*   `getMarketsByStatus(status: UInt8): [{String: AnyStruct}]`
*   `isAdmin(address: Address): Bool`
*   `getPlatformStats(): {String: AnyStruct}`
*   `getUserPredictionsForMarket(marketId: UInt64, userAddress: Address): {String: UFix64}?`
*   *(New, required for scripts)* `getUserWinningsFromMarket(marketId: UInt64, userAddress: Address): UFix64?`
*   *(New, required for scripts)* `getAdminPermissions(address: Address): [String]?`
*   `getMarketsCreatedCountForUser(address: Address): UInt64` (New)
*   `getPredictionsPlacedCountForUser(address: Address): UInt64` (New)
*   `getTotalUniqueMarketCreatorsCount(): UInt64` (New)
*   `getTotalUniquePredictorsCount(): UInt64` (New)
*   Constants like `MARKET_CREATION_FEE`, `PLATFORM_FEE_RATE` are public state variables.
*   State variables `userMarketsCreatedCount: {Address: UInt64}` and `userPredictionsPlacedCount: {Address: UInt64}` are public.

**From `FlowWagerSecurity.cdc`:**
*   Validation functions (e.g., `validateMarketTitle`, `validateBetAmount`) - callable if made public and contract instance is accessible.
*   `getIsEmergencyModeActive(): Bool`
*   `getEmergencyModeReason(): String?`
*   `isMarketPaused(marketId: UInt64): Bool`
*   `getMarketPauseReason(marketId: UInt64): String?`
*   Public constants (e.g., `MAX_BET_AMOUNT`).

**From `FlowWagerAdmin.cdc`:**
*   `getAdminActions(adminAddress: Address): [AdminAction]`
*   `getMarketResolutionHistory(marketId: UInt64): [AdminAction]`
*   `getSubmittedEvidenceForMarket(marketId: UInt64): [Evidence]`
*   `getAdminPerformance(adminAddress: Address): {String: AnyStruct}` (placeholder)

**From `FlowWagerMarkets.cdc`:**
*   `getMarketAnalytics(marketId: UInt64): MarketAnalytics?`
*   `getCreatorStats(creatorAddress: Address): CreatorStats?`
*   `getTopCreators(limit: UInt64, sortBy: String): [CreatorStats]`
*   `getCategoryStats(): {UInt8: {String: AnyStruct}}`
*   `getMarketsByVolume(limit: UInt64): [UInt64]`
*   `getPlatformAnalytics(): {String: AnyStruct}`

## II. Transactions (State-Changing Operations)

These are defined in `.cdc` files within the `transactions/` directory. Users sign these with their wallets (via FCL) to interact with the platform.

*   **`create_market.cdc`**
    *   **Purpose:** Create a new prediction market.
    *   **Args:** `title: String, description: String, categoryRawValue: UInt8, endTime: UFix64, options: [String], marketCreationFeeAmount: UFix64`
    *   **Signer:** Market creator.
*   **`place_prediction.cdc`**
    *   **Purpose:** Place a bet on a market.
    *   **Args:** `marketId: UInt64, option: String, amount: UFix64`
    *   **Signer:** Bettor.
*   **`resolve_market.cdc`**
    *   **Purpose:** Admin resolves a market.
    *   **Args:** `marketId: UInt64, outcome: String, evidenceURL: String`
    *   **Signer:** Admin with "resolve_market" permission.
*   **`claim_winnings.cdc`**
    *   **Purpose:** User claims winnings from a resolved market.
    *   **Args:** `marketId: UInt64`
    *   **Signer:** Bettor who won.
    *   **Note:** Depends on `FlowWager.claimWinnings` returning `@FungibleToken.Vault`.
*   **`add_admin.cdc`**
    *   **Purpose:** Admin adds a new admin.
    *   **Args:** `newAdminAddress: Address, permissions: [String]`
    *   **Signer:** Admin with "manage_admins" permission.
*   **`remove_admin.cdc`**
    *   **Purpose:** Admin removes an existing admin.
    *   **Args:** `adminToRemoveAddress: Address`
    *   **Signer:** Admin with "manage_admins" permission.
*   **`withdraw_platform_fees.cdc`**
    *   **Purpose:** Admin withdraws platform fees.
    *   **Args:** `amount: UFix64, recipientAddress: Address`
    *   **Signer:** Admin with "withdraw_fees" permission.
*   **`emergency_resolve.cdc`**
    *   **Purpose:** Admin performs emergency resolution of a market.
    *   **Args:** `marketId: UInt64, outcome: String, evidenceURL: String`
    *   **Signer:** Admin with "emergency_resolve" permission.
*   **`update_market_status.cdc`**
    *   **Purpose:** Manually trigger a market status update (e.g., Active to PendingResolution).
    *   **Args:** `marketId: UInt64`
    *   **Signer:** Any user.
    *   **Note:** Depends on `FlowWager.triggerMarketStatusUpdate` helper function.
*   **`batch_resolve_markets.cdc`**
    *   **Purpose:** Admin resolves multiple markets in one transaction.
    *   **Args:** `marketResolutions: [{marketId: UInt64, outcome: String, evidenceURL: String}]`
    *   **Signer:** Admin with "resolve_market" permission.

*(Additional transactions might be needed for interacting with `FlowWagerSecurity` emergency functions or `FlowWagerAdmin` evidence submission if not done via other contract calls.)*

## III. Scripts (Read-Only Data Queries)

These are defined in `.cdc` files within the `scripts/` directory. They are executed to read data from the blockchain without cost to the user (beyond node provider fees if applicable).

*   **`get_market.cdc`**: Args: `marketId: UInt64`. Returns: Market details or nil.
*   **`get_all_markets.cdc`**: Args: None. Returns: Array of all market details.
*   **`get_markets_by_category.cdc`**: Args: `categoryRawValue: UInt8`. Returns: Array of market details.
*   **`get_markets_by_status.cdc`**: Args: `statusRawValue: UInt8`. Returns: Array of market details.
*   **`get_user_predictions.cdc`**: Args: `userAddress: Address`. Returns: Dict of user's predictions by market.
*   **`get_user_winnings.cdc`**: Args: `marketId: UInt64, userAddress: Address`. Returns: `UFix64?` (winnings amount). (Depends on `FlowWager.getUserWinningsFromMarket` helper).
*   **`get_platform_stats.cdc`**: Args: None. Returns: Platform statistics.
*   **`get_creator_stats.cdc`**: Args: `creatorAddress: Address`. Returns: `FlowWagerMarkets.CreatorStats?`.
*   **`get_admin_status.cdc`**: Args: `adminAddress: Address`. Returns: Admin status and permissions. (Depends on `FlowWager.getAdminPermissions` helper).
*   **`get_market_analytics.cdc`**: Args: `marketId: UInt64`. Returns: `FlowWagerMarkets.MarketAnalytics?`.

*(Additional scripts could be added to query specific data from `FlowWagerAdmin` like evidence lists or specific admin action logs, or new scripts for user activity counts.)*

## IV. Events

Refer to `FlowWagerEvents.cdc` for a complete list of events and their parameters. These are crucial for off-chain services and real-time UI updates. Examples: `MarketCreated`, `PredictionPlaced`, `MarketResolved`, `AdminAdded`, `WinningsClaimed`.

---

This conceptual API reference should be used in conjunction with the actual Cadence source files and any tools provided by the Flow ecosystem for interacting with smart contracts. For dApp development, FCL (Flow Client Library) is the primary tool for sending transactions and executing scripts.
