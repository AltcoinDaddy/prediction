# Unit Tests for FlowWagerAdmin.cdc

This document outlines test cases for the `FlowWagerAdmin.cdc` smart contract.

## Setup
- Deploy `FlowWager.cdc` (for `AdminCapabilityPublic` interface and potentially market data access).
- Deploy `FlowWagerEvents.cdc`.
- Deploy `FlowWagerAdmin.cdc`.
- Create accounts: `AdminUser` (with an `AdminCapabilityPublic` from `FlowWager.cdc`), `User1`.
- Mock `AdminCapabilityPublic` if direct interaction with `FlowWager.cdc` is complex for unit tests. This mock should allow setting an owner address and permissions.
- Market ID `101` can be used for tests involving `marketId`.

## 1. Initialization

1.  **Test Case: Contract Deployment**
    *   **Action:** Deploy `FlowWagerAdmin.cdc`.
    *   **Assertions:**
        *   Contract deploys successfully.
        *   `adminActionsLog` is empty.
        *   `nextAdminActionId` is 1.
        *   `marketEvidenceStore` is empty.

## 2. Evidence Management (`submitEvidence`, `createEvidenceObject`, `getSubmittedEvidenceForMarket`, `validateEvidence`)

*   **Setup:** `AdminUser` has an `AdminCapabilityPublic` (mock or real). Let's assume `AdminUser.address` is `0xADMIN`.

1.  **Test Case: `createEvidenceObject()` - Factory Function**
    *   **Action:** Call `FlowWagerAdmin.createEvidenceObject(marketId: 101, url: "http://evidence.com/1", description: "Initial evidence", submitter: 0xADMIN)`.
    *   **Assertions:**
        *   Returns an `Evidence` struct instance.
        *   Fields match input parameters.
        *   `timestamp` is set to current block timestamp.

2.  **Test Case: `submitEvidence()` - Successful Submission**
    *   **Action:** `AdminUser` (via their capability) calls `FlowWagerAdmin.submitEvidence(marketId: 101, url: "http://evidence.com/2", description: "Submitted evidence", submitterAdminCap: AdminUserCap)`.
    *   **Assertions:**
        *   Returns an `Evidence` struct.
        *   The `Evidence` struct is added to `marketEvidenceStore[101]`.
        *   `getSubmittedEvidenceForMarket(101)` now returns an array containing this evidence.
        *   An `AdminAction` is logged for "submit_evidence" with correct details.
        *   `nextAdminActionId` increments.
        *   (Event `EvidenceSubmitted` or `AdminActionLogged` emitted - once integrated).

3.  **Test Case: `submitEvidence()` - Multiple Submissions for Same Market**
    *   **Action:**
        1. `AdminUser` submits evidence E1 for market 101.
        2. `AdminUser` submits evidence E2 for market 101.
    *   **Assertions:**
        *   `marketEvidenceStore[101]` contains both E1 and E2.
        *   Two "submit_evidence" actions logged.

4.  **Test Case: `submitEvidence()` - Submission for Different Markets**
    *   **Action:**
        1. `AdminUser` submits evidence E1 for market 101.
        2. `AdminUser` submits evidence E3 for market 102.
    *   **Assertions:**
        *   `marketEvidenceStore[101]` contains E1.
        *   `marketEvidenceStore[102]` contains E3.

5.  **Test Case: `submitEvidence()` Fails - Empty URL**
    *   **Action:** `AdminUser` calls `submitEvidence` with `url: ""`.
    *   **Assertions:** Transaction/call panics due to pre-condition.

6.  **Test Case: `getSubmittedEvidenceForMarket()` - Market with No Evidence**
    *   **Action:** Call `getSubmittedEvidenceForMarket(marketId: 777)` (market with no evidence submitted).
    *   **Assertions:** Returns an empty array `[]`.

