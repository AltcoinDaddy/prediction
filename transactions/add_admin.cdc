import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Transaction for an existing admin to add a new admin.

Parameters:
- newAdminAddress: Address - The address of the account to be made an admin.
- permissions: [String] - A list of permission strings for the new admin (e.g., ["resolve_market", "pause_market"]).
                         Use ["all"] for full permissions.
*/

transaction(newAdminAddress: Address, permissions: [String]) {

    // let flowWagerContract: &FlowWager{FlowWager.ContractPublic} // Or a more specific admin interface
    let callingAdminCapability: &FlowWager.AdminCapability // Reference to the calling admin's capability

    prepare(signer: AuthAccount) {
        // Borrow a reference to the FlowWager contract instance (if needed for direct calls, though likely not for this)
        // self.flowWagerContract = getAccount(0xFLOWWAGER_CONTRACT_ADDRESS)
        //     .getCapability<&FlowWager{FlowWager.ContractPublic}>(FlowWager.ContractPublicPath)
        //     .borrow() ?? panic("Could not borrow FlowWager contract reference")

        // Borrow the calling admin's capability from their account
        self.callingAdminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic("Could not borrow AdminCapability from signer. Ensure you are an admin and the capability is at the correct path.")

        // The FlowWager.addAdmin function itself checks for "manage_admins" permission.
        // assert(self.callingAdminCapability.hasPermission(permission: "manage_admins"),
        //        message: "Calling admin does not have 'manage_admins' permission.")
    }

    execute {
        // Call the addAdmin function on the FlowWager contract
        FlowWager.addAdmin(
            adminAddress: newAdminAddress,
            permissions: permissions,
            adminCapRef: self.callingAdminCapability // Pass the calling admin's capability reference
        )

        log("Admin ".concat(self.callingAdminCapability.adminAddress.toString()).concat(" added new admin: ").concat(newAdminAddress.toString()))
        log("New admin permissions: ".concat(permissions.join(", ")))

        // Event AdminAdded is emitted by the contract.
        // AdminActionLogged event might be emitted by FlowWagerAdmin if integrated.
    }
}
