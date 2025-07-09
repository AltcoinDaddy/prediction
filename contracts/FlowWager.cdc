import FungibleToken from 0xSTANDARD_FUNGIBLE_TOKEN_ADDRESS
import FlowToken from 0xSTANDARD_FLOW_TOKEN_ADDRESS

// TODO: Replace 0xSTANDARD_FUNGIBLE_TOKEN_ADDRESS and 0xSTANDARD_FLOW_TOKEN_ADDRESS
// with actual addresses when deploying.

// import FlowWagerEvents from "./FlowWagerEvents.cdc" // TODO: Uncomment when FlowWagerEvents is used
// import FlowWagerSecurity from "./FlowWagerSecurity.cdc" // TODO: Uncomment when FlowWagerSecurity is used

pub contract FlowWager {

    pub enum MarketCategory: UInt8 {
        case Sports = 0
        case Politics = 1
        case Cryptocurrency = 2
        case Economics = 3
        case Entertainment = 4
        case Technology = 5
        case Science = 6
        case Lifestyle = 7
        case Weather = 8
        case Gaming = 9
        case Other = 10
        case Meta = 11 // For markets about FlowWager itself
    }

    pub enum MarketStatus: UInt8 {
        case Active = 0
        case PendingResolution = 1 // Market ended, awaiting admin resolution
        case Resolved = 2
        case Cancelled = 3 // In case a market needs to be cancelled
        case EmergencyResolved = 4 // Resolved through emergency mechanism
    }

    pub resource Market {
        pub let id: UInt64
        pub let title: String
        pub let description: String
        pub let category: MarketCategory
        pub let creator: Address
        pub let creationTime: UFix64
        pub let endTime: UFix64
        pub let options: [String]
        pub var status: MarketStatus
        pub var outcome: String?
        pub var evidenceURL: String?
        pub var resolutionTimestamp: UFix64?

        access(contract) let pools: {String: UFix64}
        access(contract) let predictions: {Address: {String: UFix64}}
        access(contract) var totalPool: UFix64
        access(contract) var participants: {Address: Bool}

        init(
            id: UInt64,
            title: String,
            description: String,
            category: MarketCategory,
            creator: Address,
            creationTime: UFix64,
            endTime: UFix64,
            options: [String]
        ) {
            // TODO: Integrate FlowWagerSecurity validation for title, description, duration
            // FlowWagerSecurity.validateMarketTitle(title)
            // FlowWagerSecurity.validateMarketDescription(description)
            // FlowWagerSecurity.validateMarketDuration(creationTime, endTime)
            pre {
                title.length > 0: "Market title cannot be empty"
                description.length > 0: "Market description cannot be empty"
                options.length >= 2: "Market must have at least two options"
                endTime > getCurrentBlock().timestamp: "Market end time must be in the future"
                (endTime - creationTime) >= FlowWager.MIN_MARKET_DURATION: "Market duration is less than minimum"
                (endTime - creationTime) <= FlowWager.MAX_MARKET_DURATION: "Market duration is greater than maximum"
            }
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.creator = creator
            self.creationTime = creationTime
            self.endTime = endTime
            self.options = options
            self.status = MarketStatus.Active
            self.outcome = nil
            self.evidenceURL = nil
            self.resolutionTimestamp = nil
            self.pools = {}
            for option in options {
                self.pools[option] = 0.0
            }
            self.predictions = {}
            self.totalPool = 0.0
            self.participants = {}

            // TODO: Emit MarketCreated event
            // FlowWagerEvents.emitMarketCreated(id: self.id, title: self.title, category: self.category.rawValue, creator: self.creator, endTime: self.endTime, options: self.options)
        }

        pub fun placePrediction(predictor: Address, option: String, amount: UFix64) {
            // TODO: Integrate FlowWagerSecurity validation for bet amount
            // FlowWagerSecurity.validateBetAmount(amount)
            pre {
                self.status == MarketStatus.Active: "Market is not active"
                getCurrentBlock().timestamp < self.endTime: "Market has ended"
                self.options.contains(option): "Invalid option provided"
                amount > 0.0: "Prediction amount must be positive"
            }

            self.pools[option] = (self.pools[option] ?? 0.0) + amount
            self.totalPool = self.totalPool + amount

            if self.predictions[predictor] == nil {
                self.predictions[predictor] = {}
            }
            let userPredictions = self.predictions[predictor]!
            userPredictions[option] = (userPredictions[option] ?? 0.0) + amount
            self.predictions[predictor] = userPredictions

            self.participants[predictor] = true

            // TODO: Emit PredictionPlaced event
            // FlowWagerEvents.emitPredictionPlaced(marketId: self.id, predictor: predictor, option: option, amount: amount, timestamp: getCurrentBlock().timestamp)
        }

        // Called by an admin via the main contract's resolveMarket
        access(contract) fun internalResolve(outcome: String, evidenceURL: String, resolver: Address) {
            pre {
                self.status == MarketStatus.PendingResolution || self.status == MarketStatus.Active : "Market is not in a resolvable state (Active or PendingResolution)"
                self.options.contains(outcome): "Invalid outcome for this market"
                evidenceURL.length > 0 : "Evidence URL cannot be empty" // Basic check; more robust validation in FlowWagerSecurity
            }
            self.outcome = outcome
            self.evidenceURL = evidenceURL
            self.status = MarketStatus.Resolved
            self.resolutionTimestamp = getCurrentBlock().timestamp

            // TODO: Emit MarketResolved event
            // FlowWagerEvents.emitMarketResolved(id: self.id, outcome: self.outcome!, resolver: resolver, evidenceURL: self.evidenceURL!, timestamp: self.resolutionTimestamp!)
        }

        access(contract) fun internalEmergencyResolve(outcome: String, evidenceURL: String, resolver: Address) {
            pre {
                // self.status can be Active, PendingResolution, or even Cancelled if overridden by emergency
                self.options.contains(outcome): "Invalid outcome for this market"
                evidenceURL.length > 0 : "Evidence URL cannot be empty"
            }
            self.outcome = outcome
            self.evidenceURL = evidenceURL
            self.status = MarketStatus.EmergencyResolved
            self.resolutionTimestamp = getCurrentBlock().timestamp
            // TODO: Emit MarketEmergencyResolution event
        }

        pub fun getUserWinnings(user: Address): UFix64 {
            pre {
                self.status == MarketStatus.Resolved || self.status == MarketStatus.EmergencyResolved : "Market is not yet resolved"
                self.outcome != nil : "Market outcome is not set"
            }

            let userPredictions = self.predictions[user]
            if userPredictions == nil { return 0.0 }

            let winningOption = self.outcome!
            let userBetOnWinningOutcome = userPredictions![winningOption] ?? 0.0
            if userBetOnWinningOutcome == 0.0 { return 0.0 }

            let winningPool = self.pools[winningOption]!
            // TODO: Critical - What if winningPool is 0.0? This will cause division by zero.
            // Add check: if winningPool == 0.0 { return 0.0 } and decide how to handle pool funds.
            if winningPool == 0.0 { // Safety check, though implies no winning bets if outcome was this option
                return 0.0
            }

            let winnings = (userBetOnWinningOutcome / winningPool) * (self.totalPool * (1.0 - FlowWager.PLATFORM_FEE_RATE - FlowWager.CREATOR_FEE_RATE))
            return winnings
        }

        // Called by FlowWager.claimWinnings
        access(contract) fun markUserWinningsClaimed(user: Address) {
            self.predictions.remove(key: user)
        }

        pub fun canEnableEmergencyResolution(): Bool {
            return self.status == MarketStatus.PendingResolution && (getCurrentBlock().timestamp > (self.endTime + FlowWager.RESOLUTION_WINDOW))
        }

        pub fun getMarketInfo(): {String: AnyStruct} {
            let poolsInfo: {String: UFix64} = {}
            for option in self.options {
                poolsInfo[option] = self.pools[option]
            }

            let userPredictionCounts : {String: UInt64} = {}
            for option in self.options {
                userPredictionCounts[option] = 0
            }

            for userAddr in self.predictions.keys {
                let userBets = self.predictions[userAddr]!
                for option in userBets.keys {
                    if userBets[option]! > 0.0 {
                       userPredictionCounts[option] = (userPredictionCounts[option] ?? 0) + 1
                    }
                }
            }

            return {
                "id": self.id,
                "title": self.title,
                "description": self.description,
                "category": self.category.rawValue,
                "creator": self.creator,
                "creationTime": self.creationTime,
                "endTime": self.endTime,
                "options": self.options,
                "status": self.status.rawValue,
                "outcome": self.outcome,
                "evidenceURL": self.evidenceURL,
                "resolutionTimestamp": self.resolutionTimestamp,
                "totalPool": self.totalPool,
                "pools": poolsInfo,
                "participantCount": UInt64(self.participants.keys.length)
                // "predictions": self.predictions // Might be too large/sensitive for public view
            }
        }

        // This would ideally be triggered by an off-chain oracle/keeper or a transaction.
        pub fun trySetToPendingResolution() {
            if self.status == MarketStatus.Active && getCurrentBlock().timestamp >= self.endTime {
                self.status = MarketStatus.PendingResolution
                // TODO: Emit MarketUpdated event
                // FlowWagerEvents.emitMarketUpdated(id: self.id, status: self.status.rawValue, timestamp: getCurrentBlock().timestamp)
            }
        }

        // Market resources are stored in the contract's `markets` dictionary and destroyed when explicitly removed.
        destroy() {
            // TODO: Log destruction if needed
        }
    }

    pub resource AdminCapability {
        pub let adminAddress: Address
        pub let permissions: [String]
        pub let grantedAt: UFix64

        init(adminAddress: Address, permissions: [String]) {
            self.adminAddress = adminAddress
            self.permissions = permissions
            self.grantedAt = getCurrentBlock().timestamp
        }

        pub fun hasPermission(permission: String): Bool {
            if self.permissions.contains("all") { return true }
            return self.permissions.contains(permission)
        }
    }

    pub let deployer: Address
    access(contract) var nextMarketId: UInt64
    access(self) let markets: @{UInt64: Market}
    access(self) let admins: {Address: Bool}
    access(self) let adminCapabilities: @{Address: AdminCapability}

    pub var userMarketsCreatedCount: {Address: UInt64}
    pub var userPredictionsPlacedCount: {Address: UInt64}

    pub let platformVaultPath: StoragePath
    pub let platformFeesReceiverPath: PublicPath

    pub let MARKET_CREATION_FEE: UFix64
    pub let PLATFORM_FEE_RATE: UFix64
    pub let CREATOR_FEE_RATE: UFix64
    pub let MIN_MARKET_DURATION: UFix64
    pub let MAX_MARKET_DURATION: UFix64
    pub let RESOLUTION_WINDOW: UFix64

    init() {
        self.deployer = self.account.address
        self.nextMarketId = 1
        self.markets <- {}
        self.admins = {}
        self.adminCapabilities <- {}
        self.userMarketsCreatedCount = {}
        self.userPredictionsPlacedCount = {}

        self.MARKET_CREATION_FEE = 10.0
        self.PLATFORM_FEE_RATE = 0.02
        self.CREATOR_FEE_RATE = 0.01
        self.MIN_MARKET_DURATION = 3600.0 // 1 hour
        self.MAX_MARKET_DURATION = 2592000.0 // 30 days
        self.RESOLUTION_WINDOW = 172800.0 // 48 hours

        self.platformVaultPath = /storage/flowWagerPlatformVault
        self.platformFeesReceiverPath = /public/flowWagerPlatformFeesReceiver

        let existingVault = self.account.storage.borrow<&FlowToken.Vault>(from: self.platformVaultPath)
        if existingVault == nil {
            self.account.storage.save(<-FlowToken.createEmptyVault(), to: self.platformVaultPath)
        }

        // The prompt says: access(contract) let adminCapabilities: @{Address: AdminCapability}
        // This implies the contract *stores* these resources for admins other than deployer.
        // Deployer's capability is saved to their own account storage.
        let deployerAdminOwnCap <- create AdminCapability(adminAddress: self.deployer, permissions: ["all"])
        self.account.storage.save(<-deployerAdminOwnCap, to: /storage/flowWagerAdminCapability_deployer)

        // For the contract's internal tracking and consistency with storing other admins' caps:
        let initialAdminCapForContractStorage <- create AdminCapability(adminAddress: self.deployer, permissions: ["all"])
        self.adminCapabilities.insert(key: self.deployer, <-initialAdminCapForContractStorage)
        self.admins[self.deployer] = true

        // TODO: Emit ContractInitialized event
        // FlowWagerEvents.emitContractInitialized(deployer: self.deployer, timestamp: getCurrentBlock().timestamp)

        log("FlowWager Contract Initialized")
    }

    pub fun createMarket(
        title: String,
        description: String,
        category: UInt8,
        endTime: UFix64,
        options: [String],
        payment: @FungibleToken.Vault
    ): UInt64 {
        // TODO: Integrate FlowWagerSecurity validation for title, description, duration
        pre {
            MarketCategory.fromRawValue(category) != nil : "Invalid market category"
        }

        let marketCreator = payment.owner!.address

        if marketCreator != self.deployer && !self.isAdmin(address: marketCreator) {
             assert(payment.balance >= self.MARKET_CREATION_FEE, message: "Insufficient payment for market creation fee")
             let feeVault <- payment.withdraw(amount: self.MARKET_CREATION_FEE)
             let platformVaultRef = self.account.storage.borrow<&FlowToken.Vault>(from: self.platformVaultPath)
                ?? panic("Could not borrow platform vault reference")
             platformVaultRef.deposit(from: <-feeVault)
        }

        let marketCategory = MarketCategory.fromRawValue(category) ?? panic("Invalid category raw value")

        let marketId = self.nextMarketId
        let newMarket <- create Market(
            id: marketId, title: title, description: description, category: marketCategory,
            creator: marketCreator, creationTime: getCurrentBlock().timestamp, endTime: endTime, options: options
        )

        let oldMarket <- self.markets.insert(key: marketId, <-newMarket)
        destroy oldMarket

        self.nextMarketId = self.nextMarketId + 1

        // TODO: Consider if MarketCreated event should be emitted here instead of Market init
        // FlowWagerEvents.emitMarketCreated(id: marketId, title: title, category: category, creator: marketCreator, endTime: endTime, options: options)

        // Passed-in payment vault is consumed (either fee taken or it was empty/not needed).
        destroy payment

        let currentCreatorCount = self.userMarketsCreatedCount[marketCreator] ?? 0
        self.userMarketsCreatedCount[marketCreator] = currentCreatorCount + 1

        return marketId
    }

    pub fun placePrediction(marketId: UInt64, option: String, payment: @FungibleToken.Vault) {
        // TODO: Integrate FlowWagerSecurity validation for bet amount
        pre {
            payment.balance > 0.0 : "Prediction amount must be positive"
            self.markets[marketId] != nil : "Market with the given ID does not exist"
        }
        let market = self.markets[marketId] ?? panic("Market not found")
        let predictor = payment.owner!.address

        market.placePrediction(predictor: predictor, option: option, amount: payment.balance)

        // Prediction payments are pooled in the central platformVault.
        let platformVaultRef = self.account.storage.borrow<&FlowToken.Vault>(from: self.platformVaultPath)
            ?? panic("Could not borrow platform vault reference for prediction")
        platformVaultRef.deposit(from: <-payment)

        let currentPredictorCount = self.userPredictionsPlacedCount[predictor] ?? 0
        self.userPredictionsPlacedCount[predictor] = currentPredictorCount + 1
    }

    pub fun resolveMarket(marketId: UInt64, outcome: String, evidenceURL: String, adminCapRef: &AdminCapability) {
        // TODO: Integrate FlowWagerSecurity validation for evidenceURL and admin permissions
        pre {
            self.markets[marketId] != nil : "Market not found"
            adminCapRef.hasPermission(permission: "resolve_market") : "Admin does not have permission to resolve markets"
            self.isAdmin(address: adminCapRef.adminAddress) : "Resolver is not a recognized admin or their capability is invalid."
        }

        let market = self.markets[marketId]!

        if market.status == MarketStatus.Active && getCurrentBlock().timestamp >= market.endTime {
             market.trySetToPendingResolution()
        }

        assert(market.status == MarketStatus.PendingResolution, message: "Market is not yet pending resolution. Ensure it has ended or try calling an update status transaction.")

        market.internalResolve(outcome: outcome, evidenceURL: evidenceURL, resolver: adminCapRef.adminAddress)

        // Note: Fees are implicitly handled by getUserWinnings. Explicit fee distribution to creator is a TODO.
        // TODO: Emit MarketResolved event (currently in Market.internalResolve)
        // TODO: Integrate FlowWagerAdmin.logAdminAction
    }

    // CRITICAL TODO: The original prompt's signature for claimWinnings (no return value) is problematic for secure fund transfer.
    // It should ideally return @FungibleToken.Vault or take a Receiver capability.
    // The current implementation only updates internal state.
    // The corresponding transaction `transactions/claim_winnings.cdc` assumes this function IS changed to return a vault.
    // This discrepancy MUST be resolved for the system to function correctly.
    pub fun claimWinnings(marketId: UInt64, userAddress: Address) {
        pre {
            self.markets[marketId] != nil : "Market not found"
        }
        let market = self.markets[marketId]!
        assert(market.status == MarketStatus.Resolved || market.status == MarketStatus.EmergencyResolved, message: "Market is not resolved yet.")
        assert(market.outcome != nil, message: "Market outcome is not set.")

        let winningsAmount = market.getUserWinnings(user: userAddress)

        if winningsAmount > 0.0 {
            // Actual fund transfer logic is missing here due to signature constraint.
            // If this function were to return a vault:
            // let platformVaultRef = self.account.storage.borrow<&FlowToken.Vault>(from: self.platformVaultPath) ?? panic("Could not borrow platform vault")
            // let userVault <- platformVaultRef.withdraw(amount: winningsAmount)
            // // Then return `userVault`

            market.markUserWinningsClaimed(user: userAddress)
            // TODO: Emit WinningsClaimed event
            // FlowWagerEvents.emitWinningsClaimed(marketId: marketId, winner: userAddress, amount: winningsAmount, timestamp: getCurrentBlock().timestamp)
        }
    }

    pub fun addAdmin(adminAddress: Address, permissions: [String], adminCapRef: &AdminCapability) {
        // TODO: Integrate FlowWagerSecurity.validateAdminPermissions
        pre {
            adminCapRef.hasPermission(permission: "manage_admins") : "Calling admin does not have permission to manage admins"
            self.isAdmin(address: adminCapRef.adminAddress) : "Caller is not a recognized admin."
            !self.isAdmin(address: adminAddress) : "Address is already an admin"
        }

        let newAdminCap <- create AdminCapability(adminAddress: adminAddress, permissions: permissions)
        let oldCap <- self.adminCapabilities.insert(key: adminAddress, <-newAdminCap)
        destroy oldCap

        self.admins[adminAddress] = true
        // TODO: Emit AdminAdded event
        // FlowWagerEvents.emitAdminAdded(admin: adminAddress, permissions: permissions, addedBy: adminCapRef.adminAddress, timestamp: getCurrentBlock().timestamp)
        log("Admin added")
    }

    pub fun removeAdmin(adminAddress: Address, adminCapRef: &AdminCapability) {
        pre {
            adminCapRef.hasPermission(permission: "manage_admins") : "Calling admin does not have permission to manage admins"
            self.isAdmin(address: adminCapRef.adminAddress) : "Caller is not a recognized admin."
            self.isAdmin(address: adminAddress) : "Address is not an admin"
            adminAddress != self.deployer : "Deployer admin cannot be removed"
            adminAddress != adminCapRef.adminAddress : "Admin cannot remove themselves using this function"
        }

        self.admins.remove(key: adminAddress)
        let removedCap <- self.adminCapabilities.remove(key: adminAddress)
        destroy removedCap
        // TODO: Emit AdminRemoved event
        // FlowWagerEvents.emitAdminRemoved(admin: adminAddress, removedBy: adminCapRef.adminAddress, timestamp: getCurrentBlock().timestamp)
        log("Admin removed")
    }

    // This function confirms if conditions for emergency resolution are met for a market.
    // Actual emergency resolution is a separate admin action.
    pub fun enableEmergencyResolution(marketId: UInt64) {
        pre {
            self.markets[marketId] != nil : "Market not found"
        }
        let market = self.markets[marketId]!
        assert(market.canEnableEmergencyResolution(), message: "Conditions for emergency resolution not met for this market.")

        // TODO: Emit MarketEligibleForEmergencyResolution event
        // FlowWagerEvents.emitMarketEmergencyResolutionEnabled(id: marketId, timestamp: getCurrentBlock().timestamp)
        log("Emergency resolution enabled for market ".concat(marketId.toString()))
    }

    pub fun emergencyResolveMarket(marketId: UInt64, outcome: String, evidenceURL: String, adminCapRef: &AdminCapability) {
        // TODO: Integrate FlowWagerSecurity.validateEvidenceURL
        pre {
            self.markets[marketId] != nil : "Market not found"
            adminCapRef.hasPermission(permission: "emergency_resolve") : "Admin does not have permission for emergency resolution." // TODO: Define this permission
        }
        let market = self.markets[marketId]!
        assert(market.status == MarketStatus.PendingResolution || market.status == MarketStatus.Active, "Market is not in a state that can be emergency resolved.")
        assert(getCurrentBlock().timestamp >= market.endTime, "Emergency resolution typically used for markets past their end time.")

        market.internalEmergencyResolve(outcome: outcome, evidenceURL: evidenceURL, resolver: adminCapRef.adminAddress)
        // Note: Fee distribution logic would be similar to normal resolution.
        // TODO: Emit MarketEmergencyResolved event (currently in Market.internalEmergencyResolve)
        // TODO: Integrate FlowWagerAdmin.logAdminAction
    }

    pub fun withdrawPlatformFees(amount: UFix64, recipient: &{FungibleToken.Receiver}, adminCapRef: &AdminCapability) {
        pre {
            adminCapRef.hasPermission(permission: "withdraw_fees") : "Admin does not have permission to withdraw platform fees"
            self.isAdmin(address: adminCapRef.adminAddress) : "Caller is not a recognized admin."
            amount > 0.0 : "Withdrawal amount must be positive"
        }

        let platformVaultRef = self.account.storage.borrow<&FlowToken.Vault>(from: self.platformVaultPath)
            ?? panic("Could not borrow platform vault reference for fee withdrawal")

        assert(platformVaultRef.balance >= amount, message: "Insufficient balance in platform vault for this withdrawal amount.")

        let feesVault <- platformVaultRef.withdraw(amount: amount)
        recipient.deposit(from: <-feesVault)

        // TODO: Emit PlatformFeesWithdrawn event
        // FlowWagerEvents.emitPlatformFeesWithdrawn(amount: amount, admin: adminCapRef.adminAddress, timestamp: getCurrentBlock().timestamp)
    }

    // VIEW FUNCTIONS
    pub fun getMarket(marketId: UInt64): {String: AnyStruct}? {
        if let market = self.markets[marketId] {
            if market.status == MarketStatus.Active && getCurrentBlock().timestamp >= market.endTime {
                 market.trySetToPendingResolution()
            }
            return market.getMarketInfo()
        }
        return nil
    }

    pub fun getAllMarkets(): [{String: AnyStruct}] {
        let allMarketInfos: [{String: AnyStruct}] = []
        let marketIds = self.markets.keys
        for id in marketIds {
            if let marketInfo = self.getMarket(marketId: id) {
                 allMarketInfos.append(marketInfo)
            }
        }
        return allMarketInfos
    }

    pub fun getMarketsByCategory(category: UInt8): [{String: AnyStruct}] {
        let categoryEnum = MarketCategory.fromRawValue(category) ?? panic("Invalid category raw value")
        let filteredMarketInfos: [{String: AnyStruct}] = []
        let marketIds = self.markets.keys
        for id in marketIds {
            let market = self.markets[id]!
            if market.category == categoryEnum {
                if market.status == MarketStatus.Active && getCurrentBlock().timestamp >= market.endTime {
                    market.trySetToPendingResolution()
                }
                filteredMarketInfos.append(market.getMarketInfo())
            }
        }
        return filteredMarketInfos
    }

    pub fun getMarketsByStatus(status: UInt8): [{String: AnyStruct}] {
        let statusEnum = MarketStatus.fromRawValue(status) ?? panic("Invalid status raw value")
        if statusEnum == MarketStatus.Active || statusEnum == MarketStatus.PendingResolution {
            for key in self.markets.keys {
                let market = self.markets[key]!
                if market.status == MarketStatus.Active && getCurrentBlock().timestamp >= market.endTime {
                    market.trySetToPendingResolution()
                }
            }
        }

        let filteredMarketInfos: [{String: AnyStruct}] = []
        let marketIds = self.markets.keys
        for id in marketIds {
            let market = self.markets[id]!
            if market.status == statusEnum {
                filteredMarketInfos.append(market.getMarketInfo())
            }
        }
        return filteredMarketInfos
    }

    pub fun isAdmin(address: Address): Bool {
        return self.admins[address] == true && self.adminCapabilities[address] != nil
    }

    pub fun getPlatformStats(): {String: AnyStruct} {
        var totalMarkets = 0
        var activeMarkets = 0
        var pendingResolutionMarkets = 0
        var resolvedMarkets = 0
        var totalVolumeAcrossAllMarkets = 0.0

        let platformVaultRef = self.account.storage.borrow<&FlowToken.Vault>(from: self.platformVaultPath)
            ?? panic("Could not borrow platform vault reference for stats")

        for key in self.markets.keys {
            let market = self.markets[key]!
            if market.status == MarketStatus.Active && getCurrentBlock().timestamp >= market.endTime {
                market.trySetToPendingResolution()
            }

            totalMarkets = totalMarkets + 1
            totalVolumeAcrossAllMarkets = totalVolumeAcrossAllMarkets + market.totalPool

            if market.status == MarketStatus.Active {
                activeMarkets = activeMarkets + 1
            } else if market.status == MarketStatus.PendingResolution {
                pendingResolutionMarkets = pendingResolutionMarkets + 1
            } else if market.status == MarketStatus.Resolved || market.status == MarketStatus.EmergencyResolved {
                resolvedMarkets = resolvedMarkets + 1
            }
        }

        return {
            "totalMarkets": UInt64(totalMarkets),
            "activeMarkets": UInt64(activeMarkets),
            "pendingResolutionMarkets": UInt64(pendingResolutionMarkets),
            "resolvedMarkets": UInt64(resolvedMarkets),
            "totalAdminCount": UInt64(self.admins.keys.length),
            "platformVaultBalance": platformVaultRef.balance,
            "nextMarketId": self.nextMarketId,
            "totalVolumeAcrossAllMarkets": totalVolumeAcrossAllMarkets
        }
    }

    pub fun getUserPredictionsForMarket(marketId: UInt64, userAddress: Address): {String: UFix64}? {
        let market = self.markets[marketId] ?? panic("Market not found")
        if let userPredictions = market.predictions[userAddress] {
            return userPredictions
        }
        return nil
    }

    // TODO: Implement proper fee distribution for creators.
    // Current `getUserWinnings` calculates user's share *after* total fees are deducted.
    // The actual creator's share needs to be made claimable. This involves:
    // 1. Tracking accrued fees per creator (perhaps in a mapping {Address: UFix64} or {UInt64: UFix64} for market-specific creator fees).
    // 2. A function for creators to claim their fees, transferring from platformVault.
    // 3. Emitting events for fee distribution.
    // Example:
    // access(contract) var creatorFeePayouts: {Address: UFix64}
    // In internalResolve():
    //   let creatorShare = self.totalPool * FlowWager.CREATOR_FEE_RATE
    //   self.creatorFeePayouts[self.creator] = (self.creatorFeePayouts[self.creator] ?? 0.0) + creatorShare
    // pub fun claimCreatorFees(recipient: &{FungibleToken.Receiver}) { ... }

    pub fun getMarketsCreatedCountForUser(address: Address): UInt64 {
        return self.userMarketsCreatedCount[address] ?? 0
    }

    pub fun getPredictionsPlacedCountForUser(address: Address): UInt64 {
        return self.userPredictionsPlacedCount[address] ?? 0
    }

    pub fun getTotalUniqueMarketCreatorsCount(): UInt64 {
        return UInt64(self.userMarketsCreatedCount.keys.length)
    }

    pub fun getTotalUniquePredictorsCount(): UInt64 {
        return UInt64(self.userPredictionsPlacedCount.keys.length)
    }
}
