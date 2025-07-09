import FlowWager from 0xFLOWWAGER_ADDRESS

// TODO: Replace 0xFLOWWAGER_ADDRESS with actual deployment address or flow.json alias.

/*
Script to check if an address is an admin and retrieve their permissions.

Parameters:
- adminAddress: Address - The address to check.

Returns:
- { "isAdmin": Bool, "permissions": [String]? }
  A dictionary containing:
  - isAdmin: True if the address is an admin.
  - permissions: Array of permission strings if admin, otherwise nil.
*/

access(all) fun main(adminAddress: Address): {String: AnyStruct} {
    let isAdmin = FlowWager.isAdmin(address: adminAddress)
    var permissions: [String]? = nil

    if isAdmin {
        // This script relies on a helper function in FlowWager.cdc:
        // access(all) fun getAdminPermissions(address: Address): [String]?
        // Example implementation in FlowWager.cdc:
        //
        // access(all) fun getAdminPermissions(address: Address): [String]? {
        //    // self.adminCapabilities is access(self)
        //    // Need to access it safely if called from outside.
        //    // If this function is part of FlowWager contract, it can access self.adminCapabilities.
        //    if let adminCap = self.adminCapabilities[address] { // adminCap is &AdminCapability
        //        return adminCap.permissions
        //    }
        //    return nil
        // }
        // The key is that `FlowWager.getAdminPermissions` must be implemented in FlowWager.cdc.
        permissions = FlowWager.getAdminPermissions(address: adminAddress)

        log("Address ".concat(adminAddress.toString()).concat(" IS an admin."))
        if permissions != nil {
            // Cadence 1.0: String array .join is not standard. Manual join or log raw array.
            log("Permissions (raw): ".concat(permissions!.toString()))
        } else {
            // This case should ideally not happen if isAdmin is true and data is consistent.
            log("Permissions could not be retrieved, though address is marked as admin.")
        }
    } else {
        log("Address ".concat(adminAddress.toString()).concat(" is NOT an admin."))
    }

    return {"isAdmin": isAdmin, "permissions": permissions}
}
