import FlowWager from "FlowWager"

// Imports are now named and will be resolved by flow.json

/*
Transaction for an admin to resolve multiple markets in a batch.
WARNING: Batch operations can be gas-intensive and may hit transaction limits.
If one resolution fails, the entire batch rolls back.

Parameters:
- marketResolutions: [{marketId: UInt64, outcome: String, evidenceURL: String}]
  An array of structs, each detailing a market to resolve.
*/

transaction(marketResolutions: [{marketId: UInt64, outcome: String, evidenceURL: String}]) {

    let adminCapability: &FlowWager.AdminCapability

    prepare(signer: AuthAccount) {
        self.adminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic("Could not borrow AdminCapability from signer. Ensure you are an admin and the capability is at the correct path.")

        // FlowWager.resolveMarket (called in loop) checks "resolve_market" permission.
        // A specific "batch_resolve_markets" permission could be added to adminCap for this tx if desired.
        assert(self.adminCapability.hasPermission(permission: "resolve_market"),
               message: "Admin requires 'resolve_market' permission for batch operations.")

        assert(marketResolutions.length > 0, message: "Market resolutions array cannot be empty.")
        // TODO: Consider enforcing a maximum batch size here (e.g., marketResolutions.length <= 20)
        // to proactively manage gas limits, though actual limit depends on complexity.
    }

    execute {
        var resolvedCount = 0
        log("Starting batch market resolution for ".concat(marketResolutions.length.toString()).concat(" markets..."))

        for resolutionInfo in marketResolutions {
            log("Attempting to resolve market ID: ".concat(resolutionInfo.marketId.toString()))

            // If any call to FlowWager.resolveMarket panics, the entire transaction will revert.
            FlowWager.resolveMarket(
                marketId: resolutionInfo.marketId,
                outcome: resolutionInfo.outcome,
                evidenceURL: resolutionInfo.evidenceURL,
                adminCapRef: self.adminCapability
            )
            resolvedCount = resolvedCount + 1
            log("Market ID: ".concat(resolutionInfo.marketId.toString()).concat(" resolved successfully in batch."))
        }

        log("Batch market resolution completed. Successfully resolved: ".concat(resolvedCount.toString()))
    }
}
