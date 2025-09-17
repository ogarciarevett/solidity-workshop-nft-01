// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// ==================== LIBRARY DEFINITIONS ====================

// Basic library for math operations
library SafeMath {
    // Library functions must be internal or private (deployed) or public/external (linked)
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// Library for array operations
library ArrayUtils {
    // Find an element in array
    function find(uint256[] memory arr, uint256 value) internal pure returns (bool, uint256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                return (true, i);
            }
        }
        return (false, 0);
    }
    
    // Remove element at index (storage array)
    function removeAt(uint256[] storage arr, uint256 index) internal {
        require(index < arr.length, "Index out of bounds");
        
        // Move last element to deleted position
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }
    
    // Sum all elements
    function sum(uint256[] memory arr) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            total += arr[i];
        }
        return total;
    }
    
    // Get max element
    function max(uint256[] memory arr) internal pure returns (uint256) {
        require(arr.length > 0, "Empty array");
        uint256 maxVal = arr[0];
        for (uint256 i = 1; i < arr.length; i++) {
            if (arr[i] > maxVal) {
                maxVal = arr[i];
            }
        }
        return maxVal;
    }
}

// Library for address operations
library AddressUtils {
    // Check if address is a contract
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    // Safe transfer ETH
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    // Function call with value
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        require(isContract(target), "Call to non-contract");
        
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        
        if (!success) {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("Function call failed");
            }
        }
        
        return returndata;
    }
}

// Library for string operations
library StringUtils {
    // Convert uint to string
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
    
    // Compare strings
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
    
    // Concatenate strings
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    
    // Get string length
    function length(string memory str) internal pure returns (uint256) {
        return bytes(str).length;
    }
}

// ==================== USING LIBRARIES ====================

// Method 1: Using directive
contract UsingLibraries {
    // Attach library functions to types
    using SafeMath for uint256;
    using ArrayUtils for uint256[];
    using AddressUtils for address;
    using StringUtils for string;
    
    uint256[] public numbers;
    
    function demonstrateUsing() public {
        uint256 a = 100;
        uint256 b = 50;
        
        // Call library functions as if they were methods
        uint256 sum = a.add(b);  // SafeMath.add(a, b)
        uint256 diff = a.sub(b); // SafeMath.sub(a, b)
        uint256 prod = a.mul(2); // SafeMath.mul(a, 2)
        
        // Array operations
        numbers.push(10);
        numbers.push(20);
        numbers.push(30);
        
        (bool found, uint256 index) = numbers.find(20);
        if (found) {
            numbers.removeAt(index);
        }
        
        uint256 total = numbers.sum();
        uint256 maxVal = numbers.max();
    }
    
    function addressOperations() public view {
        address target = msg.sender;
        
        // Check if address is contract
        bool isContr = target.isContract();
        
        // More operations...
    }
    
    function stringOperations() public pure {
        uint256 num = 123;
        string memory numStr = StringUtils.toString(num);
        
        string memory text1 = "Hello";
        string memory text2 = "World";
        string memory combined = text1.concat(text2);
        
        bool areEqual = text1.equal("Hello");
        uint256 len = text1.length();
    }
}

// Method 2: Direct library calls
contract DirectLibraryCalls {
    uint256[] public data;
    
    function demonstrateDirect() public {
        // Call library functions directly
        uint256 result = SafeMath.add(100, 50);
        uint256 product = SafeMath.mul(10, 20);
        
        // Array operations
        data.push(5);
        data.push(10);
        ArrayUtils.removeAt(data, 0);
        
        // String operations
        string memory numStr = StringUtils.toString(42);
        bool equal = StringUtils.equal("test", "test");
    }
}

// ==================== LIBRARY DEPLOYMENT PATTERNS ====================

// Library with external functions (must be deployed separately)
library DeployedLibrary {
    // External functions create separate contract
    function expensiveOperation(uint256[] calldata data) external pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < data.length; i++) {
            result += data[i] * data[i];
        }
        return result;
    }
}

// Library with state variables (not recommended)
library StatefulLibrary {
    // Libraries can have state, but it's stored in the calling contract
    struct State {
        mapping(address => uint256) balances;
        uint256 totalSupply;
    }
    
    function mint(State storage state, address to, uint256 amount) internal {
        state.balances[to] += amount;
        state.totalSupply += amount;
    }
    
    function burn(State storage state, address from, uint256 amount) internal {
        require(state.balances[from] >= amount, "Insufficient balance");
        state.balances[from] -= amount;
        state.totalSupply -= amount;
    }
    
    function balanceOf(State storage state, address account) internal view returns (uint256) {
        return state.balances[account];
    }
}

// Using stateful library
contract UsingStatefulLibrary {
    using StatefulLibrary for StatefulLibrary.State;
    
    StatefulLibrary.State private tokenState;
    
    function mint(address to, uint256 amount) public {
        tokenState.mint(to, amount);
    }
    
    function burn(address from, uint256 amount) public {
        tokenState.burn(from, amount);
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return tokenState.balanceOf(account);
    }
}

// ==================== ADVANCED LIBRARY PATTERNS ====================

// Library for fixed-point math
library FixedPoint {
    uint256 constant SCALE = 1e18;
    
    struct Fixed {
        uint256 value;
    }
    
    function fromUint(uint256 x) internal pure returns (Fixed memory) {
        return Fixed(x * SCALE);
    }
    
    function toUint(Fixed memory x) internal pure returns (uint256) {
        return x.value / SCALE;
    }
    
    function add(Fixed memory a, Fixed memory b) internal pure returns (Fixed memory) {
        return Fixed(a.value + b.value);
    }
    
    function mul(Fixed memory a, Fixed memory b) internal pure returns (Fixed memory) {
        return Fixed((a.value * b.value) / SCALE);
    }
    
    function div(Fixed memory a, Fixed memory b) internal pure returns (Fixed memory) {
        require(b.value > 0, "Division by zero");
        return Fixed((a.value * SCALE) / b.value);
    }
}

// Library for cryptographic operations
library Crypto {
    // Verify signature
    function verifySignature(
        bytes32 messageHash,
        bytes memory signature,
        address expectedSigner
    ) internal pure returns (bool) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        address recovered = ecrecover(messageHash, v, r, s);
        return recovered == expectedSigner;
    }
    
    // Create message hash
    function getMessageHash(string memory message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringUtils.toString(bytes(message).length), message));
    }
}

// ==================== LIBRARY BEST PRACTICES ====================

contract LibraryBestPractices {
    using SafeMath for uint256;
    
    // 1. Use libraries for reusable logic
    // 2. Keep libraries stateless when possible
    // 3. Use 'using' directive for better readability
    // 4. Internal functions are inlined (gas efficient)
    // 5. External functions require deployment (code reuse)
    
    function examples() public pure {
        // Good: Reusable math operations
        uint256 result = uint256(100).add(50);
        
        // Good: Complex operations abstracted
        string memory str = StringUtils.toString(12345);
        
        // Libraries can't have state variables
        // Libraries can't inherit or be inherited
        // Libraries can't receive Ether
        // Libraries can't be destroyed
    }
    
    // 6. Libraries are great for:
    // - Math operations
    // - Array/String manipulation  
    // - Encoding/Decoding
    // - Validation logic
    // - Cryptographic operations
}