7.  **Test Case: `validateEvidence()`**
    *   Create an `Evidence` struct `ev1` with valid URL "https://valid.url".
    *   Create an `Evidence` struct `ev2` with invalid URL "ftp://invalid.url".
    *   **Action & Assertions:**
        *   `FlowWagerAdmin.validateEvidence(evidence: ev1)` returns `true`.
        *   `FlowWagerAdmin.validateEvidence(evidence: ev2)` returns `false`.

## 3. Admin Action Logging (`logAdminAction`, `getAdminActions`, `getMarketResolutionHistory`)

1.  **Test Case: `logAdminAction()` - Successful Logging**
    *   **Action:** `AdminUser` (via their capability) calls `FlowWagerAdmin.logAdminAction(adminCap: AdminUserCap, actionType: "test_action", marketId: 101, targetAddress: nil, details: {"key": "value"}, success: true, reason: nil)`.
    *   **Assertions:**
        *   A new `AdminAction` is appended to `adminActionsLog`.
        *   The logged action has fields matching the input, `adminAddress` is `AdminUser.address`, `actionId` is current `nextAdminActionId`.
        *   `nextAdminActionId` increments.
        *   (`AdminActionLogged` event emitted - once integrated).

2.  **Test Case: `getAdminActions()` - Filter by Admin**
    *   **Setup:**
        *   `AdminUser1` logs action A1.
        *   `AdminUser2` logs action A2.
        *   `AdminUser1` logs action A3.
    *   **Action & Assertions:**
        *   `getAdminActions(adminAddress: AdminUser1.address)` returns `[A1, A3]`.
        *   `getAdminActions(adminAddress: AdminUser2.address)` returns `[A2]`.
        *   `getAdminActions(adminAddress: User1.address)` (non-admin or admin with no logged actions) returns `[]`.

3.  **Test Case: `getMarketResolutionHistory()` - Filter by Market and Action Type**
    *   **Setup:**
        *   Log action M1: `admin: AdminUser1, actionType: "submit_evidence", marketId: 101`.
        *   Log action M2: `admin: AdminUser1, actionType: "resolve_market", marketId: 101`.
        *   Log action M3: `admin: AdminUser1, actionType: "add_admin", marketId: nil`.
        *   Log action M4: `admin: AdminUser1, actionType: "resolve_market", marketId: 102`.
    *   **Action & Assertions:**
        *   `getMarketResolutionHistory(marketId: 101)` returns `[M1, M2]`.
        *   `getMarketResolutionHistory(marketId: 102)` returns `[M4]`.
        *   `getMarketResolutionHistory(marketId: 103)` (no relevant actions) returns `[]`.

## 4. Admin Performance (`getAdminPerformance`)

1.  **Test Case: `getAdminPerformance()` - Basic Functionality**
    *   **Setup:** `AdminUser` has logged a few actions.
    *   **Action:** Call `FlowWagerAdmin.getAdminPerformance(adminAddress: AdminUser.address)`.
    *   **Assertions:**
        *   Returns a struct `{String: AnyStruct}`.
        *   `adminAddress` field matches `AdminUser.address`.
        *   `totalActionsLogged` field reflects the count of actions logged by `AdminUser`.
        *   Other placeholder metrics are present. (Actual metrics would need dedicated tests if implemented).

## TODO for `FlowWagerAdmin.cdc` implementation based on tests:
-   Integrate `FlowWagerEvents.cdc` for emitting `AdminActionLogged` and potentially other events like `EvidenceSubmitted`.
-   Refine the `AdminCapabilityPublic` interface and its usage, particularly `ownerAddress()`. Ensure alignment with `FlowWager.cdc`.
-   Consider pagination or limits for `getAdminActions` and `getMarketResolutionHistory` if logs can grow very large, for script call gas limits.
-   If `details: {String: String}` in `AdminAction` is too restrictive, evaluate alternatives for storing complex details.

---
This covers `FlowWagerAdmin.cdc`. Next, I'll outline tests for `FlowWagerMarkets.cdc`.
