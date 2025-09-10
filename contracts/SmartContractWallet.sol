// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity ^0.8.20;

/// @title SmartContractWallet
/// @author Rahul Mayekar (https://github.com/CrazzyPhoton)
/// @notice A smart contract wallet that can hold and transfer ETH, ERC20, ERC721 and ERC1155 tokens.
/// @dev Inherits ERC721Holder and ERC1155Holder to handle safe transfers of ERC721 and ERC1155 tokens.

contract SmartContractWallet is ERC721Holder, ERC1155Holder {
    // STATE VARIABLES //

    /// @notice Address variable to store owner.
    address public owner;

    /// @notice Address variable to store trusteeA.
    address public trusteeA;

    /// @notice Address variable to store trusteeB.
    address public trusteeB;

    /// @notice Address variable to store trusteeC.
    address public trusteeC;

    // EVENTS //

    /// @notice Event emitted when ETH is transferred.
    event EthTransfer(
        address indexed from,
        address indexed to,
        uint256 indexed amount
    );

    /// @notice Event emitted when trusteeA is set.
    event NewTrusteeA(address indexed _trusteeA);

    /// @notice Event emitted when trusteeB is set.
    event NewTrusteeB(address indexed _trusteeB);

    /// @notice Event emitted when trusteeC is set.
    event NewTrusteeC(address indexed _trusteeC);

    /// @notice Event emitted when ownership is transferred.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // ERRORS //

    /// @notice Error thrown when caller is not owner.
    error CallerNotOwner(address caller);

    /// @notice Error thrown when caller is not owner nor trustee.
    error CallerNotOwnerNorTrustee(address caller);

    /// @notice Error thrown when ETH balance in contract is lesser than required.
    error EthInsufficientBalance(uint256 ethBalance);

    /// @notice Error thrown when inputted ETH amount is 0.
    error InvalidEthAmount(uint256 ethAmount);

    /// @notice Error thrown when new owner is zero address.
    error InvalidNewOwner(address zeroAddress);

    /// @notice Error thrown when recipient is zero address.
    error InvalidRecipientAddress(address recipient);

    /// @notice Error thrown when ETH withdrawal to recipient is unsuccessful.
    error UnableToSendValue(address recipient);

    // MODIFIERS //

    /// @notice Modifier to check whether caller is owner.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert CallerNotOwner(msg.sender);
        }
        _;
    }

    /// @notice Modifier to check whether caller is owner or trustee.
    modifier onlyOwnerOrTrustee() {
        if (
            msg.sender != owner &&
            msg.sender != trusteeA &&
            msg.sender != trusteeB &&
            msg.sender != trusteeC
        ) {
            revert CallerNotOwnerNorTrustee(msg.sender);
        }
        _;
    }

    // CONSTRUCTOR //

    /// @notice Constructor called during deployment.
    constructor(
        address _owner,
        address _trusteeA,
        address _trusteeB,
        address _trusteeC
    ) {
        if (_owner == address(0)) {
            revert InvalidNewOwner(address(0));
        }
        owner = _owner;
        trusteeA = _trusteeA;
        trusteeB = _trusteeB;
        trusteeC = _trusteeC;
        emit OwnershipTransferred(address(0), _owner);
        emit NewTrusteeA(_trusteeA);
        emit NewTrusteeB(_trusteeB);
        emit NewTrusteeC(_trusteeC);
    }

    // OWNER MANAGEMENT FUNCTIONS //

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

    // TRUSTEE MANAGEMENT FUNCTIONS //

    /**
     * @notice Function sets address of trusteeA.
     *
     * @param _trusteeA Address of trusteeA.
     */
    function setTrusteeA(address _trusteeA) external onlyOwner {
        trusteeA = _trusteeA;
        emit NewTrusteeA(_trusteeA);
    }

    /**
     * @notice Function sets address of trusteeB.
     *
     * @param _trusteeB Address of trusteeB.
     */
    function setTrusteeB(address _trusteeB) external onlyOwner {
        trusteeB = _trusteeB;
        emit NewTrusteeB(_trusteeB);
    }

    /**
     * @notice Function sets address of trusteeC.
     *
     * @param _trusteeC Address of trusteeC.
     */
    function setTrusteeC(address _trusteeC) external onlyOwner {
        trusteeC = _trusteeC;
        emit NewTrusteeC(_trusteeC);
    }

    // ETH TRANSACTIONS FUNCTIONS //

    /// @notice Function allows this contract to directly receive ETH.
    receive() external payable virtual {
        emit EthTransfer(msg.sender, address(this), msg.value);
    }

    /// @notice Function allows manually depositing ETH to this contract.
    function depositEth() external payable {
        emit EthTransfer(msg.sender, address(this), msg.value);
    }

    /**
     * @notice Function withdraws ETH from this contract and sends to recipient.
     *         Smart contract owner only function.
     *
     * @param recipient The address of the recipient who will receive the ETH.
     * @param ethAmount The ETH amount the recipient will receive.
     */
    function sendEth(
        address payable recipient,
        uint256 ethAmount
    ) external onlyOwnerOrTrustee {
        if (recipient == address(0)) {
            revert InvalidRecipientAddress(recipient);
        }
        if (ethAmount == 0) {
            revert InvalidEthAmount(ethAmount);
        }
        if (address(this).balance < ethAmount) {
            revert EthInsufficientBalance(address(this).balance);
        }
        (bool success, ) = recipient.call{value: ethAmount}("");
        if (!success) {
            revert UnableToSendValue(recipient);
        }
        emit EthTransfer(address(this), recipient, ethAmount);
    }

    /**
     * @notice Function withdraws all ETH from this contract and sends to recipient.
     *         Smart contract owner only function.
     *
     * @param recipient The address of the recipient who will receive the ETH.
     */
    function sendEthBalance(
        address payable recipient
    ) external onlyOwnerOrTrustee {
        if (recipient == address(0)) {
            revert InvalidRecipientAddress(recipient);
        }
        if (address(this).balance == 0) {
            revert EthInsufficientBalance(address(this).balance);
        }
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        if (!success) {
            revert UnableToSendValue(recipient);
        }
        emit EthTransfer(address(this), recipient, balance);
    }

    // ERC20 TRANSACTIONS FUNCTIONS //

    /**
     * @notice Function allows this contract to receive erc20 tokens from the caller.
     *         Caller needs to first approve this contract as a spender for the erc20 token amount they are sending to this contract using the approve function present on the erc20 token contract.
     *
     * @param token       The erc20 token contract address.
     * @param tokenAmount The erc20 token amount which this contract will receive from the caller.
     */
    function depositErc20(IERC20 token, uint256 tokenAmount) external {
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), tokenAmount);
    }

    /**
     * @notice Function withdraws erc20 token from this contract and sends to recipient.
     *         Smart contract owner only function.
     *
     * @param recipient   The address of the recipient.
     * @param token       The erc20 token contract address.
     * @param tokenAmount The erc20 token amount to be sent to the recipient.
     */
    function sendErc20(
        address recipient,
        IERC20 token,
        uint256 tokenAmount
    ) external onlyOwnerOrTrustee {
        SafeERC20.safeTransfer(token, recipient, tokenAmount);
    }

    /**
     * @notice Function withdraws erc20 token balance from this contract and sends to recipient.
     *         Smart contract owner only function.
     *
     * @param recipient The address of the recipient.
     * @param token     The erc20 token contract address.
     */
    function sendErc20Balance(
        address recipient,
        IERC20 token
    ) external onlyOwnerOrTrustee {
        SafeERC20.safeTransfer(token, recipient, token.balanceOf(address(this)));
    }

    // ERC721 TRANSACTIONS FUNCTIONS //

    /**
     * @notice Function allows this contract to receive erc721 token from the caller.
     *         Caller needs to first approve this contract as an operator for the erc721 token they are sending to this contract using the setApprovalForAll function present on the erc721 token contract.
     *
     * @param token   The erc721 token contract address.
     * @param tokenId The erc721 token ID which the contract will receive from the caller.
     */
    function depositErc721(IERC721 token, uint256 tokenId) external {
        token.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    /**
     * @notice Function withdraws erc721 token from this contract and sends to recipient.
     *         Smart contract owner only function.
     *
     * @param recipient The address of the recipient.
     * @param token     The erc721 token contract address.
     * @param tokenId   The erc721 token ID to be sent to the recipient.
     */
    function sendErc721(
        address recipient,
        IERC721 token,
        uint256 tokenId
    ) external onlyOwnerOrTrustee {
        token.safeTransferFrom(address(this), recipient, tokenId);
    }

    // ERC1155 TRANSACTIONS FUNCTIONS //

    /**
     * @notice Function allows this contract to receive erc1155 token from the caller.
     *         Caller needs to first approve this contract as an operator for the erc1155 token they are sending to this contract using the setApprovalForAll function present on the erc1155 token contract.
     *
     * @param token         The erc1155 token contract address.
     * @param tokenId       The erc1155 token ID.
     * @param tokenIdAmount The erc1155 token ID amount the contract will receive from the caller.
     */
    function depositErc1155(
        IERC1155 token,
        uint256 tokenId,
        uint256 tokenIdAmount
    ) external {
        token.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            tokenIdAmount,
            ""
        );
    }

    /**
     * @notice Function withdraws erc1155 token from this contract and sends to recipient.
     *         Smart contract owner only function.
     *
     * @param recipient     The address of the recipient.
     * @param token         The erc1155 token contract address.
     * @param tokenId       The erc1155 token ID.
     * @param tokenIdAmount The erc1155 token ID amount to be sent to the recipient.
     */
    function sendErc1155(
        address recipient,
        IERC1155 token,
        uint256 tokenId,
        uint256 tokenIdAmount
    ) external onlyOwnerOrTrustee {
        token.safeTransferFrom(
            address(this),
            recipient,
            tokenId,
            tokenIdAmount,
            ""
        );
    }
}