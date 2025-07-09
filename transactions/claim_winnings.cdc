import FungibleToken from "FungibleToken"
// FlowToken import might not be strictly needed if only FT interface is used for receiver
// import FlowToken from "FlowToken" // Keep as named import if uncommented
import FlowWager from "FlowWager"

// Imports are now named and will be resolved by flow.json

/*
Transaction for a user to claim their winnings from a resolved market.

Parameters:
- marketId: UInt64 - The ID of the market from which to claim winnings.
*/

transaction(marketId: UInt64) {

    let userFlowTokenReceiver: &{FungibleToken.Receiver}
    // This transaction relies on FlowWager.claimWinnings being refactored to return the vault.
    // If FlowWager.claimWinnings is not changed from its original spec (no return type),
    // this transaction will not function for fund transfer and a different approach is needed.
    // See comments in FlowWager.cdc around claimWinnings function.

    prepare(signer: auth(Capabilities) &Account) {
        // Get the user's FlowToken Receiver capability.
        // Assumes it's published at the standard public path for FlowToken.
        // Need auth(Capabilities) to access signer.capabilities.borrow
        self.userFlowTokenReceiver = signer.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic(message: "Could not borrow Receiver capability from the signer's account. Make sure it's published at /public/flowTokenReceiver.")
    }

    execute {
        // CRITICAL ASSUMPTION: FlowWager.claimWinnings has been modified to return @FungibleToken.Vault
        // e.g., access(all) fun claimWinnings(marketId: UInt64, userAddress: Address): @FungibleToken.Vault
        let claimedVault <- FlowWager.claimWinnings(marketId: marketId, userAddress: signer.address)

        if claimedVault.balance > 0.0 {
            log("Winnings successfully claimed from market ID: ".concat(marketId.toString()))
            log("Amount: ".concat(claimedVault.balance.toString()))

            self.userFlowTokenReceiver.deposit(from: <-claimedVault)
            log("Winnings deposited to signer's account.")
        } else {
            log("No winnings to claim or already claimed for market ID: ".concat(marketId.toString()))
            // In Cadence 1.0, 'destroy' is removed. Empty vaults are implicitly destroyed.
            // If claimedVault is an optional that's nil, this branch isn't hit.
            // If claimedVault is non-nil and empty, it's handled when it goes out of scope.
        }
        // WinningsClaimed event should be emitted by the FlowWager contract if winnings > 0.0
    }
}
