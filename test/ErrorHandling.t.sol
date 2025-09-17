// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/ErrorHandling.sol";

contract ErrorHandlingTest is Test {
    CustomErrorsExample public customErrors;
    RequireExample public requireExample;
    GasComparison public gasComparison;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    function setUp() public {
        customErrors = new CustomErrorsExample();
        requireExample = new RequireExample();
        gasComparison = new GasComparison();
        
        // Fund test accounts
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }
    
    // ==================== CUSTOM ERRORS TESTS ====================
    
    function test_CustomError_DepositTooSmall() public {
        vm.startPrank(user1);
        
        // Expect specific custom error with parameters
        vm.expectRevert(
            abi.encodeWithSelector(
                CustomErrorsExample.DepositTooSmall.selector,
                0.005 ether,
                0.01 ether
            )
        );
        customErrors.deposit{value: 0.005 ether}();
        
        vm.stopPrank();
    }
    
    function test_CustomError_WithdrawExceedsBalance() public {
        vm.startPrank(user1);
        
        // First deposit
        customErrors.deposit{value: 1 ether}();
        
        // Try to withdraw more than balance
        vm.expectRevert(
            abi.encodeWithSelector(
                CustomErrorsExample.WithdrawExceedsBalance.selector,
                2 ether,
                1 ether
            )
        );
        customErrors.withdraw(2 ether);
        
        vm.stopPrank();
    }
    
    function test_CustomError_OnlyOwner() public {
        vm.prank(user1);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                CustomErrorsExample.OnlyOwner.selector,
                user1,
                address(this)
            )
        );
        customErrors.restrictedFunction();
    }
    
    function test_CustomError_ArrayLengthMismatch() public {
        uint256[] memory arr1 = new uint256[](3);
        uint256[] memory arr2 = new uint256[](2);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                CustomErrorsExample.ArrayLengthMismatch.selector,
                3,
                2
            )
        );
        customErrors.processArrays(arr1, arr2);
    }
    
    // ==================== REQUIRE TESTS ====================
    
    function test_Require_DepositTooSmall() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Deposit too small");
        requireExample.deposit{value: 0.005 ether}();
        
        vm.stopPrank();
    }
    
    function test_Require_InsufficientBalance() public {
        vm.startPrank(user1);
        
        // Deposit first
        requireExample.deposit{value: 1 ether}();
        
        // Try to withdraw more
        vm.expectRevert("Insufficient balance");
        requireExample.withdraw(2 ether);
        
        vm.stopPrank();
    }
    
    function test_Require_OnlyOwner() public {
        vm.prank(user1);
        
        vm.expectRevert("Only owner can call");
        requireExample.restrictedFunction();
    }
    
    function test_Require_ComplexValidation() public {
        vm.startPrank(user1);
        requireExample.deposit{value: 1 ether}();
        
        // Test various validation failures
        vm.expectRevert("Value must be positive");
        requireExample.complexValidation(0, address(0x123));
        
        vm.expectRevert("Value too large");
        requireExample.complexValidation(101, address(0x123));
        
        vm.expectRevert("Invalid target");
        requireExample.complexValidation(50, address(0));
        
        vm.expectRevert("Cannot target self");
        requireExample.complexValidation(50, user1);
        
        vm.stopPrank();
    }
    
    // ==================== GAS COMPARISON TESTS ====================
    
    function test_GasComparison_CustomErrorSimple() public {
        uint256 gasStart = gasleft();
        
        try gasComparison.testCustomErrorSimple() {
            fail("Should have reverted");
        } catch {
            // Expected revert
        }
        
        uint256 gasUsed = gasStart - gasleft();
        console.log("Custom error (no params) gas:", gasUsed);
        
        // Custom errors should use less gas
        assertTrue(gasUsed < 500);
    }
    
    function test_GasComparison_RequireShort() public {
        uint256 gasStart = gasleft();
        
        try gasComparison.testRequireShort(0) {
            fail("Should have reverted");
        } catch {
            // Expected revert
        }
        
        uint256 gasUsed = gasStart - gasleft();
        console.log("Require (short message) gas:", gasUsed);
        
        // Require uses more gas than custom errors
        assertTrue(gasUsed > 200);
    }
    
    function test_GasComparison_RequireLong() public {
        uint256 gasStart = gasleft();
        
        try gasComparison.testRequireLong(0) {
            fail("Should have reverted");
        } catch {
            // Expected revert
        }
        
        uint256 gasUsed = gasStart - gasleft();
        console.log("Require (long message) gas:", gasUsed);
        
        // Long messages use even more gas
        assertTrue(gasUsed > 400);
    }
    
    // ==================== FUZZ TESTS ====================
    
    function testFuzz_CustomError_Deposit(uint256 amount) public {
        vm.assume(amount < 100 ether);
        vm.deal(user1, amount);
        vm.startPrank(user1);
        
        if (amount < 0.01 ether) {
            // Should revert with custom error
            vm.expectRevert(
                abi.encodeWithSelector(
                    CustomErrorsExample.DepositTooSmall.selector,
                    amount,
                    0.01 ether
                )
            );
            customErrors.deposit{value: amount}();
        } else {
            // Should succeed
            customErrors.deposit{value: amount}();
            assertEq(customErrors.balances(user1), amount);
        }
        
        vm.stopPrank();
    }
    
    function testFuzz_Require_Deposit(uint256 amount) public {
        vm.assume(amount < 100 ether);
        vm.deal(user1, amount);
        vm.startPrank(user1);
        
        if (amount < 0.01 ether) {
            // Should revert with require message
            vm.expectRevert("Deposit too small");
            requireExample.deposit{value: amount}();
        } else {
            // Should succeed
            requireExample.deposit{value: amount}();
            assertEq(requireExample.balances(user1), amount);
        }
        
        vm.stopPrank();
    }
    
    // ==================== ERROR RECOVERY TESTS ====================
    
    function test_ErrorRecovery_TransferFailure() public {
        // Create contract that rejects ETH
        RejectingContract rejecter = new RejectingContract();
        
        // Fund the rejecter through custom errors contract
        vm.deal(address(customErrors), 1 ether);
        
        // Set balance for rejecter
        vm.store(
            address(customErrors),
            keccak256(abi.encode(address(rejecter), 1)),
            bytes32(uint256(1 ether))
        );
        
        vm.prank(address(rejecter));
        vm.expectRevert(
            abi.encodeWithSelector(
                TransferFailed.selector,
                address(customErrors),
                address(rejecter),
                1 ether
            )
        );
        customErrors.withdraw(1 ether);
    }
}

// Helper contract that rejects ETH
contract RejectingContract {
    // No receive or fallback function - rejects ETH
}