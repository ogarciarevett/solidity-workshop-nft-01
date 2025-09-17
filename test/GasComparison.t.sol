// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {SeiMons} from "../src/SeiMons.sol";

contract GasComparisonTest is Test {
    SeiMons seimons;
    address user = address(0x1234);

    function setUp() public {
        seimons = new SeiMons();
        vm.deal(user, 10 ether);
    }

    // Test successful mints (no revert)
    function testSuccessfulMintGasComparison() public {
        console.log("\n=== SUCCESSFUL MINT GAS COMPARISON ===");

        // Test mintWithRequire - successful
        vm.prank(user);
        uint256 gasStart = gasleft();
        seimons.mintWithRequire{value: 0.0001 ether}(1);
        uint256 gasUsedRequire = gasStart - gasleft();

        // Test mintWithCustomError - successful
        vm.prank(user);
        gasStart = gasleft();
        seimons.mintWithCustomError{value: 0.0001 ether}(1);
        uint256 gasUsedCustom = gasStart - gasleft();

        console.log("Successful Mint - Require:", gasUsedRequire);
        console.log("Successful Mint - Custom:", gasUsedCustom);
        console.log(
            "Difference:",
            int256(gasUsedRequire) - int256(gasUsedCustom)
        );
    }

    // Test reverting on first check (quantity == 0)
    function testRevertEarlyGasComparison() public {
        console.log("\n=== EARLY REVERT GAS COMPARISON (quantity=0) ===");

        uint256 gasRequire = gasleft();
        vm.expectRevert("Invalid quantity");
        vm.prank(user);
        seimons.mintWithRequire{value: 0.0001 ether}(0);
        gasRequire = gasRequire - gasleft();

        uint256 gasCustom = gasleft();
        vm.expectRevert(InvalidMintQuantity.selector);
        vm.prank(user);
        seimons.mintWithCustomError{value: 0.0001 ether}(0);
        gasCustom = gasCustom - gasleft();

        console.log("Early Revert - Require:", gasRequire);
        console.log("Early Revert - Custom:", gasCustom);
        console.log("Gas Saved:", gasRequire - gasCustom);
    }

    // Test reverting on insufficient payment
    function testRevertInsufficientPaymentGasComparison() public {
        console.log("\n=== INSUFFICIENT PAYMENT REVERT GAS COMPARISON ===");

        uint256 gasRequire = gasleft();
        vm.expectRevert("Insufficient payment");
        vm.prank(user);
        seimons.mintWithRequire{value: 0.00001 ether}(5); // Sending too little
        gasRequire = gasRequire - gasleft();

        uint256 gasCustom = gasleft();
        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientPayment.selector,
                0.0005 ether, // required
                0.00001 ether // provided
            )
        );
        vm.prank(user);
        seimons.mintWithCustomError{value: 0.00001 ether}(5);
        gasCustom = gasCustom - gasleft();

        console.log("Payment Revert - Require:", gasRequire);
        console.log("Payment Revert - Custom:", gasCustom);
        console.log("Gas Saved:", gasRequire - gasCustom);
    }

    // Test reverting when quantity exceeds MAX_PER_MINT
    function testRevertMaxPerMintGasComparison() public {
        console.log("\n=== MAX PER MINT REVERT GAS COMPARISON ===");

        // Test with quantity > MAX_PER_MINT (10)
        uint256 gasRequire = gasleft();
        vm.expectRevert("Invalid quantity");
        vm.prank(user);
        seimons.mintWithRequire{value: 0.0011 ether}(11); // 11 exceeds MAX_PER_MINT of 10
        gasRequire = gasRequire - gasleft();

        uint256 gasCustom = gasleft();
        vm.expectRevert(InvalidMintQuantity.selector);
        vm.prank(user);
        seimons.mintWithCustomError{value: 0.0011 ether}(11);
        gasCustom = gasCustom - gasleft();

        console.log("Max Per Mint Revert - Require:", gasRequire);
        console.log("Max Per Mint Revert - Custom:", gasCustom);
        console.log("Gas Saved:", gasRequire - gasCustom);
    }

    // Test deployment cost difference
    function testDeploymentCostComparison() public {
        console.log("\n=== DEPLOYMENT COST COMPARISON ===");
        console.log("Check the forge gas report above for deployment costs");
        console.log("The contract with custom errors should have:");
        console.log("- Smaller deployment size (bytecode)");
        console.log("- Lower deployment cost");
    }
}

// Define custom errors at contract level for testing
error InvalidMintQuantity();
error InsufficientPayment(uint256 required, uint256 provided);
error ExceedsMaxSupply(uint256 requested, uint256 available);
