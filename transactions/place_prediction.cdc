import FungibleToken from 0xFUNGIBLE_TOKEN_ADDRESS
import FlowToken from 0xFLOW_TOKEN_ADDRESS
import FlowWager from 0xFLOWWAGER_ADDRESS

// TODO: Replace 0xFUNGIBLE_TOKEN_ADDRESS, 0xFLOW_TOKEN_ADDRESS,
// and 0xFLOWWAGER_ADDRESS with actual deployment addresses or flow.json aliases.

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

    prepare(signer: AuthAccount) {
        self.predictorAddress = signer.address

        let vaultRef = signer.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow reference to the signer's FlowToken Vault")

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
