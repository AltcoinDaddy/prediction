# Unit Tests for FlowWager.cdc

This document outlines test cases for the `FlowWager.cdc` smart contract. These tests would typically be implemented using a Flow testing library (e.g., Flow JS Testing, Go testing).

## Setup
- Deploy `FungibleToken.cdc`, `FlowToken.cdc`.
- Deploy `FlowWagerEvents.cdc` (as FlowWager emits events).
- Deploy `FlowWagerSecurity.cdc` (as FlowWager might call validation functions).
- Deploy `FlowWager.cdc`, ensuring it's initialized correctly (deployer becomes admin).
- Create accounts: `Deployer`, `AdminUser` (distinct from Deployer, made admin later), `User1`, `User2`.
- Fund user accounts with FLOW.
- Helper function to get current block timestamp.
- Helper function to advance time (for testing market end, resolution windows).

## 1. Initialization (`init()`) Tests

1.  **Test Case: Contract Deployment and Initialization**
    *   **Action:** Deploy `FlowWager.cdc`.
    *   **Assertions:**
        *   Contract is deployed successfully.
        *   `deployer` state variable is set to the deployer's address.
        *   `nextMarketId` is initialized to 1.
        *   `MARKET_CREATION_FEE`, `PLATFORM_FEE_RATE`, etc., constants are set to their specified values.
        *   Platform vault (`platformVaultPath`) is created and exists in contract account storage.
        *   Deployer is an admin: `isAdmin(deployerAddress)` returns `true`.
        *   Deployer's `AdminCapability` is stored in `adminCapabilities` (or their account, based on final `AdminCapability` storage pattern in `FlowWager.cdc`). If stored in contract: `adminCapabilities[deployerAddress]` should exist and have "all" permission.
        *   `ContractInitialized` event is emitted (once event emission is uncommented).

## 2. `createMarket()` Tests

1.  **Test Case: Successful Market Creation by Non-Admin (Fee Paid)**
    *   **Setup:** `User1` has sufficient FLOW for market creation fee (e.g., 15 FLOW, fee is 10 FLOW).
    *   **Action:** `User1` calls `createMarket` transaction with valid parameters and a payment vault containing `MARKET_CREATION_FEE`.
        *   `title`: "Test Market 1"
        *   `description`: "Description for Test Market 1"
        *   `category`: `Sports.rawValue` (e.g., 0)
        *   `endTime`: `currentTime + MIN_MARKET_DURATION + 100.0`
        *   `options`: `["Yes", "No"]`
    *   **Assertions:**
        *   Transaction succeeds.
        *   Market ID 1 is returned.
        *   `nextMarketId` in contract becomes 2.
        *   `getMarket(1)` returns market details matching input parameters.
            *   `creator` is `User1.address`.
            *   `status` is `Active`.
            *   `totalPool` is 0.0.
            *   `pools` for "Yes" and "No" are 0.0.
        *   `User1`'s FLOW balance is reduced by `MARKET_CREATION_FEE`.
        *   `FlowWager` contract's `platformVault` balance increases by `MARKET_CREATION_FEE`.
        *   `MarketCreated` event is emitted with correct parameters (once uncommented).

2.  **Test Case: Successful Market Creation by Deployer/Admin (Fee Waived)**
    *   **Action:** `Deployer` calls `createMarket` transaction with valid parameters. The payment vault passed can be empty or contain 0 FLOW, and `marketCreationFeeAmount` in tx can be 0.0.
    *   **Assertions:**
        *   Transaction succeeds.
        *   A new market ID is returned (e.g., 1 if first market, or next available).
        *   `Deployer`'s FLOW balance is unchanged (no fee paid).
        *   `FlowWager` contract's `platformVault` balance is unchanged by this specific creation.
        *   Market is created successfully, details match.
        *   `MarketCreated` event emitted.

