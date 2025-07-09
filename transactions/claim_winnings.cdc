import FungibleToken from 0xSTANDARD_FUNGIBLE_TOKEN_ADDRESS
import FlowToken from 0xSTANDARD_FLOW_TOKEN_ADDRESS
import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xSTANDARD_FUNGIBLE_TOKEN_ADDRESS, 0xSTANDARD_FLOW_TOKEN_ADDRESS,
// and 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment addresses.

/*
Transaction for a user to claim their winnings from a resolved market.
This transaction assumes FlowWager.claimWinnings now returns @FungibleToken.Vault.
If FlowWager.claimWinnings does NOT return a vault, this transaction needs significant change,
or FlowWager.claimWinnings needs a Receiver capability argument.

Parameters:
- marketId: UInt64 - The ID of the market from which to claim winnings.
*/

transaction(marketId: UInt64) {

    // let flowWagerContract: &FlowWager{FlowWager.ContractPublic}
    let userFlowTokenReceiver: &{FungibleToken.Receiver}
    let winningsVault: @FungibleToken.Vault? // Optional, because winnings might be 0.0

    prepare(signer: AuthAccount) {
        // Borrow a reference to the FlowWager contract
        // self.flowWagerContract = getAccount(0xFLOWWAGER_CONTRACT_ADDRESS)
        //     .getCapability<&FlowWager{FlowWager.ContractPublic}>(FlowWager.ContractPublicPath)
        //     .borrow() ?? panic("Could not borrow FlowWager contract reference")

        // Get the user's FlowToken Receiver capability
        self.userFlowTokenReceiver = signer.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic("Could not borrow Receiver capability from the signer's account. Make sure it's published at /public/flowTokenReceiver.")

        // Initialize winningsVault as nil. It will be assigned in execute.
        self.winningsVault = nil
    }

    execute {
        // Call the claimWinnings function on the FlowWager contract.
        // CRITICAL ASSUMPTION: FlowWager.claimWinnings is modified to return the vault:
        // pub fun claimWinnings(marketId: UInt64, userAddress: Address): @FungibleToken.Vault { ... }
        // If not, this will fail. The original prompt for FlowWager.cdc did NOT have a return type.
        // For this transaction to work, FlowWager.claimWinnings MUST be:
        // pub fun claimWinnings(marketId: UInt64, userAddress: Address): @FungibleToken.Vault
        // OR FlowWager.claimWinnings(marketId: UInt64, userAddress: Address, receiver: &{FungibleToken.Receiver})

        // Assuming the version that returns a vault:
        let claimedVault <- FlowWager.claimWinnings(marketId: marketId, userAddress: signer.address)

        if claimedVault.balance > 0.0 {
            log("Winnings successfully claimed from market ID: ".concat(marketId.toString()))
            log("Amount: ".concat(claimedVault.balance.toString()))

            // Deposit the winnings into the user's account
            self.userFlowTokenReceiver.deposit(from: <-claimedVault)
            log("Winnings deposited to signer's account.")
        } else {
            log("No winnings to claim or already claimed for market ID: ".concat(marketId.toString()))
            // Destroy the empty vault if balance is 0
            destroy claimedVault
        }
        // Event WinningsClaimed is emitted by the contract.
    }
}

// ===== IMPORTANT NOTE FOR REVIEW =====
// This transaction's `execute` block fundamentally depends on a change to the
// `FlowWager.cdc` contract's `claimWinnings` function signature.
// The original signature was `pub fun claimWinnings(marketId: UInt64, userAddress: Address)` (no return).
// For this transaction to be viable and secure for fund transfer, `claimWinnings` needs to be:
// `pub fun claimWinnings(marketId: UInt64, userAddress: Address): @FungibleToken.Vault`
//
// If `FlowWager.claimWinnings` cannot be changed:
// Alternative 1: `FlowWager.claimWinnings` takes `receiver: &{FungibleToken.Receiver}`. Tx would pass `self.userFlowTokenReceiver`.
// Alternative 2: `FlowWager.claimWinnings` only updates internal state. A separate transaction would be:
//   transaction {
//     prepare(signer: AuthAccount) {
//       let amount = FlowWager.getPendingWithdrawalForUser(marketId, signer.address) // New func needed
//       let vaultRef = FlowWager.getPlatformVaultRef() // Needs careful capability handling
//       let myVault <- vaultRef.withdraw(amount)
//       signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!.deposit(from: <-myVault)
//       FlowWager.markWithdrawalComplete(marketId, signer.address) // New func needed
//     }
//   }
// This alternative is much more complex and less atomic.
// The version implemented above assumes the signature change for `claimWinnings` in `FlowWager.cdc`.
// =====================================
