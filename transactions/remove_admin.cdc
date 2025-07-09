import FlowWager from "FlowWager"

// Imports are now named and will be resolved by flow.json

/*
Transaction for an existing admin to remove another admin.
Cannot remove the deployer or oneself via this transaction.

Parameters:
- adminToRemoveAddress: Address - The address of the admin account to be removed.
*/

transaction(adminToRemoveAddress: Address) {

    let callingAdminCapability: &FlowWager.AdminCapability

    prepare(signer: AuthAccount) {
        // Borrow the calling admin's capability from their account.
        // Assumes admins store their capability at /storage/flowWagerAdminCapability.
        self.callingAdminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic("Could not borrow AdminCapability from signer. Ensure you are an admin and the capability is at the correct path.")

        // The FlowWager.removeAdmin function itself performs permission and other necessary checks.
    }

    execute {
        FlowWager.removeAdmin(
            adminAddress: adminToRemoveAddress,
            adminCapRef: self.callingAdminCapability
        )

        log("Admin ".concat(self.callingAdminCapability.adminAddress.toString()).concat(" removed admin: ").concat(adminToRemoveAddress.toString()))
        // AdminRemoved event is emitted by the FlowWager contract.
        // TODO: Consider if FlowWager.removeAdmin should directly call FlowWagerAdmin.logAdminAction.
    }
}
