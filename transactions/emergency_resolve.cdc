import FlowWager from "FlowWager"

// Imports are now named and will be resolved by flow.json

/*
Transaction for an admin to perform an emergency resolution of a market.

Parameters:
- marketId: UInt64 - The ID of the market to be emergency resolved.
- outcome: String - The winning outcome for the market.
- evidenceURL: String - A URL providing evidence for this emergency resolution.
*/

transaction(marketId: UInt64, outcome: String, evidenceURL: String) {

    let adminCapability: &FlowWager.AdminCapability

    prepare(signer: auth(Storage) &Account) {
        // Borrow the admin capability from the signer's account.
        // Assumes admins store their capability at /storage/flowWagerAdminCapability.
        self.adminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic(message: "Could not borrow AdminCapability from signer. Ensure you are an admin and the capability is at the correct path.")

        // The FlowWager.emergencyResolveMarket function itself performs permission checks.
    }

    execute {
        FlowWager.emergencyResolveMarket(
            marketId: marketId,
            outcome: outcome,
            evidenceURL: evidenceURL,
            adminCapRef: self.adminCapability
        )

        log("Market ID: ".concat(marketId.toString()).concat(" EMERGENCY RESOLVED by admin: ").concat(self.adminCapability.adminAddress.toString()))
        log("Outcome: ".concat(outcome).concat(", Evidence: ").concat(evidenceURL))
        // MarketEmergencyResolved event is emitted by the FlowWager contract.
        // TODO: Consider if FlowWager.emergencyResolveMarket should call FlowWagerAdmin.logAdminAction.
    }
}
