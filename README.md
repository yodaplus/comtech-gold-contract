## Comtech Maker Checker Documentation

### Comtech Maker-Checker App Components

- Comtech Maker-Checker Smart Contract
  https://github.com/yodaplus/comtech-gold-contract
- Comtech Maker-Checker DApp
  https://github.com/yodaplus/comtech-gold

## Comtech Maker-Checker Smart Contract

Maker-Checker Smart Contract is responsible for CGO Token Action and setting up `Initiator` , `Executor` and `Mint Escrow Wallet`

- Initiator role
  It initiates the mint/burn Action

- Executor role
  It act as a verifier to mint/burn Action.

- Admin role
  Smart Contract's admin is responsible to setup Initiator, Executor and Mint Wallet Address.
- Smart Contract holds the Bar Details.

### Smart Contract Implemetation

**![](https://lh4.googleusercontent.com/uSropg-wyXTosr-Gb6JdBDSjLW1KXtWQ24wacPf85J2-PBQ1cjpGNDyADDnEIrgHC-1oV-1v_uf1rv6X3bjBbR_eg8-ZfdmoQxs6w6CB9AUnwKBFLusVniHhjywNERBfK6IqIM_fXAzPn50FT1L5GnosuA=s2048)**

## Comtech Maker-Checker DApp

Maker-Checker consist of frontend, backend interact with smart contract.

## backend implementation (Python - Django)

- Database and logic implemetation for bar assignment to the holder wallet.
- Bar details are fully based on event driven approach with blockchain.
- Celery (with web3 layer) - Cron Job for Bar details record and holding assignment - reassignment.

## frontend implemetation

- UI interaction for Admin, Initiator and Executor.
- web3 layer for contract interaction
  (Intiate Mint, MInt, Intiate Burn, Burn, etc.)
- Initiator, Executor can be a normal XDCPay/Metamask Wallet or Multisig safe.

> Note: We are using the Yodaplus Multisig safe (Optional)

- Multisig safe introduce the execution policy:
  1. Multiple owner of the safe.
  2. Configure the `m` of `n` policy for the owners of the safe to execute any transaction.

## Comtech Maker-Checker Workflow diagram

https://lucid.app/lucidchart/357a7291-b7f3-4f4e-966c-a6834cd538af/edit?viewport_loc=-523%2C-116%2C2560%2C1129%2C0_0&invitationId=inv_765ab176-84b7-4d87-ae09-367b73c961c5
**![](https://lh5.googleusercontent.com/wwof0xd1eyDK4K7Cv5reH6zh5wKIyDEYBkO-ZDvCB-AQc_iUb7bAi-0YBwIfdEXQLLlLUKFMIscVKA61GgSJfXJNezLftn-x-TipxpAV2doo4aEriAqrnaIPaK-fik6GBPDbN6XfSlV6mZ4cgBs2-vNTXg=s2048)**
