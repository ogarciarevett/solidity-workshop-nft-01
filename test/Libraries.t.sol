// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/Libraries.sol";

contract LibrariesTest is Test {
    using SafeMath for uint256;
    using ArrayUtils for uint256[];
    using StringUtils for string;
    using AddressUtils for address;
    
    UsingLibraries public usingLib;
    DirectLibraryCalls public directLib;
    UsingStatefulLibrary public statefulLib;
    
    function setUp() public {
        usingLib = new UsingLibraries();
        directLib = new DirectLibraryCalls();
        statefulLib = new UsingStatefulLibrary();
    }
    
    // ==================== SAFEMATH TESTS ====================
    
    function test_SafeMath_Add() public {
        uint256 a = 100;
        uint256 b = 50;
        uint256 result = a.add(b);
        assertEq(result, 150);
    }
    
    function test_SafeMath_Sub() public {
        uint256 a = 100;
        uint256 b = 50;
        uint256 result = a.sub(b);
        assertEq(result, 50);
    }
    
    function test_SafeMath_Mul() public {
        uint256 a = 100;
        uint256 b = 5;
        uint256 result = a.mul(b);
        assertEq(result, 500);
    }
    
    function test_SafeMath_Div() public {
        uint256 a = 100;
        uint256 b = 4;
        uint256 result = a.div(b);
        assertEq(result, 25);
    }
    
    function test_SafeMath_DivByZero() public {
        uint256 a = 100;
        vm.expectRevert("SafeMath: division by zero");
        a.div(0);
    }
    
    // ==================== ARRAY UTILS TESTS ====================
    
    function test_ArrayUtils_Find() public {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 10;
        arr[1] = 20;
        arr[2] = 30;
        
        (bool found, uint256 index) = ArrayUtils.find(arr, 20);
        assertTrue(found);
        assertEq(index, 1);
        
        (found, index) = ArrayUtils.find(arr, 40);
        assertFalse(found);
    }
    
    function test_ArrayUtils_Sum() public {
        uint256[] memory arr = new uint256[](4);
        arr[0] = 10;
        arr[1] = 20;
        arr[2] = 30;
        arr[3] = 40;
        
        uint256 total = ArrayUtils.sum(arr);
        assertEq(total, 100);
    }
    
    function test_ArrayUtils_Max() public {
        uint256[] memory arr = new uint256[](5);
        arr[0] = 50;
        arr[1] = 20;
        arr[2] = 100;
        arr[3] = 30;
        arr[4] = 75;
        
        uint256 maxVal = ArrayUtils.max(arr);
        assertEq(maxVal, 100);
    }
    
    function test_ArrayUtils_RemoveAt() public {
        // Test with contract that uses storage arrays
        usingLib.demonstrateUsing();
        
        // Check initial state
        assertEq(usingLib.numbers(0), 10);
        assertEq(usingLib.numbers(1), 30);  // 20 was removed
    }
    
    // ==================== STRING UTILS TESTS ====================
    
    function test_StringUtils_ToString() public {
        assertEq(StringUtils.toString(0), "0");
        assertEq(StringUtils.toString(123), "123");
        assertEq(StringUtils.toString(999999), "999999");
    }
    
    function test_StringUtils_Equal() public {
        assertTrue(StringUtils.equal("hello", "hello"));
        assertFalse(StringUtils.equal("hello", "world"));
        assertTrue(StringUtils.equal("", ""));
    }
    
    function test_StringUtils_Concat() public {
        string memory result = StringUtils.concat("Hello", " World");
        assertTrue(StringUtils.equal(result, "Hello World"));
    }
    
    function test_StringUtils_Length() public {
        assertEq(StringUtils.length(""), 0);
        assertEq(StringUtils.length("Hello"), 5);
        assertEq(StringUtils.length("Test String"), 11);
    }
    
    // ==================== ADDRESS UTILS TESTS ====================
    
    function test_AddressUtils_IsContract() public {
        // EOA should return false
        assertFalse(AddressUtils.isContract(address(0x123)));
        
        // Contract should return true
        assertTrue(AddressUtils.isContract(address(usingLib)));
        assertTrue(AddressUtils.isContract(address(this)));
    }
    
    function test_AddressUtils_SendValue() public {
        address payable recipient = payable(address(0x456));
        uint256 amount = 1 ether;
        
        // Fund the test contract
        vm.deal(address(this), 10 ether);
        
        uint256 balanceBefore = recipient.balance;
        AddressUtils.sendValue(recipient, amount);
        
        assertEq(recipient.balance, balanceBefore + amount);
    }
    
    // ==================== STATEFUL LIBRARY TESTS ====================
    
    function test_StatefulLibrary_Mint() public {
        address user = address(0x789);
        uint256 amount = 1000;
        
        statefulLib.mint(user, amount);
        assertEq(statefulLib.balanceOf(user), amount);
    }
    
    function test_StatefulLibrary_Burn() public {
        address user = address(0x789);
        
        // First mint
        statefulLib.mint(user, 1000);
        
        // Then burn
        statefulLib.burn(user, 300);
        assertEq(statefulLib.balanceOf(user), 700);
    }
    
    function test_StatefulLibrary_BurnInsufficientBalance() public {
        address user = address(0x789);
        
        statefulLib.mint(user, 100);
        
        vm.expectRevert("Insufficient balance");
        statefulLib.burn(user, 200);
    }
    
    // ==================== FIXED POINT MATH TESTS ====================
    
    function test_FixedPoint_Operations() public {
        FixedPoint.Fixed memory a = FixedPoint.fromUint(10);
        FixedPoint.Fixed memory b = FixedPoint.fromUint(3);
        
        // Addition
        FixedPoint.Fixed memory sum = FixedPoint.add(a, b);
        assertEq(FixedPoint.toUint(sum), 13);
        
        // Multiplication
        FixedPoint.Fixed memory product = FixedPoint.mul(a, b);
        assertEq(FixedPoint.toUint(product), 30);
        
        // Division
        FixedPoint.Fixed memory quotient = FixedPoint.div(a, b);
        assertEq(FixedPoint.toUint(quotient), 3);  // 10/3 = 3.33... truncated to 3
    }
    
    // ==================== CRYPTO LIBRARY TESTS ====================
    
    function test_Crypto_MessageHash() public {
        string memory message = "Hello, World!";
        bytes32 hash = Crypto.getMessageHash(message);
        
        // Hash should be deterministic
        bytes32 expectedHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                "13",  // length of "Hello, World!"
                message
            )
        );
        assertEq(hash, expectedHash);
    }
    
    // ==================== FUZZ TESTS ====================
    
    function testFuzz_SafeMath_Add(uint256 a, uint256 b) public {
        // Skip if overflow would occur
        if (a > type(uint256).max - b) {
            vm.expectRevert("SafeMath: addition overflow");
            a.add(b);
        } else {
            uint256 result = a.add(b);
            assertEq(result, a + b);
        }
    }
    
    function testFuzz_StringUtils_ToString(uint256 value) public {
        string memory str = StringUtils.toString(value);
        
        // Verify the string is not empty (except for 0)
        if (value == 0) {
            assertTrue(StringUtils.equal(str, "0"));
        } else {
            assertTrue(StringUtils.length(str) > 0);
        }
    }
    
    function testFuzz_ArrayUtils_Operations(uint256[] memory arr) public {
        vm.assume(arr.length > 0 && arr.length < 100);
        
        // Test sum
        uint256 sum = ArrayUtils.sum(arr);
        
        // Manually calculate sum for verification
        uint256 expectedSum = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            // Skip if would overflow
            if (expectedSum > type(uint256).max - arr[i]) return;
            expectedSum += arr[i];
        }
        assertEq(sum, expectedSum);
        
        // Test max
        if (arr.length > 0) {
            uint256 max = ArrayUtils.max(arr);
            
            // Verify max is actually the maximum
            for (uint256 i = 0; i < arr.length; i++) {
                assertTrue(max >= arr[i]);
            }
        }
    }
}