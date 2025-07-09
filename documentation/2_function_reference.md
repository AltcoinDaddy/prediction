# FlowWager Platform - Function Reference (FlowWager.cdc - Key Public Functions)

This document provides a reference for key public functions in the main `FlowWager.cdc` contract. For a complete list and internal functions, please refer to the source code.

## Core Market Operations

---

**`pub fun createMarket(title: String, description: String, category: UInt8, endTime: UFix64, options: [String], payment: @FungibleToken.Vault): UInt64`**

*   **Description:** Creates a new prediction market. Also increments the market creator's count in `userMarketsCreatedCount`.
*   **Parameters:**
    *   `title: String`: The title of the market.
    *   `description: String`: Detailed description of the market.
    *   `category: UInt8`: Raw value of the `MarketCategory` enum.
    *   `endTime: UFix64`: Timestamp when the market betting closes. Must adhere to `MIN_MARKET_DURATION` and `MAX_MARKET_DURATION`.
    *   `options: [String]`: An array of strings representing the possible outcomes (at least 2).
    *   `payment: @FungibleToken.Vault`: A vault containing FLOW tokens for the market creation fee. Fee is waived if the transaction signer (owner of the vault) is an admin or the deployer. The vault should contain at least `MARKET_CREATION_FEE` if a fee is applicable.
*   **Returns:** `UInt64` - The ID of the newly created market.
*   **Events Emitted:** `MarketCreated` (from `Market` resource initialization).
*   **Side Effects:**
    *   Creates and stores a new `Market` resource.
    *   Increments `nextMarketId`.
    *   Updates `userMarketsCreatedCount` for the creator.
    *   If fee is applicable, transfers `MARKET_CREATION_FEE` from `payment` vault to the contract's `platformVault`.
*   **Panics:** If parameters are invalid (e.g., duration, options length, category), or if fee payment fails when required.

---

**`pub fun placePrediction(marketId: UInt64, option: String, payment: @FungibleToken.Vault)`**

*   **Description:** Allows a user to place a prediction (bet) on an active market. Also increments the predictor's count in `userPredictionsPlacedCount`.
*   **Parameters:**
    *   `marketId: UInt64`: The ID of the market to bet on.
    *   `option: String`: The chosen outcome from the market's options.
    *   `payment: @FungibleToken.Vault`: A vault containing the FLOW amount for the prediction. The entire balance of this vault is taken as the bet amount.
*   **Events Emitted:** `PredictionPlaced` (from `Market` resource).
*   **Side Effects:**
    *   Updates the specified `Market` resource: increases `totalPool`, updates option-specific pool, records user's prediction.
    *   Updates `userPredictionsPlacedCount` for the predictor.
    *   Transfers FLOW from `payment` vault to the contract's `platformVault`.
*   **Panics:** If market not found, not active, past `endTime`, option invalid, or payment amount is zero.

---

**`pub fun resolveMarket(marketId: UInt64, outcome: String, evidenceURL: String, adminCapRef: &AdminCapability)`**

*   **Description:** Allows an authorized admin to resolve a market that is pending resolution.
*   **Parameters:**
    *   `marketId: UInt64`: The ID of the market to resolve.
    *   `outcome: String`: The determined winning outcome. Must be one of the market's options.
    *   `evidenceURL: String`: A URL pointing to evidence supporting the resolution.
    *   `adminCapRef: &AdminCapability`: A reference to the calling admin's `AdminCapability` resource, proving their authorization and permissions (requires "resolve_market" permission).
*   **Events Emitted:** `MarketResolved` (from `Market` resource).
*   **Side Effects:**
    *   Updates the specified `Market` resource: sets `status` to `Resolved`, `outcome`, `evidenceURL`, and `resolutionTimestamp`.
    *   (Potentially logs action via `FlowWagerAdmin.cdc`).
*   **Panics:** If market not found, not in `PendingResolution` status, outcome invalid, evidence URL empty, or admin lacks permission.

---

**`pub fun claimWinnings(marketId: UInt64, userAddress: Address): @FungibleToken.Vault`**
**(NOTE: This signature reflects a *required* modification for the transaction `claim_winnings.cdc` to work as intended for fund transfer. The original contract prompt for `FlowWager.cdc` did NOT have a return type for this function. If this function is not changed, the `claim_winnings.cdc` transaction will not correctly transfer funds.)**

*   **Description:** Allows a user to claim their winnings from a resolved market.
*   **Parameters:**
    *   `marketId: UInt64`: The ID of the resolved market.
    *   `userAddress: Address`: The address of the user claiming winnings. Typically the transaction signer.
