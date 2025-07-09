import FlowWager from 0xFLOWWAGER_ADDRESS

// TODO: Replace 0xFLOWWAGER_ADDRESS with actual deployment address or flow.json alias.

/*
Transaction for an existing admin to add a new admin.

Parameters:
- newAdminAddress: Address - The address of the account to be made an admin.
- permissions: [String] - A list of permission strings for the new admin. Use ["all"] for full permissions.
*/

transaction(newAdminAddress: Address, permissions: [String]) {

    let callingAdminCapability: &FlowWager.AdminCapability

    prepare(signer: AuthAccount) {
        // Borrow the calling admin's capability from their account.
        // Assumes admins store their capability at /storage/flowWagerAdminCapability.
        self.callingAdminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic("Could not borrow AdminCapability from signer. Ensure you are an admin and the capability is at the correct path.")

        // The FlowWager.addAdmin function itself performs permission checks.
    }

    execute {
        FlowWager.addAdmin(
            adminAddress: newAdminAddress,
            permissions: permissions,
            adminCapRef: self.callingAdminCapability
        )

        log("Admin ".concat(self.callingAdminCapability.adminAddress.toString()).concat(" added new admin: ").concat(newAdminAddress.toString()))
        log("New admin permissions: ".concat(permissions.join(", "))) // .join might not be available on [String], depends on Cadence version string utils
                                                                    // If not, log permissions array directly or iterate.
                                                                    // For Cadence 1.0, String array .join is not standard. Manual join or log raw array.
        log("Raw permissions array: ".concat(permissions.toString()))


        // AdminAdded event is emitted by the FlowWager contract.
        // TODO: Consider if FlowWager.addAdmin should directly call FlowWagerAdmin.logAdminAction.
    }
}
