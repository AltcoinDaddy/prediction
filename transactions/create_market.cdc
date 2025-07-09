import FungibleToken from "FungibleToken"
import FlowToken from "FlowToken"
import FlowWager from "FlowWager"

// Imports are now named and will be resolved by flow.json

/*
Transaction to create a new prediction market.

Parameters:
- title: String - The title of the market.
- description: String - A detailed description of the market.
- categoryRawValue: UInt8 - The raw UInt8 value for the market category.
- endTime: UFix64 - The timestamp when the market ends.
- options: [String] - Possible outcomes (e.g., ["Yes", "No"]).
- marketCreationFeeAmount: UFix64 - Fee amount. Should match FlowWager.MARKET_CREATION_FEE
                                   unless the creator is an admin (then 0.0 is acceptable).
*/

transaction(title: String, description: String, categoryRawValue: UInt8, endTime: UFix64, options: [String], marketCreationFeeAmount: UFix64) {

    let paymentVault: @FungibleToken.Vault
    let marketCreator: Address

    prepare(signer: auth(Storage) &Account) {
        self.marketCreator = signer.address

        let vaultRef = signer.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic(message: "Could not borrow reference to the signer's FlowToken Vault")

        // The FlowWager.createMarket function handles the logic for fee waiver if creator is admin.
        // This transaction prepares a vault with the specified fee amount.
        // If marketCreationFeeAmount is 0.0 (e.g. for an admin), an empty vault is effectively withdrawn.
        self.paymentVault <- vaultRef.withdraw(amount: marketCreationFeeAmount)
    }

    execute {
        let marketId = FlowWager.createMarket(
            title: title,
            description: description,
            category: categoryRawValue,
            endTime: endTime,
            options: options,
            payment: <-self.paymentVault
        )

        log("Market created successfully with ID: ".concat(marketId.toString()))
        log("Creator: ".concat(self.marketCreator.toString()))
        // MarketCreated event is emitted by the FlowWager contract.
    }
}
