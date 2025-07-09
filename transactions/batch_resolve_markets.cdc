import FlowWager from 0xFLOWWAGER_CONTRACT_ADDRESS
// TODO: Replace 0xFLOWWAGER_CONTRACT_ADDRESS with actual deployment address.

/*
Transaction for an admin to resolve multiple markets in a batch.
WARNING: Batch operations can be gas-intensive. The number of markets resolvable
in a single transaction will be limited by Flow's transaction gas limits.
Consider processing in smaller batches if many markets need resolution.

Parameters:
- marketResolutions: [{marketId: UInt64, outcome: String, evidenceURL: String}]
  An array of structs, each containing the details for resolving one market.
*/

transaction(marketResolutions: [{marketId: UInt64, outcome: String, evidenceURL: String}]) {

    let adminCapability: &FlowWager.AdminCapability // Reference to the admin's capability resource

    prepare(signer: AuthAccount) {
        // Borrow the admin capability from the signer's account
        self.adminCapability = signer.storage.borrow<&FlowWager.AdminCapability>(from: /storage/flowWagerAdminCapability)
            ?? panic("Could not borrow AdminCapability from signer. Make sure you are an admin and the capability is at the correct path.")

        // The FlowWager.resolveMarket function (called internally by this batch tx)
        // checks for "resolve_market" permission for each market.
        // A single check here for the batch operation permission might also be useful if defined.
        // For now, relying on the per-market check within the loop.
        assert(self.adminCapability.hasPermission(permission: "resolve_market"),
               message: "Admin does not have 'resolve_market' permission, required for batch resolution.")

        assert(marketResolutions.length > 0, message: "Market resolutions array cannot be empty.")
        // Consider adding a maximum batch size check here to prevent overly large transactions.
        // e.g., assert(marketResolutions.length <= 20, message: "Batch size too large. Max 20 markets per batch.")
    }

    execute {
        var resolvedCount = 0
        var errorCount = 0
        var errors: [String] = []

        log("Starting batch market resolution for ".concat(marketResolutions.length.toString()).concat(" markets..."))

        for resolutionInfo in marketResolutions {
            // It's generally better to catch errors per item in a batch if possible,
            // but Cadence's error handling (panic) will halt the whole transaction.
            // To make it robust (skip failing items), each call to resolveMarket would need to be
            // wrapped in its own transaction or the contract function itself designed to not panic
            // but return a status. This is complex.
            // For now, if one resolution fails, the whole batch transaction fails.

            // An alternative for more robust batching (but more complex):
            // The contract `FlowWager` could have a function:
            // `tryResolveMarket(marketId: ..., outcome: ..., evidenceURL: ..., adminCapRef: ...): Bool`
            // which returns true on success, false on failure (and logs error internally).
            // Then this transaction could count successes/failures.
            // For now, sticking to the existing `resolveMarket` which panics on failure.

            log("Attempting to resolve market ID: ".concat(resolutionInfo.marketId.toString()).concat(" with outcome: ").concat(resolutionInfo.outcome))

            FlowWager.resolveMarket(
                marketId: resolutionInfo.marketId,
                outcome: resolutionInfo.outcome,
                evidenceURL: resolutionInfo.evidenceURL,
                adminCapRef: self.adminCapability
            )
            resolvedCount = resolvedCount + 1
            log("Market ID: ".concat(resolutionInfo.marketId.toString()).concat(" resolved successfully."))
        }

        log("Batch market resolution completed.")
        log("Total markets processed: ".concat(marketResolutions.length.toString()))
        log("Successfully resolved: ".concat(resolvedCount.toString()))
        // errorCount will be 0 if this point is reached, as any error would have panicked.
    }
}

// Note on Batching Robustness:
// As implemented, if any single market resolution in the batch fails (e.g., market not found,
// invalid outcome, permission issue discovered mid-way), the entire transaction will panic and
// roll back. None of the markets in that batch will be resolved.
// True atomic batching where some items can succeed while others fail (and are reported)
// requires more sophisticated error handling within the contract functions themselves
// (e.g., returning result structs or error codes instead of panicking) or processing each item
// in a separate transaction (which is not a "batch" transaction anymore).
// The current implementation is a "best effort" atomic batch: all succeed or all fail.
// This is often acceptable, and the caller can then retry with a corrected batch or individual items.
