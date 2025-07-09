import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Transaction for an admin to perform an emergency resolution of a market.
This typically bypasses normal resolution windows or conditions if the market is stuck
or requires immediate intervention.

Parameters:
- marketId: UInt64 - The ID of the market to be emergency resolved.
- outcome: String - The winning outcome for the market.
- evidenceURL: String - A URL providing evidence for this emergency resolution.
*/

transaction(marketId: UInt64, outcome: String, evidenceURL: String) {

    let adminCapability: &FlowWager.AdminCapability // Reference to the admin's capability resource

    prepare(signer: AuthAccount) {
        // Borrow the admin capability from the signer's account
        self.adminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic("Could not borrow AdminCapability from signer. Make sure you are an admin and the capability is at the correct path.")

        // The FlowWager.emergencyResolveMarket function itself checks for "emergency_resolve" permission.
        // assert(self.adminCapability.hasPermission(permission: "emergency_resolve"),
        //        message: "Admin does not have 'emergency_resolve' permission.")
    }

    execute {
        // Call the emergencyResolveMarket function on the FlowWager contract
        FlowWager.emergencyResolveMarket(
            marketId: marketId,
            outcome: outcome,
            evidenceURL: evidenceURL,
            adminCapRef: self.adminCapability // Pass the borrowed capability reference
        )

        log("Market ID: ".concat(marketId.toString()).concat(" EMERGENCY RESOLVED by admin: ").concat(self.adminCapability.adminAddress.toString()))
        log("Outcome: ".concat(outcome).concat(", Evidence: ").concat(evidenceURL))

        // Event MarketEmergencyResolved is emitted by the contract (via Market resource's internalEmergencyResolve).
        // AdminActionLogged event might be emitted by FlowWagerAdmin if integrated.
    }
}