3.  **Test Case: Market Creation Fails - Insufficient Fee from Non-Admin**
    *   **Setup:** `User1` has less than `MARKET_CREATION_FEE`.
    *   **Action:** `User1` calls `createMarket` tx, `marketCreationFeeAmount` is `MARKET_CREATION_FEE`, but underlying vault has less.
    *   **Assertions:**
        *   Transaction fails (panic due to vault withdrawal insufficient balance or contract's assert).
        *   No market is created.
        *   `nextMarketId` remains unchanged.

4.  **Test Case: Market Creation Fails - Invalid End Time (Too Short Duration)**
    *   **Action:** `User1` calls `createMarket` with `endTime` such that `endTime - currentTime < MIN_MARKET_DURATION`.
    *   **Assertions:**
        *   Transaction fails (panic from `Market` resource `init` pre-condition).
        *   No market created.

5.  **Test Case: Market Creation Fails - Invalid End Time (Too Long Duration)**
    *   **Action:** `User1` calls `createMarket` with `endTime` such that `endTime - currentTime > MAX_MARKET_DURATION`.
    *   **Assertions:**
        *   Transaction fails (panic from `Market` resource `init` pre-condition).
        *   No market created.

6.  **Test Case: Market Creation Fails - End Time in Past**
    *   **Action:** `User1` calls `createMarket` with `endTime` < `currentTime`.
    *   **Assertions:**
        *   Transaction fails (panic from `Market` resource `init` pre-condition).

7.  **Test Case: Market Creation Fails - Invalid Category Raw Value**
    *   **Action:** `User1` calls `createMarket` with `categoryRawValue` that does not map to any `MarketCategory` enum (e.g., 99).
    *   **Assertions:**
        *   Transaction fails (panic from `MarketCategory.fromRawValue()` or contract pre-condition).

8.  **Test Case: Market Creation Fails - Empty Title/Description/Options**
    *   **Action:** Call `createMarket` with empty title.
    *   **Assertions:** Transaction fails (panic from `Market` init or `FlowWagerSecurity` validation).
    *   Repeat for empty description, and options array with < 2 elements.

## 3. `placePrediction()` Tests

*   **Setup for Prediction Tests:**
    *   A market (e.g., Market ID 1) is created and is `Active`.
    *   `User1` and `User2` have sufficient FLOW.

1.  **Test Case: Successful Prediction**
    *   **Action:** `User1` calls `placePrediction` transaction for Market ID 1, option "Yes", amount 10.0 FLOW.
    *   **Assertions:**
        *   Transaction succeeds.
        *   `getMarket(1)` shows:
            *   `totalPool` increased by 10.0.
            *   `pools["Yes"]` increased by 10.0.
            *   `predictions[User1.address]["Yes"]` is 10.0 (or reflects the new total if prior bets).
            *   `participantCount` updates correctly.
        *   `FlowWager` contract's `platformVault` balance increases by 10.0.
        *   `User1`'s FLOW balance decreases by 10.0.
        *   `PredictionPlaced` event emitted with correct parameters.

2.  **Test Case: Successful Multiple Predictions by Same User on Same Option**
    *   **Action:**
        1. `User1` predicts 10.0 on "Yes".
        2. `User1` predicts another 5.0 on "Yes".
    *   **Assertions:**
        *   `predictions[User1.address]["Yes"]` is 15.0.
        *   `totalPool` and `pools["Yes"]` are correctly updated (increased by 15.0 total).

3.  **Test Case: Successful Multiple Predictions by Same User on Different Options**
    *   **Action:**
        1. `User1` predicts 10.0 on "Yes".
        2. `User1` predicts 5.0 on "No".
    *   **Assertions:**
        *   `predictions[User1.address]["Yes"]` is 10.0.
        *   `predictions[User1.address]["No"]` is 5.0.
        *   `totalPool` is 15.0. `pools["Yes"]` is 10.0, `pools["No"]` is 5.0.

4.  **Test Case: Successful Predictions by Different Users**
    *   **Action:**
        1. `User1` predicts 10.0 on "Yes".
        2. `User2` predicts 20.0 on "No".
    *   **Assertions:**
        *   `predictions[User1.address]["Yes"]` is 10.0.
        *   `predictions[User2.address]["No"]` is 20.0.
        *   `totalPool` is 30.0. `pools["Yes"]` is 10.0, `pools["No"]` is 20.0.
        *   `participantCount` reflects 2 participants.

5.  **Test Case: Prediction Fails - Market Not Active (e.g., PendingResolution or Resolved)**
    *   **Setup:** Market 1's status is changed to `PendingResolution` (e.g., advance time past `endTime` and call `triggerMarketStatusUpdate`).
    *   **Action:** `User1` attempts to predict on Market 1.
    *   **Assertions:** Transaction fails (panic from `Market.placePrediction` pre-condition).

6.  **Test Case: Prediction Fails - Market Has Ended (CurrentTime > EndTime)**
    *   **Setup:** Advance time past Market 1's `endTime`. Market status might still be `Active` if not updated.
    *   **Action:** `User1` attempts to predict on Market 1.
    *   **Assertions:** Transaction fails (panic from `Market.placePrediction` pre-condition `getCurrentBlock().timestamp < self.endTime`).

7.  **Test Case: Prediction Fails - Invalid Option**
    *   **Action:** `User1` attempts to predict on Market 1 with option "Maybe" (not in `market.options`).
    *   **Assertions:** Transaction fails (panic from `Market.placePrediction` pre-condition).

8.  **Test Case: Prediction Fails - Amount is Zero or Negative**
    *   **Action:** `User1` attempts to predict with amount 0.0 or -5.0.
    *   **Assertions:** Transaction fails (panic from tx `amount > 0.0` or contract pre-condition).

9.  **Test Case: Prediction Fails - Market ID Does Not Exist**
    *   **Action:** `User1` attempts to predict on Market ID 999 (non-existent).
    *   **Assertions:** Transaction fails (panic from `FlowWager.placePrediction` pre-condition `self.markets[marketId] != nil`).

10. **Test Case: Prediction Fails - Insufficient FLOW Balance for Bet**
    *   **Setup:** `User1` has 5 FLOW.
    *   **Action:** `User1` attempts to predict 10 FLOW.
    *   **Assertions:** Transaction fails (panic from `vaultRef.withdraw` in tx `prepare` block).

## 4. Admin Management Tests (`addAdmin`, `removeAdmin`, `isAdmin`)

*   **Setup:** `Deployer` is admin. `User1` is not admin.

1.  **Test Case: `isAdmin` Check**
    *   **Assertions:**
        *   `FlowWager.isAdmin(deployerAddress)` returns `true`.
        *   `FlowWager.isAdmin(User1.address)` returns `false`.

2.  **Test Case: Deployer Adds New Admin Successfully**
    *   **Action:** `Deployer` calls `addAdmin` transaction for `User1.address` with permissions `["resolve_market"]`.
    *   **Assertions:**
        *   Transaction succeeds.
        *   `FlowWager.isAdmin(User1.address)` now returns `true`.
        *   `FlowWager.adminCapabilities[User1.address]` exists and has `["resolve_market"]` permission. (Or check via `getAdminPermissions` if added).
        *   `AdminAdded` event emitted.

3.  **Test Case: New Admin Uses Their Permissions (e.g., to resolve, if that's the permission given)**
    *   **Setup:** `User1` is now an admin with "resolve_market" permission. Create and end a market.
    *   **Action:** `User1` calls `resolveMarket` transaction.
    *   **Assertions:** Transaction succeeds (assuming other conditions for resolution are met).

4.  **Test Case: `addAdmin` Fails - Caller Not an Admin**
    *   **Action:** `User2` (non-admin) attempts to call `addAdmin` for `User1.address`.
    *   **Assertions:** Transaction fails (panic due to missing `AdminCapability` or permission check in `addAdmin`).

5.  **Test Case: `addAdmin` Fails - Caller Lacks "manage_admins" Permission**
    *   **Setup:** `Deployer` adds `User1` as admin with only `["resolve_market"]` permission.
    *   **Action:** `User1` attempts to call `addAdmin` for `User2.address`.
    *   **Assertions:** Transaction fails (panic from `addAdmin` permission check `adminCapRef.hasPermission(permission: "manage_admins")`).

6.  **Test Case: Deployer Removes Admin Successfully**
    *   **Setup:** `User1` is an admin.
    *   **Action:** `Deployer` calls `removeAdmin` transaction for `User1.address`.
    *   **Assertions:**
        *   Transaction succeeds.
        *   `FlowWager.isAdmin(User1.address)` now returns `false`.
        *   `FlowWager.adminCapabilities[User1.address]` is removed.
        *   `AdminRemoved` event emitted.

7.  **Test Case: `removeAdmin` Fails - Caller Not an Admin**
    *   **Action:** `User2` (non-admin) attempts to call `removeAdmin` for `User1.address`.
    *   **Assertions:** Transaction fails.

8.  **Test Case: `removeAdmin` Fails - Attempt to Remove Deployer**
    *   **Setup:** `Deployer` adds `User1` as admin with `["all"]` permissions.
    *   **Action:** `User1` (now a full admin) attempts to call `removeAdmin` for `Deployer.address`.
    *   **Assertions:** Transaction fails (panic from `removeAdmin` pre-condition `adminAddress != self.deployer`).

9.  **Test Case: `removeAdmin` Fails - Admin Tries to Remove Self via this function**
    *   **Action:** `Deployer` attempts to call `removeAdmin` for `Deployer.address`.
    *   **Assertions:** Transaction fails (panic from `removeAdmin` pre-condition `adminAddress != adminCapRef.adminAddress`).

## 5. `resolveMarket()` and `emergencyResolveMarket()` Tests

*   **Setup for Resolution Tests:**
    *   Market 1 created by `User1`. Predictions placed by `User1` (10 on "Yes") and `User2` (20 on "No"). Total pool 30.
    *   `AdminUser` (can be `Deployer` or another admin with `resolve_market` / `emergency_resolve` permission).
    *   Advance time past Market 1's `endTime`.
    *   Call `triggerMarketStatusUpdate(marketId: 1)` to set status to `PendingResolution`.

1.  **Test Case: Successful Market Resolution**
    *   **Action:** `AdminUser` calls `resolveMarket` for Market 1, outcome "Yes", evidenceURL "http://example.com/evidence.html".
    *   **Assertions:**
        *   Transaction succeeds.
        *   `getMarket(1)` shows:
            *   `status` is `Resolved`.
            *   `outcome` is "Yes".
            *   `evidenceURL` is "http://example.com/evidence.html".
            *   `resolutionTimestamp` is set.
        *   `MarketResolved` event emitted.

2.  **Test Case: Resolution Fails - Market Not PendingResolution (e.g., Active)**
    *   **Setup:** Market 1 is `Active` (don't advance time or don't call `triggerMarketStatusUpdate`).
    *   **Action:** `AdminUser` attempts `resolveMarket`.
    *   **Assertions:** Transaction fails (panic from `resolveMarket` pre-condition `market.status == MarketStatus.PendingResolution`).

3.  **Test Case: Resolution Fails - Invalid Outcome**
    *   **Action:** `AdminUser` calls `resolveMarket` with outcome "Maybe" (not in `market.options`).
    *   **Assertions:** Transaction fails (panic from `Market.internalResolve` pre-condition).

4.  **Test Case: Resolution Fails - Caller Lacks "resolve_market" Permission**
    *   **Setup:** `User1` (non-admin or admin without `resolve_market` perm) has an `AdminCapability` (if they are admin with other perms).
    *   **Action:** `User1` attempts `resolveMarket`.
    *   **Assertions:** Transaction fails.

5.  **Test Case: Successful Emergency Market Resolution**
    *   **Setup:** Market 1 `PendingResolution`. `AdminUser` has `emergency_resolve` permission.
    *   **Action:** `AdminUser` calls `emergencyResolveMarket` for Market 1, outcome "No", evidence "http://emergency.com".
    *   **Assertions:**
        *   Transaction succeeds.
        *   Market status is `EmergencyResolved`.
        *   Outcome and evidence are set.
        *   `MarketEmergencyResolved` event emitted.

6.  **Test Case: `emergencyResolveMarket` Fails - Caller Lacks "emergency_resolve" Permission**
    *   **Setup:** `AdminUser` has `resolve_market` but not `emergency_resolve` permission.
    *   **Action:** `AdminUser` attempts `emergencyResolveMarket`.
    *   **Assertions:** Transaction fails.

## 6. `claimWinnings()` Tests (ASSUMES `claimWinnings` returns `@FungibleToken.Vault`)

*   **Setup for Winnings Tests:**
    *   Market 1 resolved with outcome "Yes".
    *   `User1` predicted 10 on "Yes". `User2` predicted 20 on "No". Total pool 30.
    *   Platform fee 2%, Creator fee 1% (Total 3% = 0.9 FLOW from pool).
    *   Pool available for winners: 30 - 0.9 = 29.1 FLOW.
    *   Winning pool ("Yes" pool) was 10 FLOW.
    *   `User1`'s share: (10/10) * 29.1 = 29.1 FLOW. (This calculation needs to be exact as per `Market.getUserWinnings`)
        *   Let's re-verify `Market.getUserWinnings` logic:
            `winnings = (userBetOnWinningOutcome / winningPool) * (self.totalPool - (self.totalPool * (FlowWager.PLATFORM_FEE_RATE + FlowWager.CREATOR_FEE_RATE)))`
            If `User1` bet 10 on "Yes", `winningPool` ("Yes" pool) is 10.
            `winnings = (10 / 10) * (30.0 - (30.0 * (0.02 + 0.01)))`
            `winnings = 1 * (30.0 - (30.0 * 0.03))`
            `winnings = 1 * (30.0 - 0.9)`
            `winnings = 29.1`
            This implies the winner of a binary market gets the entire post-fee pool if they are the only one on the winning side. This seems correct for this formula.

1.  **Test Case: Successful Winnings Claim by Winner**
    *   **Action:** `User1` calls `claimWinnings` transaction for Market 1.
    *   **Assertions:**
        *   Transaction succeeds.
        *   `User1`'s FLOW balance increases by 29.1 (approx, considering UFix64 precision).
        *   `FlowWager` contract's `platformVault` balance decreases by 29.1.
        *   `getMarket(1).predictions[User1.address]` is removed or marked claimed.
        *   `WinningsClaimed` event emitted.

2.  **Test Case: Attempt to Claim Winnings by Loser**
    *   **Action:** `User2` (who bet on "No") calls `claimWinnings` for Market 1.
    *   **Assertions:**
        *   Transaction succeeds (doesn't panic if `claimWinnings` handles 0 balance vault).
        *   `User2`'s FLOW balance is unchanged.
        *   The returned vault from `FlowWager.claimWinnings` has 0.0 balance.
        *   No `WinningsClaimed` event for a positive amount, or event shows 0.

3.  **Test Case: Attempt to Claim Winnings Twice by Winner**
    *   **Action:**
        1. `User1` successfully claims winnings.
        2. `User1` calls `claimWinnings` again for Market 1.
    *   **Assertions:**
        *   Second transaction succeeds.
        *   `User1`'s FLOW balance is unchanged by the second claim.
        *   Returned vault from second call has 0.0 balance.

4.  **Test Case: Claim Winnings Fails - Market Not Resolved**
    *   **Setup:** Market 1 is `PendingResolution`.
    *   **Action:** `User1` attempts `claimWinnings`.
    *   **Assertions:** Transaction fails (panic from `FlowWager.claimWinnings` pre-condition, as it calls `market.getUserWinnings` which checks status).

5.  **Test Case: Claim Winnings Fails - Market ID Does Not Exist**
    *   **Action:** `User1` attempts `claimWinnings` for Market 999.
    *   **Assertions:** Transaction fails.


## 7. Fee-Related Function Tests (`withdrawPlatformFees`)

*   **Setup:**
    *   Several markets created and fees paid, resulting in e.g., 50 FLOW in `platformVault` from creation fees.
    *   Market 1 resolved. Total pool 30. Platform fee (2%) = 0.6 FLOW. Creator fee (1%) = 0.3 FLOW.
    *   The `platformVault` now also contains these fees from resolved markets.
    *   `AdminUser` has `withdraw_fees` permission.
    *   `FeeRecipient` account created, with a `/public/flowTokenReceiver`.

1.  **Test Case: Successful `withdrawPlatformFees`**
    *   **Action:** `AdminUser` calls `withdrawPlatformFees` tx, amount 20.0, recipient `FeeRecipient.address`.
    *   **Assertions:**
        *   Transaction succeeds.
        *   `FlowWager` `platformVault` balance decreases by 20.0.
        *   `FeeRecipient`'s FLOW balance increases by 20.0.
        *   `PlatformFeesWithdrawn` event emitted.

2.  **Test Case: `withdrawPlatformFees` Fails - Insufficient Platform Vault Balance**
    *   **Action:** `AdminUser` attempts to withdraw 100.0 (more than available).
    *   **Assertions:** Transaction fails (panic from `platformVaultRef.balance >= amount` or `withdraw`).

3.  **Test Case: `withdrawPlatformFees` Fails - Caller Lacks "withdraw_fees" Permission**
    *   **Setup:** `AdminUser` does not have `withdraw_fees` permission.
    *   **Action:** `AdminUser` attempts `withdrawPlatformFees`.
    *   **Assertions:** Transaction fails.

4.  **Test Case: `withdrawPlatformFees` Fails - Invalid Recipient (No Receiver)**
    *   **Setup:** `BadRecipient` account does *not* have a published `/public/flowTokenReceiver`.
    *   **Action:** `AdminUser` attempts `withdrawPlatformFees` to `BadRecipient.address`.
    *   **Assertions:** Transaction fails (panic when trying to get `feeReceiverCap`).

## 8. View Function Tests (`getMarket`, `getAllMarkets`, etc.)

*   These are generally tested implicitly by other tests that verify state changes.
*   Explicit tests would call the script versions of these and verify the output structure and content against known state.

1.  **Test Case: `getMarket()`** - Covered by `createMarket` tests.
2.  **Test Case: `getAllMarkets()`** - Create 2-3 markets, call script, verify array length and content.
3.  **Test Case: `getMarketsByCategory()`** - Create markets in different categories, call script for one category, verify results.
4.  **Test Case: `getMarketsByStatus()`** - Change market statuses, call script, verify. Ensure `trySetToPendingResolution` is triggered for relevant markets.
5.  **Test Case: `getPlatformStats()`** - After various operations, call script, verify key stats (totalMarkets, vaultBalance, etc.).

## 9. `triggerMarketStatusUpdate()` Test (via transaction `update_market_status.cdc`)

*   **Setup:** Market 1 created, `endTime` is in the past, but status is still `Active`.
*   **Action:** Call `update_market_status.cdc` transaction for Market 1.
*   **Assertions:**
    *   Transaction succeeds.
    *   `getMarket(1).status` is now `PendingResolution`.
    *   `MarketStatusUpdated` or `MarketPendingResolution` event emitted by the contract.

## TODO for `FlowWager.cdc` implementation based on these tests:
- Ensure `Market.trySetToPendingResolution()` emits `MarketStatusUpdated` or `MarketPendingResolution` event if status changes.
- Add `FlowWager.getAdminPermissions(address: Address): [String]?` function.
- Add `FlowWager.getUserWinningsFromMarket(marketId: UInt64, userAddress: Address): UFix64?` function.
- Add `FlowWager.triggerMarketStatusUpdate(marketId: UInt64)` function.
- **Critically: Modify `FlowWager.claimWinnings` to return `@FungibleToken.Vault`.**
- Implement creator fee payout mechanism (e.g., `claimCreatorFee` function and tracking). Tests for this are currently missing as the feature is not fully in `FlowWager.cdc`.
- Uncomment all event emissions in `FlowWager.cdc` and `Market` resource.
- Wire up calls to `FlowWagerSecurity` validation functions if they are to be used.
- Add `totalPredictionTransactions` counter to `Market` resource for analytics.

## 10. User Activity Tracking Tests (New Feature)

*   **Setup:** `User1`, `User2`, `User3` accounts. `FlowWager.cdc` initialized (activity count dictionaries are empty).

1.  **Test Case: Initial Activity Counts are Zero**
    *   **Assertions:**
        *   `FlowWager.getMarketsCreatedCountForUser(User1.address)` returns 0.
        *   `FlowWager.getPredictionsPlacedCountForUser(User1.address)` returns 0.
        *   `FlowWager.getTotalUniqueMarketCreatorsCount()` returns 0.
        *   `FlowWager.getTotalUniquePredictorsCount()` returns 0.

2.  **Test Case: `createMarket` Updates Creator Counts**
    *   **Action:**
        1. `User1` creates Market 1.
        2. `User2` creates Market 2.
        3. `User1` creates Market 3.
    *   **Assertions:**
        *   `FlowWager.getMarketsCreatedCountForUser(User1.address)` returns 2.
        *   `FlowWager.getMarketsCreatedCountForUser(User2.address)` returns 1.
        *   `FlowWager.getMarketsCreatedCountForUser(User3.address)` returns 0.
        *   `FlowWager.getTotalUniqueMarketCreatorsCount()` returns 2.

3.  **Test Case: `placePrediction` Updates Predictor Counts**
    *   **Setup:** Market 1 is active.
    *   **Action:**
        1. `User1` places prediction on Market 1.
        2. `User2` places prediction on Market 1.
        3. `User1` places another prediction on Market 1.
        4. `User3` places prediction on Market 1.
    *   **Assertions:**
        *   `FlowWager.getPredictionsPlacedCountForUser(User1.address)` returns 2.
        *   `FlowWager.getPredictionsPlacedCountForUser(User2.address)` returns 1.
        *   `FlowWager.getPredictionsPlacedCountForUser(User3.address)` returns 1.
        *   `FlowWager.getTotalUniquePredictorsCount()` returns 3.

4.  **Test Case: Combined Activity**
    *   **Setup:**
        *   `User1` creates Market 1.
        *   `User1` places prediction on Market 1.
        *   `User2` places prediction on Market 1.
    *   **Assertions:**
        *   `FlowWager.getMarketsCreatedCountForUser(User1.address)` returns 1.
        *   `FlowWager.getPredictionsPlacedCountForUser(User1.address)` returns 1.
        *   `FlowWager.getPredictionsPlacedCountForUser(User2.address)` returns 1.
        *   `FlowWager.getTotalUniqueMarketCreatorsCount()` returns 1.
        *   `FlowWager.getTotalUniquePredictorsCount()` returns 2.

---
This covers `FlowWager.cdc`. Next, I'll outline tests for `FlowWagerSecurity.cdc`.
`FlowWagerEvents.cdc` is primarily definitions, so it doesn't have much logic to unit test directly, other than ensuring it deploys. Its usage is tested via events emitted by other contracts.
