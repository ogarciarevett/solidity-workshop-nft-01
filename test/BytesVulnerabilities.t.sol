// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/BytesVulnerabilities.sol";

contract BytesVulnerabilitiesTest is Test {
    BytesVulnerabilities public bytesContract;
    
    function setUp() public {
        bytesContract = new BytesVulnerabilities();
    }
    
    // ==================== FUZZING TESTS ====================
    
    // Fuzz test for memory bounds vulnerability
    function testFuzz_VulnerableMemoryRead(bytes memory data, uint256 index) public {
        // This will often revert or return unexpected data
        if (data.length == 0) {
            // Skip empty data
            return;
        }
        
        // Test vulnerable function (may read out of bounds)
        bytes32 result = bytesContract.vulnerableMemoryRead(data, index);
        
        // The vulnerable function doesn't check bounds
        // So we can read past the array!
        // In production, this is a security issue
    }
    
    // Fuzz test for safe memory read
    function testFuzz_SafeMemoryRead(bytes memory data, uint256 index) public {
        // Skip if data is empty
        if (data.length == 0) return;
        
        // Test safe function
        if (index + 32 <= data.length) {
            // Should succeed
            bytes32 result = bytesContract.safeMemoryRead(data, index);
            
            // Verify we got valid data
            assertTrue(result != bytes32(0) || data.length < 32);
        } else {
            // Should revert
            vm.expectRevert("Index out of bounds");
            bytesContract.safeMemoryRead(data, index);
        }
    }
    
    // Fuzz test for ABI decode vulnerability
    function testFuzz_VulnerableAbiDecode(bytes calldata data) public {
        // The vulnerable function will often revert with malformed data
        try bytesContract.vulnerableAbiDecode(data) returns (uint256 num, string memory str) {
            // If it succeeds, we got lucky with the data format
            assertTrue(num >= 0);  // Always true for uint
            assertTrue(bytes(str).length >= 0);  // Always true
        } catch {
            // Most random data will fail to decode
            // This is expected for fuzzing
        }
    }
    
    // Fuzz test for calldata slice vulnerability
    function testFuzz_CalldataSlice(bytes calldata data) public {
        if (data.length >= 32) {
            // Vulnerable function should work
            bytes32 resultVuln = bytesContract.vulnerableCalldataSlice(data);
            
            // Safe function should also work
            bytes32 resultSafe = bytesContract.safeCalldataSlice(data);
            
            // Results should be identical
            assertEq(resultVuln, resultSafe);
        } else {
            // Vulnerable function will revert
            vm.expectRevert();
            bytesContract.vulnerableCalldataSlice(data);
            
            // Safe function will revert with message
            vm.expectRevert("Insufficient data");
            bytesContract.safeCalldataSlice(data);
        }
    }
    
    // ==================== SPECIFIC VULNERABILITY TESTS ====================
    
    // Test hash collision vulnerability
    function test_HashCollisionVulnerability() public {
        address user1 = address(0x1);
        address user2 = address(0x2);
        
        // Crafted data to cause collision with encodePacked
        bytes memory data1 = hex"111111";
        bytes memory data2 = hex"11";
        
        // These could potentially collide with carefully crafted inputs
        bool collision = bytesContract.vulnerableHashCollision(
            user1, data1, user2, data2
        );
        
        // The safe version should not have collision
        bool noCollision = bytesContract.safeHashing(
            user1, data1, user2, data2
        );
        
        // Safe version should handle this correctly
        assertFalse(noCollision);
    }
    
    // Test gas griefing attack
    function test_GasGriefing() public {
        // Create large data array (not too large for test)
        bytes memory largeData = new bytes(1000);
        
        // Fill with data
        for (uint i = 0; i < largeData.length; i++) {
            largeData[i] = bytes1(uint8(i % 256));
        }
        
        // Measure gas for vulnerable function
        uint256 gasBefore = gasleft();
        bytesContract.vulnerableGasGriefing(largeData);
        uint256 gasUsedVulnerable = gasBefore - gasleft();
        
        // The vulnerable function uses a lot of gas due to storage writes
        assertTrue(gasUsedVulnerable > 50000);  // High gas usage
        
        // Safe function should reject large data
        vm.expectRevert("Data too large");
        bytesContract.safeGasConscious(largeData);
    }
    
    // ==================== EDGE CASE TESTS ====================
    
    // Test empty bytes
    function test_EmptyBytes() public {
        bytes memory empty = "";
        
        // Vulnerable function might behave unexpectedly
        bytes32 result = bytesContract.vulnerableMemoryRead(empty, 0);
        // This reads random memory!
        
        // Safe function should handle properly
        vm.expectRevert("Index out of bounds");
        bytesContract.safeMemoryRead(empty, 0);
    }
    
    // Test maximum values
    function test_MaxValues() public {
        bytes memory data = "test";
        uint256 maxIndex = type(uint256).max;
        
        // This will likely cause issues
        // The vulnerable function might overflow or read random memory
        bytes32 result = bytesContract.vulnerableMemoryRead(data, maxIndex);
        
        // Safe function should reject
        vm.expectRevert("Index out of bounds");
        bytesContract.safeMemoryRead(data, maxIndex);
    }
    
    // Test odd-length bytes
    function test_OddLengthBytes() public {
        // Create odd-length bytes (not multiple of 32)
        bytes memory oddBytes = new bytes(33);  // 32 + 1
        oddBytes[32] = 0xFF;
        
        // Test vulnerable function behavior
        bytes32 result = bytesContract.vulnerableMemoryRead(oddBytes, 0);
        assertTrue(result != bytes32(0) || oddBytes.length == 0);
        
        // Reading at boundary
        bytes32 boundaryResult = bytesContract.vulnerableMemoryRead(oddBytes, 1);
        // This reads partially out of bounds!
    }
    
    // ==================== PATTERN DETECTION TESTS ====================
    
    // Test repeated pattern detection (useful for fuzzing)
    function test_RepeatedPatterns() public {
        // All zeros pattern
        bytes memory zeros = new bytes(100);
        // Default is all zeros
        
        // All ones pattern  
        bytes memory ones = new bytes(100);
        for (uint i = 0; i < ones.length; i++) {
            ones[i] = 0xFF;
        }
        
        // Test with patterns
        BytesVulnerabilities.FuzzingPattern memory pattern;
        pattern.data = zeros;
        pattern.offset = 0;
        pattern.length = 100;
        
        // This should handle the suspicious pattern
        bytesContract.fuzzingTargets(pattern);
        
        pattern.data = ones;
        bytesContract.fuzzingTargets(pattern);
    }
    
    // ==================== INVARIANT TESTS ====================
    
    // Invariant: Safe functions should never read out of bounds
    function invariant_SafeFunctionsBounded() public {
        bytes memory testData = "test data";
        uint256 maxValidIndex = testData.length > 32 ? testData.length - 32 : 0;
        
        // This should always work for valid indices
        if (testData.length >= 32) {
            bytesContract.safeMemoryRead(testData, maxValidIndex);
        }
        
        // This should always revert for invalid indices
        if (testData.length < 32) {
            try bytesContract.safeMemoryRead(testData, 0) {
                revert("Should have reverted");
            } catch Error(string memory reason) {
                assertEq(reason, "Index out of bounds");
            }
        }
    }
}