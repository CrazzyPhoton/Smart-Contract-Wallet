# SmartContractWallet and FactoryContractForSmartContractWallet

This project contains two Solidity smart contracts:

1. **SmartContractWallet**: A secure wallet contract supporting ETH, ERC20, ERC721, and ERC1155 token management.
2. **FactoryContractForSmartContractWallet**: A factory contract for deploying and managing multiple instances of `SmartContractWallet`.

---

## Table of Contents

1. [Features](#features)
2. [Deployment](#deployment)
3. [Contract Details](#contract-details)
4. [Security Considerations](#security-considerations)
5. [License](#license)

---

## Features

### SmartContractWallet

- **Supports Multiple Token Standards**:
  - ERC20 tokens
  - ERC721 tokens (NFTs)
  - ERC1155 tokens (multi-token standard)
- **ETH Management**:
  - Deposit and withdraw ETH securely.
- **Token Management**:
  - Deposit and withdraw ERC20, ERC721, and ERC1155 tokens.
- **Role-Based Access Control**:
  - Owner and up to three trustees have defined roles.
- **Custom Errors and Events**:
  - Efficient gas usage through custom errors.
  - Transparent transaction logs through events.

### FactoryContractForSmartContractWallet

- **Deploy SmartContractWallet Instances**:
  - Factory deploys and manages wallet instances.
- **Owner Management**:
  - Factory owner can pause or resume wallet deployments.
- **Mapping**:
  - Tracks deployed wallets per owner.
- **Custom Errors and Events**:
  - Optimized gas usage and detailed event logs.

---

## Deployment

1. **Deploy Factory Contract**: Deploy the `FactoryContractForSmartContractWallet` on your desired EVM-compatible blockchain.
2. **Deploy Wallet Instances via Factory**: Use the factory's `deploySmartContractWallet` function to create wallet instances.

---

## Contract Details

### SmartContractWallet

| Function               | Description                                            |
|------------------------|--------------------------------------------------------|
| `transferOwnership`    | Transfers ownership of the wallet.                    |
| `setTrusteeA`          | Sets Trustee A's address.                             |
| `setTrusteeB`          | Sets Trustee B's address.                             |
| `setTrusteeC`          | Sets Trustee C's address.                             |
| `depositEth`           | Deposits ETH into the wallet.                         |
| `sendEth`              | Sends ETH from the wallet to a recipient.             |
| `sendEthBalance`       | Sends all ETH from the wallet to a recipient.         |
| `depositErc20`         | Deposits ERC20 tokens into the wallet.                |
| `sendErc20`            | Sends ERC20 tokens from the wallet to a recipient.    |
| `sendErc20Balance`     | Sends all ERC20 tokens of a type to a recipient.      |
| `depositErc721`        | Deposits an ERC721 token into the wallet.             |
| `sendErc721`           | Sends an ERC721 token to a recipient.                 |
| `depositErc1155`       | Deposits ERC1155 tokens into the wallet.              |
| `sendErc1155`          | Sends ERC1155 tokens to a recipient.                  |

### FactoryContractForSmartContractWallet

| Function                         | Description                                      |
|----------------------------------|--------------------------------------------------|
| `deploySmartContractWallet`      | Deploys a new `SmartContractWallet`.            |
| `pauseDeployment`                | Toggles deployment pause state.                 |
| `transferOwnership`              | Transfers ownership of the factory.             |
| `getSmartContractWalletsOfAddress` | Retrieves all wallets deployed by an address.   |

---

## Security Considerations

- **Role-based access control**: Critical operations are restricted to the owner or designated trustees.
- **Custom errors and modifiers**: Used to enhance gas efficiency and maintain code clarity.
- **OpenZeppelin libraries**: Ensure secure and standard-compliant operations for ERC20, ERC721, and ERC1155 token standards.

---

## License

This project is licensed under the MIT License.

---


