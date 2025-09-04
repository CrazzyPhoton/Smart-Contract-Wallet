// SPDX-License-Identifier: MIT

import "./SmartContractWallet.sol";

pragma solidity ^0.8.20;

contract FactoryContractForSmartContractWallet {
    // STATE VARIABLES //

    /// @notice Address variable to store owner.
    address public owner;

    /// @notice Boolean to pause and unpause deployment of smart contract wallets.
    bool public isDeploymentPaused;

    /// @notice Mapping to store smart contract wallets of address.
    mapping(address => address[]) private smartContractWalletsOfAddress;

    // EVENTS //

    /// @notice Event emitted when ownership is transferred.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Event emitted when smart contract wallet is deployed.
    event SmartContractWalletDeployed(
        address indexed smartContractWalletAddress,
        address indexed smartContractWalletOwner
    );

    // ERRORS //

    /// @notice Error thrown when caller is not owner.
    error CallerNotOwner(address caller);

    /// @notice Error thrown when smart contract wallet deployment is paused.
    error DeploymentPaused();

    /// @notice Error thrown when new owner is zero address.
    error InvalidNewOwner(address zeroAddress);

    // MODIFIERS //

    /// @notice Modifier to check whether caller is owner.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert CallerNotOwner(msg.sender);
        }
        _;
    }

    // CONSTRUCTOR //

    /// @notice Constructor called during deployment.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // FUNCTIONS //

    /**
     * @notice Function deploys smart contract wallet.
     *
     * @param _owner    The address of owner.
     * @param _trusteeA The address of trusteeA.
     * @param _trusteeB The address of trusteeB.
     * @param _trusteeC The address of trusteeC.
     */
    function deploySmartContractWallet(
        address _owner,
        address _trusteeA,
        address _trusteeB,
        address _trusteeC
    ) external returns (address, address) {
        if (isDeploymentPaused == true) {
            revert DeploymentPaused();
        }
        SmartContractWallet newSmartContractWallet = new SmartContractWallet(
            _owner,
            _trusteeA,
            _trusteeB,
            _trusteeC
        );
        smartContractWalletsOfAddress[_owner].push(
            address(newSmartContractWallet)
        );
        emit SmartContractWalletDeployed(
            address(newSmartContractWallet),
            _owner
        );
        address smartContractWalletAddress = address(newSmartContractWallet);
        address smartContractWalletOwner = _owner;
        return (smartContractWalletAddress, smartContractWalletOwner);
    }

    /// @notice Function pauses and unpauses deployment of smart contract wallets.
    function pauseDeployment() external onlyOwner {
        isDeploymentPaused = !isDeploymentPaused;
    }

    /**
     * @notice Function transfers ownership of the smart contract to a new address.
     *
     * @param newOwner Address of new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert InvalidNewOwner(address(0));
        }
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice Function returns smart contract wallets of an address.
     *
     * @param _address The address to be queried for.
     */
    function getSmartContractWalletsOfAddress(
        address _address
    ) external view returns (address[] memory) {
        return smartContractWalletsOfAddress[_address];
    }
}