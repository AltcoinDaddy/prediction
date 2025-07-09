import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Script to check if an address is an admin and retrieve their permissions if they are.

Parameters:
- adminAddress: Address - The address to check.

Returns:
- {isAdmin: Bool, permissions: [String]?}
  A struct containing:
  - isAdmin: Bool - True if the address is an admin, false otherwise.
  - permissions: [String]? - An array of permission strings if the address is an admin, otherwise nil.
                           (This requires FlowWager to expose a way to get permissions for an admin)
*/

pub fun main(adminAddress: Address): {String: AnyStruct} {
    let isAdmin = FlowWager.isAdmin(address: adminAddress)
    var permissions: [String]? = nil

    if isAdmin {
        // To get permissions, FlowWager.cdc needs a public function like:
        // pub fun getAdminPermissions(adminAddress: Address): [String]? {
        //     if let capability = self.adminCapabilities[adminAddress] {
        //         return capability.permissions
        //     }
        //     return nil
        // }
        // Assuming such a function `FlowWager.getAdminPermissions(address: Address): [String]?` exists.
        permissions = FlowWager.getAdminPermissions(address: adminAddress)
        log("Address ".concat(adminAddress.toString()).concat(" IS an admin."))
        if permissions != nil {
            log("Permissions: ".concat(permissions!.join(", ")))
        } else {
            log("Permissions could not be retrieved (this should not happen if isAdmin is true and capabilities are stored correctly).")
        }
    } else {
        log("Address ".concat(adminAddress.toString()).concat(" is NOT an admin."))
    }

    return {"isAdmin": isAdmin, "permissions": permissions}
}

// Note: This script relies on a new public function `getAdminPermissions(address: Address): [String]?`
// being added to `FlowWager.cdc` to retrieve the permissions list for an admin.
// The `FlowWager.isAdmin` function only returns a Bool.
// The `AdminCapability` resource in `FlowWager.cdc` holds the permissions.
// `FlowWager.adminCapabilities: @{Address: AdminCapability}` is `access(self)`.
// A public getter is needed:
// pub fun getAdminPermissions(address: Address): [String]? {
//    if let adminCap = self.adminCapabilities[address] {
//        return adminCap.permissions
//    }
//    return nil
// }
