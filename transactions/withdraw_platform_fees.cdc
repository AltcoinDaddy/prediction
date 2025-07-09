import FungibleToken from 0xSTANDARD_FUNGIBLE_TOKEN_ADDRESS
import FlowToken from 0xSTANDARD_FLOW_TOKEN_ADDRESS // Not strictly needed here if only using FT interface
import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xSTANDARD_FUNGIBLE_TOKEN_ADDRESS, 0xSTANDARD_FLOW_TOKEN_ADDRESS,
// and 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment addresses.

/*
Transaction for an admin to withdraw accumulated platform fees.

Parameters:
- amount: UFix64 - The amount of FLOW to withdraw from the platform fees.
- recipientAddress: Address - The address of the account to receive the withdrawn fees.
                               This account must have a published FungibleToken.Receiver capability.
*/

transaction(amount: UFix64, recipientAddress: Address) {

    let callingAdminCapability: &FlowWager.AdminCapability // Reference to the calling admin's capability
    let feeReceiverCap: Capability<&{FungibleToken.Receiver}> // Capability for the recipient's vault

    prepare(signer: AuthAccount) {
        // Borrow the calling admin's capability from their account
        self.callingAdminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic("Could not borrow AdminCapability from signer. Ensure you are an admin and the capability is at the correct path.")

        // The FlowWager.withdrawPlatformFees function checks for "withdraw_fees" permission.
        // assert(self.callingAdminCapability.hasPermission(permission: "withdraw_fees"),
        //        message: "Calling admin does not have 'withdraw_fees' permission.")

        // Get the public Receiver capability for the recipient address
        self.feeReceiverCap = getAccount(recipientAddress)
            .capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver) // Standard public path for FlowToken receiver
            ?? panic("Could not get Receiver capability for the recipient address. Ensure it is published at /public/flowTokenReceiver.")

        assert(self.feeReceiverCap.borrow() != nil, message: "Cannot borrow Receiver from capability.")
    }

    execute {
        // Borrow the receiver from the capability to pass to the function
        let actualReceiver = self.feeReceiverCap.borrow()!

        // Call the withdrawPlatformFees function on the FlowWager contract
        FlowWager.withdrawPlatformFees(
            amount: amount,
            recipient: actualReceiver, // Pass the borrowed receiver reference
            adminCapRef: self.callingAdminCapability
        )

        log("Admin ".concat(self.callingAdminCapability.adminAddress.toString()).concat(" withdrew platform fees."))
        log("Amount: ".concat(amount.toString()).concat(", Recipient: ").concat(recipientAddress.toString()))

        // Event PlatformFeesWithdrawn is emitted by the contract.
    }
}
