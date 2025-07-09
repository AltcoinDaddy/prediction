import FungibleToken from "FungibleToken"
import FlowToken from "FlowToken"
import FlowWager from "FlowWager"

// Imports are now named and will be resolved by flow.json

/*
Transaction to place a prediction (bet) on a market.

Parameters:
- marketId: UInt64 - The ID of the market to place the prediction on.
- option: String - The chosen option (e.g., "Yes" or "No").
- amount: UFix64 - The amount of FLOW tokens to wager.
*/

transaction(marketId: UInt64, option: String, amount: UFix64) {

    let predictionPaymentVault: @FungibleToken.Vault
    let predictorAddress: Address

    prepare(signer: auth(Storage) &Account) {
        self.predictorAddress = signer.address

        let vaultRef = signer.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic(message: "Could not borrow reference to the signer's FlowToken Vault")

        assert(vaultRef.balance >= amount, message: "Insufficient FLOW balance for this prediction amount.")
        self.predictionPaymentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
        FlowWager.placePrediction(
            marketId: marketId,
            option: option,
            payment: <-self.predictionPaymentVault
        )

        log("Prediction placed successfully on market ID: ".concat(marketId.toString()))
        log("Predictor: ".concat(self.predictorAddress.toString()))
        log("Option: ".concat(option).concat(", Amount: ").concat(amount.toString()))
        // PredictionPlaced event is emitted by the FlowWager contract.
    }
}
