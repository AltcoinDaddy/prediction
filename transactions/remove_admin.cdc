import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Transaction for an existing admin to remove another admin.
Cannot remove the deployer or oneself via this transaction.

Parameters:
- adminToRemoveAddress: Address - The address of the admin account to be removed.
*/

transaction(adminToRemoveAddress: Address) {

    let callingAdminCapability: &FlowWager.AdminCapability // Reference to the calling admin's capability

    prepare(signer: AuthAccount) {
        // Borrow the calling admin's capability from their account
        self.callingAdminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic("Could not borrow AdminCapability from signer. Ensure you are an admin and the capability is at the correct path.")

        // The FlowWager.removeAdmin function itself checks for "manage_admins" permission
        // and other conditions like not removing deployer or self.
        // assert(self.callingAdminCapability.hasPermission(permission: "manage_admins"),
        //        message: "Calling admin does not have 'manage_admins' permission.")
    }

    execute {
        // Call the removeAdmin function on the FlowWager contract
        FlowWager.removeAdmin(
            adminAddress: adminToRemoveAddress,
            adminCapRef: self.callingAdminCapability // Pass the calling admin's capability reference
        )

        log("Admin ".concat(self.callingAdminCapability.adminAddress.toString()).concat(" removed admin: ").concat(adminToRemoveAddress.toString()))

        // Event AdminRemoved is emitted by the contract.
        // AdminActionLogged event might be emitted by FlowWagerAdmin if integrated.
    }
}
