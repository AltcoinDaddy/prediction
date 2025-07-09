import FungibleToken from 0xFUNGIBLE_TOKEN_ADDRESS
// FlowToken import is not strictly necessary if only FungibleToken.Receiver is used.
// import FlowToken from 0xFLOW_TOKEN_ADDRESS
import FlowWager from 0xFLOWWAGER_ADDRESS

// TODO: Replace 0xFUNGIBLE_TOKEN_ADDRESS, (0xFLOW_TOKEN_ADDRESS if used),
// and 0xFLOWWAGER_ADDRESS with actual deployment addresses or flow.json aliases.

/*
Transaction for an admin to withdraw accumulated platform fees.

Parameters:
- amount: UFix64 - The amount of FLOW to withdraw.
- recipientAddress: Address - The account to receive fees; must have a published FungibleToken.Receiver.
*/

transaction(amount: UFix64, recipientAddress: Address) {

    let callingAdminCapability: &FlowWager.AdminCapability
    let feeReceiver: &{FungibleToken.Receiver}

    prepare(signer: AuthAccount) {
        self.callingAdminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic("Could not borrow AdminCapability from signer. Ensure you are an admin and the capability is at the correct path.")

        // Get the public Receiver capability for the recipient address.
        // Assumes standard /public/flowTokenReceiver path.
        self.feeReceiver = getAccount(recipientAddress)
            .capabilities.borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic("Could not borrow Receiver capability for the recipient. Ensure it's published at /public/flowTokenReceiver.")
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
