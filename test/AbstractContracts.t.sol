// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/AbstractContracts.sol";

contract AbstractContractsTest is Test {
    OwnedContract public ownedContract;
    SimplePaymentProcessor public paymentProcessor;
    ComplexContract public complexContract;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public recipient = address(0x3);
    
    function setUp() public {
        ownedContract = new OwnedContract();
        paymentProcessor = new SimplePaymentProcessor(recipient);
        complexContract = new ComplexContract();
        
        // Fund test accounts
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(address(this), 10 ether);
    }
    
    // ==================== OWNABLE TESTS ====================
    
    function test_Ownable_InitialOwner() public {
        assertEq(ownedContract.owner(), address(this));
    }
    
    function test_Ownable_TransferOwnership() public {
        ownedContract.transferOwnership(user1);
        assertEq(ownedContract.owner(), user1);
    }
    
    function test_Ownable_OnlyOwnerModifier() public {
        vm.prank(user1);
        vm.expectRevert("Not the owner");
        ownedContract.setValue(100);
    }
    
    function test_Ownable_RenounceOwnership() public {
        ownedContract.renounceOwnership();
        assertEq(ownedContract.owner(), address(0));
    }
    
    function test_Ownable_RenounceWithValue() public {
        ownedContract.setValue(100);
        
        vm.expectRevert("Cannot renounce with non-zero value");
        ownedContract.renounceOwnership();
    }
    
    // ==================== PAYMENT PROCESSOR TESTS ====================
    
    function test_PaymentProcessor_MakePayment() public {
        vm.startPrank(user1);
        
        uint256 balanceBefore = recipient.balance;
        uint256 paymentAmount = 1 ether;
        
        paymentProcessor.makePayment{value: paymentAmount}();
        
        // Check payment was processed
        (address payer, uint256 amount, uint256 timestamp, bool processed) = 
            paymentProcessor.payments(0);
        
        assertEq(payer, user1);
        assertEq(amount, paymentAmount);
        assertTrue(processed);
        assertTrue(timestamp > 0);
        
        // Check recipient received funds minus fee (3%)
        uint256 expectedAmount = paymentAmount * 97 / 100;
        assertEq(recipient.balance, balanceBefore + expectedAmount);
        
        vm.stopPrank();
    }
    
    function test_PaymentProcessor_InvalidPayment() public {
        vm.startPrank(user1);
        
        // Try to send less than minimum
        vm.expectRevert("Invalid payment");
        paymentProcessor.makePayment{value: 0.001 ether}();
        
        // Try to send more than maximum  
        vm.expectRevert("Invalid payment");
        paymentProcessor.makePayment{value: 11 ether}();
        
        vm.stopPrank();
    }
    
    function test_PaymentProcessor_UpdateLimits() public {
        paymentProcessor.updateLimits(0.1 ether, 20 ether);
        
        assertEq(paymentProcessor.minPayment(), 0.1 ether);
        assertEq(paymentProcessor.maxPayment(), 20 ether);
    }
    
    function test_PaymentProcessor_MultiplePayments() public {
        vm.prank(user1);
        paymentProcessor.makePayment{value: 1 ether}();
        
        vm.prank(user2);
        paymentProcessor.makePayment{value: 2 ether}();
        
        assertEq(paymentProcessor.paymentCounter(), 2);
    }
    
    // ==================== COMPLEX CONTRACT TESTS ====================
    
    function test_ComplexContract_Deposit() public {
        vm.startPrank(user1);
        
        uint256 depositAmount = 2 ether;
        complexContract.deposit{value: depositAmount}();
        
        assertEq(complexContract.balances(user1), depositAmount);
        
        vm.stopPrank();
    }
    
    function test_ComplexContract_Withdraw() public {
        vm.startPrank(user1);
        
        // Deposit first
        complexContract.deposit{value: 3 ether}();
        
        // Withdraw
        uint256 balanceBefore = user1.balance;
        complexContract.withdraw(1 ether);
        
        assertEq(user1.balance, balanceBefore + 1 ether);
        assertEq(complexContract.balances(user1), 2 ether);
        
        vm.stopPrank();
    }
    
    function test_ComplexContract_Pausable() public {
        // Only owner can pause
        complexContract.pause();
        assertTrue(complexContract.paused());
        
        // Cannot deposit when paused
        vm.prank(user1);
        vm.expectRevert("Contract is paused");
        complexContract.deposit{value: 1 ether}();
        
        // Unpause
        complexContract.unpause();
        assertFalse(complexContract.paused());
        
        // Now can deposit
        vm.prank(user1);
        complexContract.deposit{value: 1 ether}();
    }
    
    function test_ComplexContract_RateLimit() public {
        vm.startPrank(user1);
        
        // First deposit should work
        complexContract.deposit{value: 1 ether}();
        
        // Second deposit immediately should fail
        vm.expectRevert("Rate limit exceeded");
        complexContract.deposit{value: 1 ether}();
        
        // Wait for rate limit
        vm.warp(block.timestamp + 61);
        
        // Now should work
        complexContract.deposit{value: 1 ether}();
        
        vm.stopPrank();
    }
    
    function test_ComplexContract_OwnerExemptFromRateLimit() public {
        // Owner should be exempt from rate limit
        complexContract.deposit{value: 1 ether}();
        complexContract.deposit{value: 1 ether}();  // Should not revert
        
        assertEq(complexContract.balances(address(this)), 2 ether);
    }
    
    // ==================== INHERITANCE TESTS ====================
    
    function test_MultipleInheritance() public {
        // ComplexContract inherits from Ownable, Pausable, and RateLimited
        
        // Test Ownable functionality
        assertEq(complexContract.owner(), address(this));
        
        // Test Pausable functionality
        assertFalse(complexContract.paused());
        complexContract.pause();
        assertTrue(complexContract.paused());
        
        // Test RateLimited functionality
        assertTrue(complexContract.checkRateLimit(address(this)));  // Owner exempt
        assertFalse(complexContract.checkRateLimit(user1));  // User not exempt
    }
    
    // ==================== FUZZ TESTS ====================
    
    function testFuzz_PaymentProcessor(uint256 amount) public {
        vm.assume(amount >= 0.01 ether && amount <= 10 ether);
        vm.deal(user1, amount);
        
        vm.startPrank(user1);
        
        uint256 recipientBalanceBefore = recipient.balance;
        paymentProcessor.makePayment{value: amount}();
        
        // Verify payment recorded
        (address payer, uint256 recordedAmount, , bool processed) = 
            paymentProcessor.payments(0);
        
        assertEq(payer, user1);
        assertEq(recordedAmount, amount);
        assertTrue(processed);
        
        // Verify recipient received funds minus fee
        uint256 expectedReceived = amount * 97 / 100;
        assertEq(recipient.balance, recipientBalanceBefore + expectedReceived);
        
        vm.stopPrank();
    }
    
    function testFuzz_ComplexContract_Deposit(uint256 amount) public {
        vm.assume(amount > 0 && amount < 100 ether);
        vm.deal(user1, amount);
        
        vm.startPrank(user1);
        
        complexContract.deposit{value: amount}();
        assertEq(complexContract.balances(user1), amount);
        
        vm.stopPrank();
    }
    
    function testFuzz_ComplexContract_Withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        vm.assume(depositAmount > 0 && depositAmount < 100 ether);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= depositAmount);
        vm.deal(user1, depositAmount);
        
        vm.startPrank(user1);
        
        // Deposit
        complexContract.deposit{value: depositAmount}();
        
        // Withdraw
        uint256 balanceBefore = user1.balance;
        complexContract.withdraw(withdrawAmount);
        
        assertEq(user1.balance, balanceBefore + withdrawAmount);
        assertEq(complexContract.balances(user1), depositAmount - withdrawAmount);
        
        vm.stopPrank();
    }
}