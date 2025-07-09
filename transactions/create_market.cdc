import FungibleToken from 0xFUNGIBLE_TOKEN_ADDRESS
import FlowToken from 0xFLOW_TOKEN_ADDRESS
import FlowWager from 0xFLOWWAGER_ADDRESS

// TODO: Replace 0xFUNGIBLE_TOKEN_ADDRESS, 0xFLOW_TOKEN_ADDRESS,
// and 0xFLOWWAGER_ADDRESS with actual deployment addresses or flow.json aliases.

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

    prepare(signer: AuthAccount) {
        self.marketCreator = signer.address

        let vaultRef = signer.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow reference to the signer's FlowToken Vault")

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
