// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/src/Test.sol";
import "../contracts/SmartContractWallet.sol";
import "../contracts/FactoryContractForSmartContractWallet.sol";

contract FactoryContractForSmartContractWalletTest is Test {
    FactoryContractForSmartContractWallet public factory;
    
    // Test addresses
    address public owner;
    address public trusteeA = address(0x1);
    address public trusteeB = address(0x2);
    address public trusteeC = address(0x3);
    address public otherUser = address(0x4);
    address public newOwner = address(0x5);

    // Events to test
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SmartContractWalletDeployed(
        address indexed smartContractWalletAddress,
        address indexed smartContractWalletOwner
    );

    function setUp() public {
        owner = address(this);
        factory = new FactoryContractForSmartContractWallet();
    }

    // ===== CONSTRUCTOR TESTS =====
    
    function testConstructorSetsOwnerCorrectly() public view {
        assertEq(factory.owner(), address(this));
    }

    function testConstructorEmitsOwnershipTransferredEvent() public {
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(address(0), address(this));
        
        new FactoryContractForSmartContractWallet();
    }

    function testConstructorSetsDeploymentNotPaused() public view {
        assertEq(factory.isDeploymentPaused(), false);
    }

    // ===== DEPLOY SMART CONTRACT WALLET TESTS =====

    function testDeploySmartContractWalletSuccess() public {
        (address walletAddress, address walletOwner) = factory.deploySmartContractWallet(
            owner,
            trusteeA,
            trusteeB,
            trusteeC
        );

        // Check return values
        assertTrue(walletAddress != address(0));
        assertEq(walletOwner, owner);

        // Check wallet is stored correctly
        address[] memory wallets = factory.getSmartContractWalletsOfAddress(owner);
        assertEq(wallets.length, 1);
        assertEq(wallets[0], walletAddress);

        // Verify the deployed wallet has correct parameters
        SmartContractWallet wallet = SmartContractWallet(payable(walletAddress));
        assertEq(wallet.owner(), owner);
        assertEq(wallet.trusteeA(), trusteeA);
        assertEq(wallet.trusteeB(), trusteeB);
        assertEq(wallet.trusteeC(), trusteeC);
    }

    function testDeploySmartContractWalletEmitsEvent() public {
        vm.expectEmit(false, true, false, true);
        emit SmartContractWalletDeployed(address(0), owner);
        
        factory.deploySmartContractWallet(owner, trusteeA, trusteeB, trusteeC);
    }

    function testDeployMultipleWalletsForSameOwner() public {
        // Deploy first wallet
        factory.deploySmartContractWallet(owner, trusteeA, trusteeB, trusteeC);
        
        // Deploy second wallet
        factory.deploySmartContractWallet(owner, trusteeA, trusteeB, trusteeC);

        address[] memory wallets = factory.getSmartContractWalletsOfAddress(owner);
        assertEq(wallets.length, 2);
        assertTrue(wallets[0] != wallets[1]);
    }

    function testDeployWalletsForDifferentOwners() public {
        // Deploy wallet for owner
        factory.deploySmartContractWallet(owner, trusteeA, trusteeB, trusteeC);
        
        // Deploy wallet for otherUser
        factory.deploySmartContractWallet(otherUser, trusteeA, trusteeB, trusteeC);

        address[] memory ownerWallets = factory.getSmartContractWalletsOfAddress(owner);
        address[] memory otherUserWallets = factory.getSmartContractWalletsOfAddress(otherUser);
        
        assertEq(ownerWallets.length, 1);
        assertEq(otherUserWallets.length, 1);
        assertTrue(ownerWallets[0] != otherUserWallets[0]);
    }

    function testDeploySmartContractWalletRevertsWhenPaused() public {
        factory.pauseDeployment();

        vm.expectRevert(
            abi.encodeWithSelector(FactoryContractForSmartContractWallet.DeploymentPaused.selector)
        );
        factory.deploySmartContractWallet(owner, trusteeA, trusteeB, trusteeC);
    }

    function testDeploySmartContractWalletWithZeroAddressOwner() public {
        // This should work as the SmartContractWallet constructor handles the validation
        vm.expectRevert(
            abi.encodeWithSelector(SmartContractWallet.InvalidNewOwner.selector, address(0))
        );
        factory.deploySmartContractWallet(address(0), trusteeA, trusteeB, trusteeC);
    }

    // ===== PAUSE DEPLOYMENT TESTS =====

    function testPauseDeploymentTogglesState() public {
        bool initial = factory.isDeploymentPaused();
        
        factory.pauseDeployment();
        assertEq(factory.isDeploymentPaused(), !initial);
        
        factory.pauseDeployment();
        assertEq(factory.isDeploymentPaused(), initial);
    }

    function testPauseDeploymentOnlyOwnerCanCall() public {
        vm.prank(otherUser);
        vm.expectRevert(
            abi.encodeWithSelector(FactoryContractForSmartContractWallet.CallerNotOwner.selector, otherUser)
        );
        factory.pauseDeployment();
    }

    function testPauseDeploymentWorksAfterOwnershipTransfer() public {
        factory.transferOwnership(newOwner);
        
        vm.prank(newOwner);
        factory.pauseDeployment();
        
        assertTrue(factory.isDeploymentPaused());
    }

    // ===== TRANSFER OWNERSHIP TESTS =====

    function testTransferOwnershipChangesOwner() public {
        factory.transferOwnership(newOwner);
        assertEq(factory.owner(), newOwner);
    }

    function testTransferOwnershipEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(address(this), newOwner);
        
        factory.transferOwnership(newOwner);
    }

    function testTransferOwnershipRevertsForZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(FactoryContractForSmartContractWallet.InvalidNewOwner.selector, address(0))
        );
        factory.transferOwnership(address(0));
    }

    function testTransferOwnershipOnlyOwnerCanCall() public {
        vm.prank(otherUser);
        vm.expectRevert(
            abi.encodeWithSelector(FactoryContractForSmartContractWallet.CallerNotOwner.selector, otherUser)
        );
        factory.transferOwnership(newOwner);
    }

    function testTransferOwnershipPreventsOldOwnerFromActions() public {
        factory.transferOwnership(newOwner);
        
        // Original owner should no longer be able to pause deployment
        vm.expectRevert(
            abi.encodeWithSelector(FactoryContractForSmartContractWallet.CallerNotOwner.selector, address(this))
        );
        factory.pauseDeployment();
    }

    // ===== GET SMART CONTRACT WALLETS TESTS =====

    function testGetSmartContractWalletsOfAddressReturnsCorrectWallets() public {
        // Deploy two wallets
        (address wallet1,) = factory.deploySmartContractWallet(owner, trusteeA, trusteeB, trusteeC);
        (address wallet2,) = factory.deploySmartContractWallet(owner, trusteeA, trusteeB, trusteeC);

        address[] memory wallets = factory.getSmartContractWalletsOfAddress(owner);
        
        assertEq(wallets.length, 2);
        assertEq(wallets[0], wallet1);
        assertEq(wallets[1], wallet2);
    }

    function testGetSmartContractWalletsOfAddressReturnsEmptyForNoWallets() public view {
        address[] memory wallets = factory.getSmartContractWalletsOfAddress(otherUser);
        assertEq(wallets.length, 0);
    }

    function testGetSmartContractWalletsOfAddressWithZeroAddress() public view {
        address[] memory wallets = factory.getSmartContractWalletsOfAddress(address(0));
        assertEq(wallets.length, 0);
    }

    // ===== INTEGRATION TESTS =====

    function testCompleteWorkflow() public {
        // 1. Deploy a wallet
        (address wallet1,) = factory.deploySmartContractWallet(owner, trusteeA, trusteeB, trusteeC);
        
        // 2. Pause deployment
        factory.pauseDeployment();
        
        // 3. Verify deployment is paused
        vm.expectRevert(
            abi.encodeWithSelector(FactoryContractForSmartContractWallet.DeploymentPaused.selector)
        );
        factory.deploySmartContractWallet(owner, trusteeA, trusteeB, trusteeC);
        
        // 4. Unpause deployment
        factory.pauseDeployment();
        
        // 5. Deploy another wallet
        (address wallet2,) = factory.deploySmartContractWallet(owner, trusteeA, trusteeB, trusteeC);
        
        // 6. Verify both wallets are stored
        address[] memory wallets = factory.getSmartContractWalletsOfAddress(owner);
        assertEq(wallets.length, 2);
        assertEq(wallets[0], wallet1);
        assertEq(wallets[1], wallet2);
        
        // 7. Transfer ownership
        factory.transferOwnership(newOwner);
        assertEq(factory.owner(), newOwner);
    }

    // ===== FUZZ TESTS =====

    function testFuzzDeploySmartContractWallet(
        address _owner,
        address _trusteeA,
        address _trusteeB,
        address _trusteeC
    ) public {
        vm.assume(_owner != address(0));
        
        (address walletAddress, address walletOwner) = factory.deploySmartContractWallet(
            _owner,
            _trusteeA,
            _trusteeB,
            _trusteeC
        );
        
        assertTrue(walletAddress != address(0));
        assertEq(walletOwner, _owner);
        
        address[] memory wallets = factory.getSmartContractWalletsOfAddress(_owner);
        assertEq(wallets.length, 1);
        assertEq(wallets[0], walletAddress);
    }

    function testFuzzTransferOwnership(address _newOwner) public {
        vm.assume(_newOwner != address(0));
        
        factory.transferOwnership(_newOwner);
        assertEq(factory.owner(), _newOwner);
    }
}
