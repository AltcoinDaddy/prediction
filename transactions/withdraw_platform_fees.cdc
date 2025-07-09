import FungibleToken from "FungibleToken"
// FlowToken import is not strictly necessary if only FungibleToken.Receiver is used.
// import FlowToken from "FlowToken" // Keep as named import if uncommented
import FlowWager from "FlowWager"

// Imports are now named and will be resolved by flow.json

/*
Transaction for an admin to withdraw accumulated platform fees.

Parameters:
- amount: UFix64 - The amount of FLOW to withdraw.
- recipientAddress: Address - The account to receive fees; must have a published FungibleToken.Receiver.
*/

transaction(amount: UFix64, recipientAddress: Address) {

    let callingAdminCapability: &FlowWager.AdminCapability
    let feeReceiver: &{FungibleToken.Receiver}

    prepare(signer: auth(Storage) &Account) { // auth(Storage) for signer.storage.borrow
        self.callingAdminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic(message: "Could not borrow AdminCapability from signer. Ensure you are an admin and the capability is at the correct path.")

        // Get the public Receiver capability for the recipient address.
        // Assumes standard /public/flowTokenReceiver path.
        // getAccount().capabilities.borrow requires auth(Capabilities) on the account being called, not the signer.
        // However, the getAccount(recipientAddress) itself does not require signer authorization.
        let recipientAccount = getAccount(recipientAddress)
        self.feeReceiver = recipientAccount.capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic(message: "Could not borrow Receiver capability for the recipient. Ensure it's published at /public/flowTokenReceiver.")
    }

    execute {
        FlowWager.withdrawPlatformFees(
            amount: amount,
            recipient: self.feeReceiver,
            adminCapRef: self.callingAdminCapability
        )

        log("Admin ".concat(self.callingAdminCapability.adminAddress.toString()).concat(" withdrew platform fees."))
        log("Amount: ".concat(amount.toString()).concat(", Recipient: ").concat(recipientAddress.toString()))
        // PlatformFeesWithdrawn event is emitted by the FlowWager contract.
        // TODO: Consider if FlowWager.withdrawPlatformFees should call FlowWagerAdmin.logAdminAction.
    }
}
