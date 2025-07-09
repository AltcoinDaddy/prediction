import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Transaction for an admin to resolve a prediction market.

Parameters:
- marketId: UInt64 - The ID of the market to resolve.
- outcome: String - The winning outcome for the market.
- evidenceURL: String - A URL providing evidence for the resolution.
*/

transaction(marketId: UInt64, outcome: String, evidenceURL: String) {

    // let flowWagerContract: &FlowWager{FlowWager.ContractPublic} // Or a more specific admin interface
    let adminCapability: &FlowWager.AdminCapability // Reference to the admin's capability resource

    prepare(signer: AuthAccount) {
        // Borrow a reference to the FlowWager contract instance
        // self.flowWagerContract = getAccount(0xFLOWWAGER_CONTRACT_ADDRESS)
        //     .getCapability<&FlowWager{FlowWager.ContractPublic}>(FlowWager.ContractPublicPath)
        //     .borrow() ?? panic("Could not borrow FlowWager contract reference")
        // As before, direct calls to FlowWager.resolveMarket(...) are likely if it's public.

        // Borrow the admin capability from the signer's account
        // This path should be where admins store their capability resource.
        self.adminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic("Could not borrow AdminCapability from signer. Make sure you are an admin and the capability is at the correct path.")

        // Verify the admin has the specific permission to resolve markets.
        // The FlowWager.resolveMarket function itself contains this pre-condition check:
        // `adminCapRef.hasPermission(permission: "resolve_market")`
        // So, explicit check here is optional but can provide earlier feedback.
        // assert(self.adminCapability.hasPermission(permission: "resolve_market"),
        //        message: "Admin does not have 'resolve_market' permission.")
    }

    execute {
        // Call the resolveMarket function on the FlowWager contract
        FlowWager.resolveMarket(
            marketId: marketId,
            outcome: outcome,
            evidenceURL: evidenceURL,
            adminCapRef: self.adminCapability // Pass the borrowed capability reference
        )

        log("Market ID: ".concat(marketId.toString()).concat(" resolved by admin: ").concat(self.adminCapability.adminAddress.toString()))
        log("Outcome: ".concat(outcome).concat(", Evidence: ").concat(evidenceURL))

        // Event MarketResolved is emitted by the contract.
        // AdminActionLogged event might be emitted by FlowWagerAdmin if integrated.
    }
}
