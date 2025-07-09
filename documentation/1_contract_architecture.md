# FlowWager Platform - Contract Architecture

## 1. Overview

The FlowWager platform is a decentralized prediction market built on the Flow blockchain. It allows users to create and participate in prediction markets on various topics, with a unique focus on creator economics and a multi-admin resolution system. The platform utilizes FLOW tokens for all transactions.

The smart contract system is designed to be modular, with responsibilities separated into distinct contracts for clarity, maintainability, and upgradeability.

## 2. Core Contracts and Their Roles

The platform consists of the following primary smart contracts:

*   **`FlowWager.cdc` (Main Contract)**
    *   **Purpose:** The central hub of the platform. Manages the lifecycle of prediction markets, user predictions, admin capabilities, and core financial operations.
    *   **Key Responsibilities:**
        *   Market creation, including fee collection (or waiver for admins).
        *   Storing and managing `Market` resources.
        *   Handling user predictions (bet placement).
        *   Market resolution logic (triggered by authorized admins).
        *   Managing winnings claims by users.
        *   Admin management (adding/removing admins, storing `AdminCapability` resources).
        *   Platform fee collection and withdrawal.
        *   Holding the main FLOW token vault for all platform funds (bets, fees).
        *   Tracking user activity: counts of markets created per user and predictions placed per user.
    *   **Key Resources:** `Market`, `AdminCapability`.
    *   **Key State:** `markets` (dictionary of `Market` resources), `admins`, `adminCapabilities`, `platformVault`, `nextMarketId`, constants for fees and durations, `userMarketsCreatedCount`, `userPredictionsPlacedCount`.

*   **`FlowWagerEvents.cdc` (Event Definitions)**
    *   **Purpose:** Defines all events emitted by the FlowWager platform. This allows off-chain services and UIs to easily track contract activity.
    *   **Key Responsibilities:** Solely defines event structures. It does not hold state or have callable functions beyond `init`.
    *   **Examples of Events:** `MarketCreated`, `PredictionPlaced`, `MarketResolved`, `AdminAdded`, `FeesDistributed`.

*   **`FlowWagerSecurity.cdc` (Security and Validation Logic)**
    *   **Purpose:** Provides security-related validation functions, constants, and emergency control mechanisms.
    *   **Key Responsibilities:**
        *   Defining security constants (e.g., `MAX_BET_AMOUNT`, `MIN_BET_AMOUNT`).
        *   Providing validation functions for market parameters (title, description, duration), bet amounts, evidence URLs, etc.
        *   Implementing security checks like rate limiting (e.g., market creation per day) and admin action cooldowns.
        *   Managing system-wide emergency mode (enable/disable).
        *   Managing the pausing and unpausing of individual markets.
    *   **Key State:** `isEmergencyModeActive`, `pausedMarkets`, state for rate limits and cooldowns.

*   **`FlowWagerAdmin.cdc` (Advanced Admin Management & Logging)**
    *   **Purpose:** Handles more detailed aspects of administration, including evidence management for resolutions and comprehensive logging of admin actions.
    *   **Key Responsibilities:**
        *   Defining admin roles (enum).
        *   Managing submission and storage of `Evidence` for market resolutions.
        *   Logging `AdminAction` details for auditability.
        *   Providing functions to retrieve admin action history and market resolution history.
        *   (Placeholder for) Calculating admin performance metrics.
    *   **Key State:** `adminActionsLog`, `marketEvidenceStore`.

*   **`FlowWagerMarkets.cdc` (Market Analytics and Creator Stats)**
    *   **Purpose:** Provides functions to query aggregated analytics about markets, platform activity, and creator performance.
    *   **Key Responsibilities:**
        *   Calculating and returning detailed `MarketAnalytics` (volume, participants, etc.).
        *   Calculating and returning `CreatorStats` (markets created, volume generated, earnings).
        *   Providing functions to get top creators, markets by volume, and category-specific statistics (noting on-chain performance considerations for these).
        *   Calculating overall platform analytics.
    *   **Data Source:** Relies on an interface (`MarketDataProvider`) implemented by `FlowWager.cdc` to access necessary market data. This promotes decoupling but requires `FlowWager.cdc` to expose this data.

## 3. Key Design Principles

*   **Resource-Oriented Programming:** Core assets like `Market` and `AdminCapability` are implemented as Cadence resources, ensuring they are valuable, have clear ownership, and are managed according to Cadence's safety rules.
*   **Modularity and Separation of Concerns:** Each contract has a well-defined responsibility, making the system easier to understand, test, and potentially upgrade (e.g., upgrading the analytics contract without affecting the core market logic).
*   **Capability-Based Access Control:** Admin functions are protected by requiring an `AdminCapability` resource, which itself contains fine-grained permissions.
*   **Event-Driven Architecture:** Comprehensive event emission allows off-chain services to build rich user experiences and perform data analysis.
*   **Security First:** Validation, rate limiting, emergency controls, and admin action logging are incorporated to enhance platform integrity and safety.
*   **Creator Economics:** The fee structure is designed to reward market creators, a core tenet of the platform.

## 4. Data Flow and Interactions (High-Level)

*   **Market Creation:** User (via transaction) -> `FlowWager.createMarket` (pays fee if non-admin, fee to `platformVault`) -> `Market` resource created & stored -> `MarketCreated` event. (May call `FlowWagerSecurity` for validation).
*   **Prediction:** User (via transaction) -> `FlowWager.placePrediction` (FLOW to `platformVault`) -> `Market` resource updated -> `PredictionPlaced` event. (May call `FlowWagerSecurity` for validation).
*   **Resolution:** Admin (via transaction with `AdminCapability`) -> `FlowWager.resolveMarket` (may involve evidence from `FlowWagerAdmin`) -> `Market` resource updated -> `MarketResolved` event. Admin action logged in `FlowWagerAdmin`.
*   **Analytics:** Script/UI calls `FlowWagerMarkets` functions -> `FlowWagerMarkets` calls `FlowWager` (as `MarketDataProvider`) to get data -> Aggregated stats returned.

## 5. Important Considerations from Implementation

*   **`claimWinnings` in `FlowWager.cdc`:** Requires modification to return `@FungibleToken.Vault` for secure and idiomatic fund transfer to users.
*   **Helper Functions in `FlowWager.cdc`:** Several scripts and transactions rely on new public helper functions in `FlowWager.cdc` for safe data access (e.g., `getUserWinningsFromMarket`, `getAdminPermissions`, `triggerMarketStatusUpdate`).
*   **Creator Fee Payout:** The mechanism for creators to claim their share of fees from `FlowWager.cdc` needs full implementation.
*   **`FlowWagerMarkets.MarketDataProvider`:** `FlowWager.cdc` must implement this interface and track necessary data (e.g., `totalPredictionTransactions` per market, creator earnings).
*   **Gas Costs for Analytics/Batching:** On-chain analytics queries and batch operations can be gas-intensive. This is noted in relevant contracts and tests.
*   **Event Emission:** All `emit` statements in contracts need to be uncommented and correctly wired.

## 6. Future Enhancements / Considerations
*   Dispute resolution mechanism.
*   Advanced off-chain indexing for analytics and user history.
*   Gas optimizations for high-traffic functions.
*   Governance mechanisms for platform parameters.

This architecture provides a robust foundation for the FlowWager platform. Further details on specific functions and state variables can be found in the respective contract source code and function reference documentation.
