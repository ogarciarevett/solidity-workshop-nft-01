// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract BytesVulnerabilities {
    // State variables for demonstration
    uint256[] public array;
    uint256 public importantValue = 1000;
    bytes public userData;
    mapping(bytes32 => bool) public usedIds;
    
    // Events
    event VulnerabilityDemonstrated(string vulnerabilityType, bytes data);
    
    // ==================== VULNERABLE EXAMPLES ====================
    
    // 1. Memory Corruption - No bounds checking
    function vulnerableMemoryRead(bytes memory data, uint256 index) 
        public 
        pure 
        returns (bytes32) 
    {
        // VULNERABLE: No bounds checking!
        bytes32 result;
        assembly {
            // This can read past the bounds of 'data'
            result := mload(add(add(data, 0x20), index))
        }
        return result;
    }
    
    // 2. ABI Decoding vulnerability
    function vulnerableAbiDecode(bytes calldata data) 
        external 
        pure 
        returns (uint256, string memory) 
    {
        // VULNERABLE: No validation of data format
        // Fuzzer can send malformed data causing unexpected behavior
        return abi.decode(data, (uint256, string));
    }
    
    // 3. Calldata slice vulnerability
    function vulnerableCalldataSlice(bytes calldata data) 
        external 
        pure 
        returns (bytes32) 
    {
        // VULNERABLE: Assumes data has at least 32 bytes
        // Will revert if data.length < 32
        return bytes32(data[0:32]);
    }
    
    // 4. Gas griefing with dynamic bytes
    function vulnerableGasGriefing(bytes memory data) 
        public 
        returns (bytes memory) 
    {
        // VULNERABLE: Attacker can send huge bytes array
        userData = data;  // Expensive storage write
        
        // Multiple expensive operations
        bytes memory copied = data;  // Memory copy
        bytes memory doubled = abi.encodePacked(data, data);  // Another copy
        
        return doubled;
    }
    
    // 5. Hash collision with encodePacked
    function vulnerableHashCollision(
        address user1, 
        bytes calldata data1,
        address user2,
        bytes calldata data2
    ) external pure returns (bool) {
        // VULNERABLE: Hash collision possible
        // encodePacked(addr1, data1) could equal encodePacked(addr2, data2)
        // if data boundaries are crafted maliciously
        bytes32 hash1 = keccak256(abi.encodePacked(user1, data1));
        bytes32 hash2 = keccak256(abi.encodePacked(user2, data2));
        
        return hash1 == hash2;
    }
    
    // 6. Integer overflow in array access (pre-0.8.0 style, but showing the concept)
    function vulnerableArrayAccess(bytes memory data, uint256 offset) 
        public 
        pure 
        returns (bytes1) 
    {
        // VULNERABLE: offset could be larger than data.length
        // In older Solidity versions, this could wrap around
        unchecked {
            // Simulating pre-0.8.0 behavior
            return data[offset % data.length];  // Still vulnerable to division by zero
        }
    }
    
    // ==================== SAFE EXAMPLES ====================
    
    // 1. Safe memory read with bounds checking
    function safeMemoryRead(bytes memory data, uint256 index) 
        public 
        pure 
        returns (bytes32) 
    {
        // SAFE: Check bounds before reading
        require(index + 32 <= data.length, "Index out of bounds");
        
        bytes32 result;
        assembly {
            result := mload(add(add(data, 0x20), index))
        }
        return result;
    }
    
    // 2. Safe ABI decoding with validation
    function safeAbiDecode(bytes calldata data) 
        external 
        pure 
        returns (uint256, string memory) 
    {
        // SAFE: Validate minimum data length
        require(data.length >= 64, "Invalid data length");  // At least offset and length
        
        // Use try-catch for safe decoding (requires external call pattern)
        (uint256 num, string memory str) = abi.decode(data, (uint256, string));
        
        // Additional validation
        require(bytes(str).length > 0, "Empty string");
        require(bytes(str).length < 1000, "String too long");  // Prevent gas griefing
        
        return (num, str);
    }
    
    // 3. Safe calldata slice
    function safeCalldataSlice(bytes calldata data) 
        external 
        pure 
        returns (bytes32) 
    {
        // SAFE: Check length before slicing
        require(data.length >= 32, "Insufficient data");
        return bytes32(data[0:32]);
    }
    
    // 4. Safe gas-conscious operations
    function safeGasConscious(bytes calldata data) 
        external 
        pure 
        returns (bytes32) 
    {
        // SAFE: Limit input size
        require(data.length <= 1024, "Data too large");
        
        // Process without expensive operations
        if (data.length >= 32) {
            return bytes32(data[0:32]);
        } else {
            // Handle short data safely
            bytes32 result;
            for (uint i = 0; i < data.length; i++) {
                result |= bytes32(data[i]) >> (i * 8);
            }
            return result;
        }
    }
    
    // 5. Safe hashing without collision
    function safeHashing(
        address user1, 
        bytes calldata data1,
        address user2,
        bytes calldata data2
    ) external pure returns (bool) {
        // SAFE: Use abi.encode (not encodePacked) to prevent collision
        bytes32 hash1 = keccak256(abi.encode(user1, data1));
        bytes32 hash2 = keccak256(abi.encode(user2, data2));
        
        return hash1 == hash2;
    }
    
    // ==================== FUZZING TEST PATTERNS ====================
    
    // Pattern detection for fuzzers
    struct FuzzingPattern {
        bytes data;
        uint256 offset;
        uint256 length;
    }
    
    // Function that demonstrates what fuzzers typically find
    function fuzzingTargets(FuzzingPattern memory pattern) public pure {
        // Fuzzer will test with:
        // 1. Empty data (pattern.data.length == 0)
        if (pattern.data.length == 0) {
            // Should handle gracefully
            return;
        }
        
        // 2. Maximum size (pattern.data.length == type(uint256).max)
        // Would cause out-of-gas
        
        // 3. Odd lengths (non-multiple of 32)
        bool isAligned = pattern.data.length % 32 == 0;
        
        // 4. Crafted offsets for out-of-bounds
        if (pattern.offset >= pattern.data.length) {
            // Should revert safely
            return;
        }
        
        // 5. Repeated patterns (0xFFFF... or 0x0000...)
        // Check for suspicious patterns
        if (pattern.data.length > 0) {
            bool allSame = true;
            bytes1 first = pattern.data[0];
            for (uint i = 1; i < pattern.data.length && i < 100; i++) {
                if (pattern.data[i] != first) {
                    allSame = false;
                    break;
                }
            }
            // Handle suspicious uniform data
        }
    }
    
    // ==================== HISTORICAL VULNERABILITIES ====================
    
    // Demonstration of historical vulnerability (no longer works in 0.8.x)
    function historicalVulnerability() public view returns (string memory) {
        // In Solidity < 0.6.0, you could manipulate array.length:
        // array.length = uint256(-1);  // Set to max value
        // array[calculateStorageSlot()] = attackValue;  // Write to arbitrary storage
        
        // This would have allowed overwriting importantValue or any storage variable!
        // Modern Solidity prevents this with:
        // - No direct array.length manipulation
        // - Automatic overflow checks in 0.8.x
        
        return "This vulnerability was patched in Solidity 0.6.0";
    }
    
    // ==================== RECOMMENDATIONS ====================
    
    function recommendations() public pure returns (string memory) {
        return string.concat(
            "1. Always validate input lengths\n",
            "2. Use abi.encode instead of abi.encodePacked for hashing\n",
            "3. Implement size limits for dynamic data\n",
            "4. Use require() for bounds checking\n",
            "5. Test with fuzzing tools (Foundry, Echidna)\n",
            "6. Be careful with assembly and manual memory management"
        );
    }
}