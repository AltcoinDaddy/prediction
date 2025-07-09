import FungibleToken from 0xFUNGIBLE_TOKEN_ADDRESS
// FlowToken import might not be strictly needed if only FT interface is used for receiver
// import FlowToken from 0xFLOW_TOKEN_ADDRESS
import FlowWager from 0xFLOWWAGER_ADDRESS

// TODO: Replace 0xFUNGIBLE_TOKEN_ADDRESS, (0xFLOW_TOKEN_ADDRESS if used),
// and 0xFLOWWAGER_ADDRESS with actual deployment addresses or flow.json aliases.

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

    prepare(signer: AuthAccount) {
        // Get the user's FlowToken Receiver capability.
        // Assumes it's published at the standard public path for FlowToken.
        self.userFlowTokenReceiver = signer.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic("Could not borrow Receiver capability from the signer's account. Make sure it's published at /public/flowTokenReceiver.")
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
            destroy claimedVault // Destroy the empty vault
        }
        // WinningsClaimed event should be emitted by the FlowWager contract if winnings > 0.0
    }
}
