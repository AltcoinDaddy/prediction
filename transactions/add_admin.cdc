import FlowWager from "FlowWager"

// Imports are now named and will be resolved by flow.json

/*
Transaction for an existing admin to add a new admin.

Parameters:
- newAdminAddress: Address - The address of the account to be made an admin.
- permissions: [String] - A list of permission strings for the new admin. Use ["all"] for full permissions.
*/

transaction(newAdminAddress: Address, permissions: [String]) {

    let callingAdminCapability: &FlowWager.AdminCapability

    prepare(signer: auth(Storage) &Account) {
        // Borrow the calling admin's capability from their account.
        // Assumes admins store their capability at /storage/flowWagerAdminCapability.
        // Need auth(Storage) to access signer.storage.borrow
        self.callingAdminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic(message: "Could not borrow AdminCapability from signer. Ensure you are an admin and the capability is at the correct path.")

        // The FlowWager.addAdmin function itself performs permission checks.
    }

    execute {
        FlowWager.addAdmin(
            adminAddress: newAdminAddress,
            permissions: permissions,
            adminCapRef: self.callingAdminCapability
        )

        log("Admin ".concat(self.callingAdminCapability.adminAddress.toString()).concat(" added new admin: ").concat(newAdminAddress.toString()))

        var permissionsString = ""
        if permissions.length > 0 {
            permissionsString = permissions[0]
            var i = 1
            while i < permissions.length {
                permissionsString = permissionsString.concat(", ").concat(permissions[i])
                i = i + 1
            }
        }
        log("New admin permissions: [".concat(permissionsString).concat("]"))
        // For raw logging, log(permissions) might work, or iterate and log each element.
        // The .toString() for direct concatenation with another string is the issue.
        // Logging the constructed string is clearer.
        log("Raw permissions array (logged as constructed string): [".concat(permissionsString).concat("]"))

        // AdminAdded event is emitted by the FlowWager contract.
        // TODO: Consider if FlowWager.addAdmin should directly call FlowWagerAdmin.logAdminAction.
    }
}