*   **Returns:** `@FungibleToken.Vault` - A vault containing the user's winnings in FLOW. Balance will be 0.0 if no winnings or already claimed.
*   **Events Emitted:** `WinningsClaimed` (if winnings > 0).
*   **Side Effects:**
    *   Calculates user's winnings based on their predictions and market outcome, accounting for platform/creator fees.
    *   Withdraws the winnings amount from the contract's `platformVault`.
    *   Marks the user's predictions in the `Market` resource as claimed (to prevent double claims).
*   **Panics:** If market not found, or not in a resolved state that allows claims.

---

## Admin Management

**`pub fun addAdmin(adminAddress: Address, permissions: [String], adminCapRef: &AdminCapability)`**

*   **Description:** Allows an admin with "manage_admins" permission to add a new admin.
*   **Parameters:**
    *   `adminAddress: Address`: The address of the account to grant admin privileges.
    *   `permissions: [String]`: An array of permission strings for the new admin (e.g., `["resolve_market"]`, `["all"]`).
    *   `adminCapRef: &AdminCapability`: Reference to the calling admin's capability.
*   **Events Emitted:** `AdminAdded`.
*   **Side Effects:** Creates a new `AdminCapability` resource, stores it in `adminCapabilities`, and adds `adminAddress` to `admins` list.
*   **Panics:** If caller lacks "manage_admins" permission, or if `adminAddress` is already an admin.

---

**`pub fun removeAdmin(adminAddress: Address, adminCapRef: &AdminCapability)`**

*   **Description:** Allows an admin with "manage_admins" permission to remove another admin (cannot remove deployer or self).
*   **Parameters:**
    *   `adminAddress: Address`: The address of the admin to remove.
    *   `adminCapRef: &AdminCapability`: Reference to the calling admin's capability.
*   **Events Emitted:** `AdminRemoved`.
*   **Side Effects:** Removes the `AdminCapability` resource from `adminCapabilities` (and destroys it), and removes `adminAddress` from `admins` list.
*   **Panics:** If caller lacks "manage_admins" permission, or attempts to remove deployer/self, or if `adminAddress` is not an admin.

---

## View Functions (Examples)

**`pub fun getMarket(marketId: UInt64): {String: AnyStruct}?`**

*   **Description:** Retrieves detailed information about a specific market. Automatically attempts to update market status to `PendingResolution` if active and past `endTime`.
*   **Returns:** A dictionary containing market details (id, title, status, pools, etc.), or `nil` if not found.

---

**`pub fun getAllMarkets(): [{String: AnyStruct}]`**

*   **Description:** Retrieves a list of all markets with their detailed information. Also attempts status updates.
*   **Returns:** An array of market detail dictionaries.

---

**`pub fun isAdmin(address: Address): Bool`**

*   **Description:** Checks if a given address has admin privileges.
*   **Returns:** `true` if the address is an admin, `false` otherwise.

---

**`pub fun getPlatformStats(): {String: AnyStruct}`**

*   **Description:** Retrieves overall platform statistics (total markets, vault balance, etc.).
*   **Returns:** A dictionary containing platform statistics.

---

## User Activity Tracking Functions (New)

**`pub fun getMarketsCreatedCountForUser(address: Address): UInt64`**

*   **Description:** Retrieves the total number of markets created by a specific user.
*   **Parameters:**
    *   `address: Address`: The address of the user.
*   **Returns:** `UInt64` - The count of markets created by the user, or 0 if the user has not created any or is not found.

---

**`pub fun getPredictionsPlacedCountForUser(address: Address): UInt64`**

*   **Description:** Retrieves the total number of predictions placed by a specific user across all markets.
*   **Parameters:**
    *   `address: Address`: The address of the user.
*   **Returns:** `UInt64` - The count of predictions placed by the user, or 0 if the user has not placed any or is not found.

---

**`pub fun getTotalUniqueMarketCreatorsCount(): UInt64`**

*   **Description:** Retrieves the total number of unique users who have created at least one market.
*   **Returns:** `UInt64` - The count of unique market creators.

---

**`pub fun getTotalUniquePredictorsCount(): UInt64`**

*   **Description:** Retrieves the total number of unique users who have placed at least one prediction.
*   **Returns:** `UInt64` - The count of unique predictors.

---

*(This is not an exhaustive list. Refer to `FlowWager.cdc`, `FlowWagerAdmin.cdc`, `FlowWagerSecurity.cdc`, and `FlowWagerMarkets.cdc` source code for all public functions and their details.)*

*(Helper functions like `triggerMarketStatusUpdate`, `getUserWinningsFromMarket`, `getAdminPermissions` that were identified as needed for scripts/transactions should also be documented here once added to `FlowWager.cdc`.)*
