// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {SeiMons} from "../src/SeiMons.sol";
import {ISeiMons} from "../src/interfaces/ISeiMons.sol";

contract SeiMonsGasComparisonTest is Test {
    SeiMons public seimons;
    address public user = address(0x1337);

    function setUp() public {
        seimons = new SeiMons();
        vm.deal(user, 10 ether);
    }

    // Test successful mints to compare gas usage
    function testGasComparison_SuccessfulMint() public {
        uint256 quantity = 2;
        uint256 price = 0.02 ether; // 0.01 ether per token * 2

        // Test mintWithRequire
        vm.prank(user);
        uint256 gasBeforeRequire = gasleft();
        seimons.mintWithRequire{value: price}(quantity);
        uint256 gasUsedRequire = gasBeforeRequire - gasleft();

        // Test mintWithCustomError
        vm.prank(user);
        uint256 gasBeforeCustom = gasleft();
        seimons.mintWithCustomError{value: price}(quantity);
        uint256 gasUsedCustom = gasBeforeCustom - gasleft();

        console.log("=== GAS USAGE COMPARISON (Successful Mint) ===");
        console.log("mintWithRequire gas used:", gasUsedRequire);
        console.log("mintWithCustomError gas used:", gasUsedCustom);
        console.log(
            "Gas saved with custom errors:",
            gasUsedRequire > gasUsedCustom ? gasUsedRequire - gasUsedCustom : 0
        );
    }

    // Test failed mints to see bigger gas savings
    function testGasComparison_FailedMint_InsufficientPayment() public {
        uint256 quantity = 2;
        uint256 insufficientPrice = 0.01 ether; // Only sending half the required amount

        // Test mintWithRequire failure
        vm.prank(user);
        uint256 gasBeforeRequire = gasleft();
        vm.expectRevert("Insufficient payment sent");
        seimons.mintWithRequire{value: insufficientPrice}(quantity);
        uint256 gasUsedRequire = gasBeforeRequire - gasleft();

        // Test mintWithCustomError failure
        vm.prank(user);
        uint256 gasBeforeCustom = gasleft();
        vm.expectRevert(
            abi.encodeWithSelector(
                ISeiMons.InsufficientPayment.selector,
                0.02 ether,
                insufficientPrice
            )
        );
        seimons.mintWithCustomError{value: insufficientPrice}(quantity);
        uint256 gasUsedCustom = gasBeforeCustom - gasleft();

        console.log(
            "\n=== GAS USAGE COMPARISON (Failed Mint - Insufficient Payment) ==="
        );
        console.log("mintWithRequire gas used on revert:", gasUsedRequire);
        console.log("mintWithCustomError gas used on revert:", gasUsedCustom);
        console.log(
            "Gas saved with custom errors on revert:",
            gasUsedRequire - gasUsedCustom
        );
        console.log(
            "Percentage saved:",
            ((gasUsedRequire - gasUsedCustom) * 100) / gasUsedRequire,
            "%"
        );
    }

    function testGasComparison_FailedMint_InvalidQuantity() public {
        uint256 invalidQuantity = 0; // Invalid: zero quantity

        // Test mintWithRequire failure
        vm.prank(user);
        uint256 gasBeforeRequire = gasleft();
        vm.expectRevert("Quantity must be greater than 0");
        seimons.mintWithRequire{value: 0}(invalidQuantity);
        uint256 gasUsedRequire = gasBeforeRequire - gasleft();

        // Test mintWithCustomError failure
        vm.prank(user);
        uint256 gasBeforeCustom = gasleft();
        vm.expectRevert(ISeiMons.InvalidMintQuantity.selector);
        seimons.mintWithCustomError{value: 0}(invalidQuantity);
        uint256 gasUsedCustom = gasBeforeCustom - gasleft();

        console.log(
            "\n=== GAS USAGE COMPARISON (Failed Mint - Invalid Quantity) ==="
        );
        console.log("mintWithRequire gas used on revert:", gasUsedRequire);
        console.log("mintWithCustomError gas used on revert:", gasUsedCustom);
        console.log(
            "Gas saved with custom errors on revert:",
            gasUsedRequire - gasUsedCustom
        );
        console.log(
            "Percentage saved:",
            ((gasUsedRequire - gasUsedCustom) * 100) / gasUsedRequire,
            "%"
        );
    }

    function testGasComparison_FailedMint_ExceedsMaxPerMint() public {
        uint256 tooManyQuantity = 11; // Exceeds MAX_PER_MINT (10)
        uint256 price = 0.11 ether;

        // Test mintWithRequire failure
        vm.prank(user);
        uint256 gasBeforeRequire = gasleft();
        vm.expectRevert("Exceeds maximum per mint");
        seimons.mintWithRequire{value: price}(tooManyQuantity);
        uint256 gasUsedRequire = gasBeforeRequire - gasleft();

        // Test mintWithCustomError failure
        vm.prank(user);
        uint256 gasBeforeCustom = gasleft();
        vm.expectRevert(ISeiMons.InvalidMintQuantity.selector);
        seimons.mintWithCustomError{value: price}(tooManyQuantity);
        uint256 gasUsedCustom = gasBeforeCustom - gasleft();

        console.log(
            "\n=== GAS USAGE COMPARISON (Failed Mint - Exceeds Max Per Mint) ==="
        );
        console.log("mintWithRequire gas used on revert:", gasUsedRequire);
        console.log("mintWithCustomError gas used on revert:", gasUsedCustom);
        console.log(
            "Gas saved with custom errors on revert:",
            gasUsedRequire - gasUsedCustom
        );
        console.log(
            "Percentage saved:",
            ((gasUsedRequire - gasUsedCustom) * 100) / gasUsedRequire,
            "%"
        );
    }
}
