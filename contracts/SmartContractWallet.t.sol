// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/src/Test.sol";
import "../contracts/SmartContractWallet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// Mock contracts for testing
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract MockERC721 is ERC721 {
    uint256 public tokenIdCounter;

    constructor() ERC721("Mock NFT", "MNFT") {}

    function mint(address to) public returns (uint256) {
        uint256 tokenId = tokenIdCounter++;
        _mint(to, tokenId);
        return tokenId;
    }
}

contract MockERC1155 is ERC1155 {
    constructor() ERC1155("https://mock.com/{id}.json") {}

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        _mint(to, id, amount, data);
    }
}

// Contract to test failed ETH transfers
contract RejectEther {
    receive() external payable {
        revert("Rejecting ether");
    }
}

contract SmartContractWalletTest is Test, ERC1155Holder {
    SmartContractWallet public wallet;
    MockERC20 public mockERC20;
    MockERC721 public mockERC721;
    MockERC1155 public mockERC1155;
    RejectEther public rejectEther;

    // Test addresses
    address public owner;
    address public trusteeA = address(0x1);
    address public trusteeB = address(0x2);
    address public trusteeC = address(0x3);
    address public otherUser = address(0x4);
    address payable public recipient = payable(address(0x5));
    address public newOwner = address(0x6);

    // Events to test
    event EthTransfer(
        address indexed from,
        address indexed to,
        uint256 indexed amount
    );
    event NewTrusteeA(address indexed _trusteeA);
    event NewTrusteeB(address indexed _trusteeB);
    event NewTrusteeC(address indexed _trusteeC);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setUp() public {
        owner = address(this);
        wallet = new SmartContractWallet(owner, trusteeA, trusteeB, trusteeC);

        // Deploy mock tokens
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();
        mockERC1155 = new MockERC1155();
        rejectEther = new RejectEther();
    }

    // ===== CONSTRUCTOR TESTS =====

    function testConstructorSetsCorrectValues() public view {
        assertEq(wallet.owner(), owner);
        assertEq(wallet.trusteeA(), trusteeA);
        assertEq(wallet.trusteeB(), trusteeB);
        assertEq(wallet.trusteeC(), trusteeC);
    }

    function testConstructorEmitsEvents() public {
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(address(0), owner);
        vm.expectEmit(true, false, false, true);
        emit NewTrusteeA(trusteeA);
        vm.expectEmit(true, false, false, true);
        emit NewTrusteeB(trusteeB);
        vm.expectEmit(true, false, false, true);
        emit NewTrusteeC(trusteeC);

        new SmartContractWallet(owner, trusteeA, trusteeB, trusteeC);
    }

    function testConstructorRevertsForZeroAddressOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.InvalidNewOwner.selector,
                address(0)
            )
        );
        new SmartContractWallet(address(0), trusteeA, trusteeB, trusteeC);
    }

    function testConstructorAllowsZeroAddressTrustees() public {
        SmartContractWallet testWallet = new SmartContractWallet(
            owner,
            address(0),
            address(0),
            address(0)
        );

        assertEq(testWallet.trusteeA(), address(0));
        assertEq(testWallet.trusteeB(), address(0));
        assertEq(testWallet.trusteeC(), address(0));
    }

    // ===== OWNERSHIP MANAGEMENT TESTS =====

    function testTransferOwnershipSuccess() public {
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(owner, newOwner);

        wallet.transferOwnership(newOwner);
        assertEq(wallet.owner(), newOwner);
    }

    function testTransferOwnershipRevertsForZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.InvalidNewOwner.selector,
                address(0)
            )
        );
        wallet.transferOwnership(address(0));
    }

    function testTransferOwnershipOnlyOwner() public {
        vm.prank(otherUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.CallerNotOwner.selector,
                otherUser
            )
        );
        wallet.transferOwnership(newOwner);
    }

    function testTransferOwnershipPreventsOldOwnerAccess() public {
        wallet.transferOwnership(newOwner);

        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.CallerNotOwner.selector,
                address(this)
            )
        );
        wallet.setTrusteeA(address(0x999));
    }

    // ===== TRUSTEE MANAGEMENT TESTS =====

    function testSetTrusteeASuccess() public {
        address newTrusteeA = address(0x7);

        vm.expectEmit(true, false, false, true);
        emit NewTrusteeA(newTrusteeA);

        wallet.setTrusteeA(newTrusteeA);
        assertEq(wallet.trusteeA(), newTrusteeA);
    }

    function testSetTrusteeBSuccess() public {
        address newTrusteeB = address(0x8);

        vm.expectEmit(true, false, false, true);
        emit NewTrusteeB(newTrusteeB);

        wallet.setTrusteeB(newTrusteeB);
        assertEq(wallet.trusteeB(), newTrusteeB);
    }

    function testSetTrusteeCSuccess() public {
        address newTrusteeC = address(0x9);

        vm.expectEmit(true, false, false, true);
        emit NewTrusteeC(newTrusteeC);

        wallet.setTrusteeC(newTrusteeC);
        assertEq(wallet.trusteeC(), newTrusteeC);
    }

    function testSetTrusteeOnlyOwner() public {
        vm.prank(otherUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.CallerNotOwner.selector,
                otherUser
            )
        );
        wallet.setTrusteeA(address(0x123));
    }

    function testSetTrusteeAllowsZeroAddress() public {
        wallet.setTrusteeA(address(0));
        assertEq(wallet.trusteeA(), address(0));
    }

    // ===== ETH TRANSACTION TESTS =====

    function testReceiveEthSuccess() public {
        uint256 amount = 1 ether;
        address sender = address(0x123);

        vm.deal(sender, amount);
        vm.expectEmit(true, true, true, true);
        emit EthTransfer(sender, address(wallet), amount);

        vm.prank(sender);
        (bool success, ) = address(wallet).call{value: amount}("");

        assertTrue(success);
        assertEq(address(wallet).balance, amount);
    }

    function testDepositEthSuccess() public {
        uint256 amount = 1 ether;
        address sender = address(0x123);

        vm.deal(sender, amount);
        vm.expectEmit(true, true, true, true);
        emit EthTransfer(sender, address(wallet), amount);

        vm.prank(sender);
        wallet.depositEth{value: amount}();

        assertEq(address(wallet).balance, amount);
    }

    function testDepositEthZeroAmount() public {
        vm.expectEmit(true, true, true, true);
        emit EthTransfer(address(this), address(wallet), 0);

        wallet.depositEth{value: 0}();
    }

    function testSendEthSuccess() public {
        uint256 amount = 1 ether;
        vm.deal(address(wallet), amount);

        vm.expectEmit(true, true, true, true);
        emit EthTransfer(address(wallet), recipient, amount);

        wallet.sendEth(recipient, amount);

        assertEq(address(wallet).balance, 0);
        assertEq(recipient.balance, amount);
    }

    function testSendEthByTrustees() public {
        uint256 amount = 1 ether;
        vm.deal(address(wallet), amount * 3);

        // TrusteeA sends
        vm.prank(trusteeA);
        wallet.sendEth(recipient, amount);

        // TrusteeB sends
        vm.prank(trusteeB);
        wallet.sendEth(recipient, amount);

        // TrusteeC sends
        vm.prank(trusteeC);
        wallet.sendEth(recipient, amount);

        assertEq(address(wallet).balance, 0);
        assertEq(recipient.balance, amount * 3);
    }

    function testSendEthRevertsForZeroRecipient() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.InvalidRecipientAddress.selector,
                address(0)
            )
        );
        wallet.sendEth(payable(address(0)), 1 ether);
    }

    function testSendEthRevertsForZeroAmount() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.InvalidEthAmount.selector,
                0
            )
        );
        wallet.sendEth(recipient, 0);
    }

    function testSendEthRevertsForInsufficientBalance() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.EthInsufficientBalance.selector,
                0
            )
        );
        wallet.sendEth(recipient, 1 ether);
    }

    function testSendEthRevertsForUnauthorizedCaller() public {
        vm.prank(otherUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.CallerNotOwnerNorTrustee.selector,
                otherUser
            )
        );
        wallet.sendEth(recipient, 1 ether);
    }

    function testSendEthRevertsWhenTransferFails() public {
        uint256 amount = 1 ether;
        vm.deal(address(wallet), amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.UnableToSendValue.selector,
                address(rejectEther)
            )
        );
        wallet.sendEth(payable(address(rejectEther)), amount);
    }

    function testSendEthBalanceRevertsWhenTransferFails() public {
        uint256 amount = 1 ether;
        vm.deal(address(wallet), amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.UnableToSendValue.selector,
                address(rejectEther)
            )
        );
        wallet.sendEthBalance(payable(address(rejectEther)));
    }

    function testSendEthBalanceSuccess() public {
        uint256 amount = 1 ether;
        vm.deal(address(wallet), amount);

        vm.expectEmit(true, true, true, true);
        emit EthTransfer(address(wallet), recipient, amount);

        wallet.sendEthBalance(recipient);

        assertEq(address(wallet).balance, 0);
        assertEq(recipient.balance, amount);
    }

    function testSendEthBalanceRevertsForZeroRecipient() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.InvalidRecipientAddress.selector,
                address(0)
            )
        );
        wallet.sendEthBalance(payable(address(0)));
    }

    function testSendEthBalanceRevertsForZeroBalance() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.EthInsufficientBalance.selector,
                0
            )
        );
        wallet.sendEthBalance(recipient);
    }

    function testSendEthBalanceRevertsForUnauthorizedCaller() public {
        vm.prank(otherUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.CallerNotOwnerNorTrustee.selector,
                otherUser
            )
        );
        wallet.sendEthBalance(recipient);
    }

    // ===== ERC20 TRANSACTION TESTS =====

    function testDepositErc20Success() public {
        uint256 amount = 1000 * 10 ** 18;

        // Approve wallet to spend tokens
        mockERC20.approve(address(wallet), amount);

        // Deposit tokens
        wallet.depositErc20(mockERC20, amount);

        assertEq(mockERC20.balanceOf(address(wallet)), amount);
        assertEq(
            mockERC20.balanceOf(address(this)),
            mockERC20.totalSupply() - amount
        );
    }

    function testDepositErc20RevertsWithoutApproval() public {
        uint256 amount = 1000 * 10 ** 18;

        vm.expectRevert();
        wallet.depositErc20(mockERC20, amount);
    }

    function testSendErc20Success() public {
        uint256 amount = 1000 * 10 ** 18;

        // Setup: deposit tokens to wallet
        mockERC20.approve(address(wallet), amount);
        wallet.depositErc20(mockERC20, amount);

        // Send tokens
        wallet.sendErc20(recipient, mockERC20, amount);

        assertEq(mockERC20.balanceOf(address(wallet)), 0);
        assertEq(mockERC20.balanceOf(recipient), amount);
    }

    function testSendErc20ByTrustees() public {
        uint256 amount = 300 * 10 ** 18;

        // Setup: deposit tokens to wallet
        mockERC20.approve(address(wallet), amount * 3);
        wallet.depositErc20(mockERC20, amount * 3);

        // Trustees send tokens
        vm.prank(trusteeA);
        wallet.sendErc20(recipient, mockERC20, amount);

        vm.prank(trusteeB);
        wallet.sendErc20(recipient, mockERC20, amount);

        vm.prank(trusteeC);
        wallet.sendErc20(recipient, mockERC20, amount);

        assertEq(mockERC20.balanceOf(address(wallet)), 0);
        assertEq(mockERC20.balanceOf(recipient), amount * 3);
    }

    function testSendErc20RevertsForUnauthorizedCaller() public {
        vm.prank(otherUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.CallerNotOwnerNorTrustee.selector,
                otherUser
            )
        );
        wallet.sendErc20(recipient, mockERC20, 100);
    }

    function testSendErc20BalanceSuccess() public {
        uint256 amount = 1000 * 10 ** 18;

        // Setup: deposit tokens to wallet
        mockERC20.approve(address(wallet), amount);
        wallet.depositErc20(mockERC20, amount);

        // Send all balance
        wallet.sendErc20Balance(recipient, mockERC20);

        assertEq(mockERC20.balanceOf(address(wallet)), 0);
        assertEq(mockERC20.balanceOf(recipient), amount);
    }

    function testSendErc20BalanceRevertsForUnauthorizedCaller() public {
        vm.prank(otherUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.CallerNotOwnerNorTrustee.selector,
                otherUser
            )
        );
        wallet.sendErc20Balance(recipient, mockERC20);
    }

    // ===== ERC721 TRANSACTION TESTS =====

    function testDepositErc721Success() public {
        uint256 tokenId = mockERC721.mint(address(this));

        // Approve wallet for all tokens
        mockERC721.setApprovalForAll(address(wallet), true);

        // Deposit NFT
        wallet.depositErc721(mockERC721, tokenId);

        assertEq(mockERC721.ownerOf(tokenId), address(wallet));
    }

    function testDepositErc721RevertsWithoutApproval() public {
        uint256 tokenId = mockERC721.mint(address(this));

        vm.expectRevert();
        wallet.depositErc721(mockERC721, tokenId);
    }

    function testSendErc721Success() public {
        uint256 tokenId = mockERC721.mint(address(this));

        // Setup: deposit NFT to wallet
        mockERC721.setApprovalForAll(address(wallet), true);
        wallet.depositErc721(mockERC721, tokenId);

        // Send NFT
        wallet.sendErc721(recipient, mockERC721, tokenId);

        assertEq(mockERC721.ownerOf(tokenId), recipient);
    }

    function testSendErc721ByTrustees() public {
        uint256[] memory tokenIds = new uint256[](3);
        for (uint i = 0; i < 3; i++) {
            tokenIds[i] = mockERC721.mint(address(this));
        }

        // Setup: deposit NFTs to wallet
        mockERC721.setApprovalForAll(address(wallet), true);
        for (uint i = 0; i < 3; i++) {
            wallet.depositErc721(mockERC721, tokenIds[i]);
        }

        // Trustees send NFTs
        vm.prank(trusteeA);
        wallet.sendErc721(recipient, mockERC721, tokenIds[0]);

        vm.prank(trusteeB);
        wallet.sendErc721(recipient, mockERC721, tokenIds[1]);

        vm.prank(trusteeC);
        wallet.sendErc721(recipient, mockERC721, tokenIds[2]);

        for (uint i = 0; i < 3; i++) {
            assertEq(mockERC721.ownerOf(tokenIds[i]), recipient);
        }
    }

    function testSendErc721RevertsForUnauthorizedCaller() public {
        vm.prank(otherUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.CallerNotOwnerNorTrustee.selector,
                otherUser
            )
        );
        wallet.sendErc721(recipient, mockERC721, 0);
    }

    // ===== ERC1155 TRANSACTION TESTS =====

    function testDepositErc1155Success() public {
        uint256 tokenId = 1;
        uint256 amount = 100;

        // Mint tokens to this contract
        mockERC1155.mint(address(this), tokenId, amount, "");

        // Approve wallet for all tokens
        mockERC1155.setApprovalForAll(address(wallet), true);

        // Deposit ERC1155
        wallet.depositErc1155(mockERC1155, tokenId, amount);

        assertEq(mockERC1155.balanceOf(address(wallet), tokenId), amount);
        assertEq(mockERC1155.balanceOf(address(this), tokenId), 0);
    }

    function testDepositErc1155RevertsWithoutApproval() public {
        uint256 tokenId = 1;
        uint256 amount = 100;

        mockERC1155.mint(address(this), tokenId, amount, "");

        vm.expectRevert();
        wallet.depositErc1155(mockERC1155, tokenId, amount);
    }

    function testSendErc1155Success() public {
        uint256 tokenId = 1;
        uint256 amount = 100;

        // Setup: deposit ERC1155 to wallet
        mockERC1155.mint(address(this), tokenId, amount, "");
        mockERC1155.setApprovalForAll(address(wallet), true);
        wallet.depositErc1155(mockERC1155, tokenId, amount);

        // Send ERC1155
        wallet.sendErc1155(recipient, mockERC1155, tokenId, amount);

        assertEq(mockERC1155.balanceOf(address(wallet), tokenId), 0);
        assertEq(mockERC1155.balanceOf(recipient, tokenId), amount);
    }

    function testSendErc1155ByTrustees() public {
        uint256 tokenId = 1;
        uint256 amount = 300;
        uint256 amountPerTrustee = 100;

        // Setup: deposit ERC1155 to wallet
        mockERC1155.mint(address(this), tokenId, amount, "");
        mockERC1155.setApprovalForAll(address(wallet), true);
        wallet.depositErc1155(mockERC1155, tokenId, amount);

        // Trustees send tokens
        vm.prank(trusteeA);
        wallet.sendErc1155(recipient, mockERC1155, tokenId, amountPerTrustee);

        vm.prank(trusteeB);
        wallet.sendErc1155(recipient, mockERC1155, tokenId, amountPerTrustee);

        vm.prank(trusteeC);
        wallet.sendErc1155(recipient, mockERC1155, tokenId, amountPerTrustee);

        assertEq(mockERC1155.balanceOf(address(wallet), tokenId), 0);
        assertEq(mockERC1155.balanceOf(recipient, tokenId), amount);
    }

    function testSendErc1155RevertsForUnauthorizedCaller() public {
        vm.prank(otherUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                SmartContractWallet.CallerNotOwnerNorTrustee.selector,
                otherUser
            )
        );
        wallet.sendErc1155(recipient, mockERC1155, 1, 100);
    }

    // ===== INTEGRATION TESTS =====

    function testCompleteWorkflow() public {
        uint256 ethAmount = 1 ether;
        uint256 erc20Amount = 1000 * 10 ** 18;
        uint256 tokenId = 1;
        uint256 erc1155Amount = 100;

        // 1. Deposit ETH
        vm.deal(address(this), ethAmount);
        wallet.depositEth{value: ethAmount}();

        // 2. Deposit ERC20
        mockERC20.approve(address(wallet), erc20Amount);
        wallet.depositErc20(mockERC20, erc20Amount);

        // 3. Deposit ERC721
        uint256 nftId = mockERC721.mint(address(this));
        mockERC721.setApprovalForAll(address(wallet), true);
        wallet.depositErc721(mockERC721, nftId);

        // 4. Deposit ERC1155
        mockERC1155.mint(address(this), tokenId, erc1155Amount, "");
        mockERC1155.setApprovalForAll(address(wallet), true);
        wallet.depositErc1155(mockERC1155, tokenId, erc1155Amount);

        // 5. Transfer ownership
        wallet.transferOwnership(newOwner);

        // 6. New owner withdraws everything
        vm.startPrank(newOwner);
        wallet.sendEthBalance(recipient);
        wallet.sendErc20Balance(recipient, mockERC20);
        wallet.sendErc721(recipient, mockERC721, nftId);
        wallet.sendErc1155(recipient, mockERC1155, tokenId, erc1155Amount);
        vm.stopPrank();

        // Verify final state
        assertEq(address(wallet).balance, 0);
        assertEq(mockERC20.balanceOf(address(wallet)), 0);
        assertEq(mockERC721.ownerOf(nftId), recipient);
        assertEq(mockERC1155.balanceOf(address(wallet), tokenId), 0);
    }

    // ===== FUZZ TESTS =====

    function testFuzzTransferOwnership(address _newOwner) public {
        vm.assume(_newOwner != address(0));

        wallet.transferOwnership(_newOwner);
        assertEq(wallet.owner(), _newOwner);
    }

    function testFuzzSetTrustees(
        address _trusteeA,
        address _trusteeB,
        address _trusteeC
    ) public {
        wallet.setTrusteeA(_trusteeA);
        wallet.setTrusteeB(_trusteeB);
        wallet.setTrusteeC(_trusteeC);

        assertEq(wallet.trusteeA(), _trusteeA);
        assertEq(wallet.trusteeB(), _trusteeB);
        assertEq(wallet.trusteeC(), _trusteeC);
    }

    function testFuzzSendEth(
        address payable _recipient,
        uint256 _amount
    ) public {
        vm.assume(_recipient != address(0));
        vm.assume(uint160(address(_recipient)) > 0x1000);
        vm.assume(_amount > 0 && _amount <= 100 ether);

        vm.assume(
            uint160(address(_recipient)) <
                uint160(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)
        );
        vm.assume(_recipient.code.length == 0); // Only EOAs (Externally Owned Accounts)

        vm.deal(address(wallet), _amount);
        wallet.sendEth(_recipient, _amount);

        assertEq(address(wallet).balance, 0);
        assertEq(_recipient.balance, _amount);
    }

    // ===== EDGE CASE TESTS =====

    function testMultipleDepositsAndWithdrawals() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 0.3 ether;

        // Multiple deposits
        for (uint i = 0; i < 5; i++) {
            vm.deal(address(this), depositAmount);
            wallet.depositEth{value: depositAmount}();
        }

        assertEq(address(wallet).balance, depositAmount * 5);

        // Multiple partial withdrawals
        for (uint i = 0; i < 5; i++) {
            wallet.sendEth(recipient, withdrawAmount);
        }

        assertEq(
            address(wallet).balance,
            depositAmount * 5 - withdrawAmount * 5
        );
    }

    function testZeroValueDeposits() public {
        // ETH
        wallet.depositEth{value: 0}();
        assertEq(address(wallet).balance, 0);

        // ERC20
        mockERC20.approve(address(wallet), 0);
        wallet.depositErc20(mockERC20, 0);

        // ERC1155
        mockERC1155.mint(address(this), 1, 0, "");
        mockERC1155.setApprovalForAll(address(wallet), true);
        wallet.depositErc1155(mockERC1155, 1, 0);
    }
}
