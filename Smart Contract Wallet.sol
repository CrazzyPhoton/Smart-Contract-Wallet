// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmartContractWallet is ERC721Holder, ERC1155Holder {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner(), "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
 
    //============================================//
    //              OWNER FUNCTIONS
    //============================================//

    /// @notice Function returns the address of the current owner.
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Function transfers ownership of the contract to a new address.
     *         Can only be called by the current smart contract owner.
     *
     * @param newOwner The address which will be the new smart contract owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner cannot be the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    //============================================//
    //               ETH TRANSACTIONS
    //============================================//

    /// @notice Function allows this contract to directly receive ETH.
    receive() external payable virtual {}

    /// @notice Function allows manually depositing ETH to this contract.
    function depositEth() external payable {}

    /** 
     * @notice Function withdraws ETH from this contract and sends to recipient.
     *         Smart contract owner only function.
     *
     * @param recipient The address of the recipient who will receive the ETH.
     * @param ethAmount The ETH amount the recipient will rececive.
     */
    function sendEth(address payable recipient, uint256 ethAmount) external onlyOwner {
        require(address(this).balance >= ethAmount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: ethAmount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    //============================================//
    //              ERC20 TRANSACTIONS
    //============================================//

    /**
     * @notice Function allows this contract to receive erc20 tokens from the caller.
     *         Caller needs to first approve this contract as a spender for the erc20 token amount they are sending to this contract using the approve function present on the erc20 token contract.
     * 
     * @param token       The erc20 token contract address.
     * @param tokenAmount The erc20 token amount which this contract will receive from the caller. 
     */
    function depositErc20(IERC20 token, uint256 tokenAmount) external {
        token.transferFrom(msg.sender, address(this), tokenAmount);
    }

    /**
     * @notice Function withdraws erc20 tokens from this contract and sends to recipient.
     *         Smart contract owner only function.
     * 
     * @param recipient   The address of the recipient.
     * @param token       The erc20 token contract address.
     * @param tokenAmount The erc20 token amount to be sent to the recipient. 
     */
    function sendErc20(address recipient, IERC20 token, uint256 tokenAmount) external onlyOwner {
        token.transfer(recipient, tokenAmount);
    }

    //============================================//
    //             ERC721 TRANSACTIONS
    //============================================//

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
    function sendErc721(address recipient, IERC721 token, uint256 tokenId) external onlyOwner {
        token.safeTransferFrom(address(this), recipient, tokenId);
    }

    //============================================//
    //            ERC1155 TRANSACTIONS
    //============================================//

    /**
     * @notice Function allows this contract to receive erc1155 token from the caller.
     *         Caller needs to first approve this contract as an operator for the erc1155 token they are sending to this contract using the setApprovalForAll function present on the erc1155 token contract.
     * 
     * @param token         The erc1155 token contract address.
     * @param tokenId       The erc1155 token ID.
     * @param tokenIdAmount The erc1155 token ID amount the contract will receive from the caller.
     */
    function depositErc1155(IERC1155 token, uint256 tokenId, uint256 tokenIdAmount) external {
        token.safeTransferFrom(msg.sender, address(this), tokenId, tokenIdAmount, "");
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
    function sendErc1155(address recipient, IERC1155 token, uint256 tokenId, uint256 tokenIdAmount) external onlyOwner {
        token.safeTransferFrom(address(this), recipient, tokenId, tokenIdAmount, "");
    }

}
