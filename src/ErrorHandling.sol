// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// ==================== CUSTOM ERRORS (Solidity 0.8.4+) ====================

// Define custom errors at file level
error Unauthorized(address caller);
error InsufficientBalance(uint256 available, uint256 required);
error InvalidInput(string reason);
error TransferFailed(address from, address to, uint256 amount);
error DeadlineExceeded(uint256 deadline, uint256 currentTime);
error InvalidState(string expected, string actual);

contract CustomErrorsExample {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public constant MIN_DEPOSIT = 0.01 ether;
    
    // Custom errors specific to this contract
    error DepositTooSmall(uint256 sent, uint256 minimum);
    error WithdrawExceedsBalance(uint256 requested, uint256 available);
    error OnlyOwner(address caller, address owner);
    error ZeroAddress();
    error ArrayLengthMismatch(uint256 length1, uint256 length2);
    
    constructor() {
        owner = msg.sender;
    }
    
    // Using custom errors instead of require strings
    function deposit() public payable {
        // Custom error with parameters
        if (msg.value < MIN_DEPOSIT) {
            revert DepositTooSmall(msg.value, MIN_DEPOSIT);
        }
        
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 amount) public {
        uint256 balance = balances[msg.sender];
        
        // Custom error provides more context
        if (amount > balance) {
            revert WithdrawExceedsBalance(amount, balance);
        }
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            revert TransferFailed(address(this), msg.sender, amount);
        }
    }
    
    function restrictedFunction() public view {
        if (msg.sender != owner) {
            revert OnlyOwner(msg.sender, owner);
        }
        // Function logic...
    }
    
    function processArrays(uint256[] memory arr1, uint256[] memory arr2) public pure {
        if (arr1.length != arr2.length) {
            revert ArrayLengthMismatch(arr1.length, arr2.length);
        }
        // Process arrays...
    }
    
    function transferOwnership(address newOwner) public {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }
        
        owner = newOwner;
    }
}

// ==================== REQUIRE STATEMENTS ====================

contract RequireExample {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public constant MIN_DEPOSIT = 0.01 ether;
    
    constructor() {
        owner = msg.sender;
    }
    
    // Using require with error messages
    function deposit() public payable {
        require(msg.value >= MIN_DEPOSIT, "Deposit too small");
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    function restrictedFunction() public view {
        require(msg.sender == owner, "Only owner can call");
        // Function logic...
    }
    
    function processArrays(uint256[] memory arr1, uint256[] memory arr2) public pure {
        require(arr1.length == arr2.length, "Array length mismatch");
        // Process arrays...
    }
    
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Unauthorized");
        require(newOwner != address(0), "Zero address not allowed");
        
        owner = newOwner;
    }
    
    // Multiple require statements
    function complexValidation(uint256 value, address target) public view {
        require(value > 0, "Value must be positive");
        require(value <= 100, "Value too large");
        require(target != address(0), "Invalid target");
        require(target != msg.sender, "Cannot target self");
        require(balances[msg.sender] >= value, "Insufficient funds");
    }
}

// ==================== GAS COMPARISON ====================

contract GasComparison {
    // Custom errors for gas comparison
    error CustomError1();
    error CustomError2(uint256 value);
    error CustomError3(address user, uint256 value, string reason);
    
    // Gas test: Custom error (no parameters)
    function testCustomErrorSimple() public pure {
        revert CustomError1();
        // Gas: ~164 gas
    }
    
    // Gas test: Custom error (with parameters)
    function testCustomErrorWithParams(uint256 value) public pure {
        revert CustomError2(value);
        // Gas: ~268 gas
    }
    
    // Gas test: Custom error (multiple parameters)
    function testCustomErrorComplex(address user, uint256 value) public pure {
        revert CustomError3(user, value, "Complex error");
        // Gas: ~500+ gas (depends on string length)
    }
    
    // Gas test: Require with short message
    function testRequireShort(uint256 value) public pure {
        require(value > 0, "Invalid");
        // Gas: ~280 gas
    }
    
    // Gas test: Require with medium message
    function testRequireMedium(uint256 value) public pure {
        require(value > 0, "Value must be greater than zero");
        // Gas: ~340 gas
    }
    
    // Gas test: Require with long message
    function testRequireLong(uint256 value) public pure {
        require(value > 0, "The provided value must be greater than zero to proceed with this operation");
        // Gas: ~440+ gas
    }
    
    // Demonstration: Custom errors save gas
    function efficientValidation(uint256 amount, address recipient) public pure {
        // More gas efficient with custom errors
        if (amount == 0) revert CustomError1();
        if (recipient == address(0)) revert CustomError2(0);
        
        // vs require statements (more gas)
        // require(amount > 0, "Amount must be greater than zero");
        // require(recipient != address(0), "Recipient cannot be zero address");
    }
}

// ==================== ERROR HANDLING PATTERNS ====================

contract ErrorHandlingPatterns {
    // Custom errors for different scenarios
    error NotInitialized();
    error AlreadyInitialized();
    error Paused();
    error InvalidSignature(bytes signature);
    error Expired(uint256 expiry);
    error Blacklisted(address account);
    
    bool public initialized;
    bool public paused;
    mapping(address => bool) public blacklist;
    
    // Modifiers with custom errors
    modifier onlyInitialized() {
        if (!initialized) revert NotInitialized();
        _;
    }
    
    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }
    
    modifier notBlacklisted(address account) {
        if (blacklist[account]) revert Blacklisted(account);
        _;
    }
    
    // Try-catch with custom errors
    function tryCatchExample(address target) public returns (bool) {
        try IExternalContract(target).riskyOperation() {
            return true;
        } catch Error(string memory reason) {
            // Handle require/revert with string
            if (keccak256(bytes(reason)) == keccak256(bytes("Specific error"))) {
                // Handle specific error
            }
            return false;
        } catch (bytes memory lowLevelData) {
            // Handle custom errors and low-level failures
            // Custom errors are encoded as bytes
            if (lowLevelData.length >= 4) {
                bytes4 selector = bytes4(lowLevelData);
                if (selector == InsufficientBalance.selector) {
                    // Handle InsufficientBalance error
                }
            }
            return false;
        }
    }
    
    // Assert vs Require vs Revert
    function assertRequireRevert(uint256 value) public pure {
        // Use require for input validation
        require(value > 0, "Value must be positive");
        
        // Use custom errors for better gas efficiency and clarity
        if (value > 100) {
            revert InvalidInput("Value too large");
        }
        
        // Use assert for invariants (should never fail in production)
        uint256 result = value * 2;
        assert(result >= value);  // Overflow check (though automatic in 0.8+)
        
        // Plain revert for unreachable code
        if (value == 50) {
            revert();  // No error data
        }
    }
}

// ==================== BEST PRACTICES COMPARISON ====================

contract BestPractices {
    // ============ Custom Errors Approach (Recommended) ============
    
    // Define errors at contract/file level
    error InsufficientFunds(uint256 requested, uint256 available);
    error NotAuthorized(address caller, bytes32 role);
    error InvalidParameter(string paramName, uint256 value);
    
    mapping(address => uint256) private balances;
    mapping(address => bytes32) private roles;
    
    function customErrorApproach(uint256 amount) public {
        // ✅ Gas efficient
        // ✅ Strongly typed parameters
        // ✅ Better for debugging
        // ✅ Can be caught specifically
        
        if (amount > balances[msg.sender]) {
            revert InsufficientFunds(amount, balances[msg.sender]);
        }
        
        if (roles[msg.sender] != keccak256("ADMIN")) {
            revert NotAuthorized(msg.sender, keccak256("ADMIN"));
        }
        
        if (amount == 0 || amount > 1000) {
            revert InvalidParameter("amount", amount);
        }
    }
    
    // ============ Require Approach (Traditional) ============
    
    function requireApproach(uint256 amount) public view {
        // ❌ Less gas efficient
        // ✅ Simple and readable
        // ✅ Widely understood
        // ❌ String storage costs
        
        require(
            amount <= balances[msg.sender],
            "Insufficient funds for withdrawal"
        );
        
        require(
            roles[msg.sender] == keccak256("ADMIN"),
            "Caller is not authorized"
        );
        
        require(
            amount > 0 && amount <= 1000,
            "Invalid amount parameter"
        );
    }
    
    // ============ Hybrid Approach ============
    
    function hybridApproach(uint256 amount) public view {
        // Use require for simple checks
        require(amount > 0, "Amount must be positive");
        
        // Use custom errors for complex scenarios
        if (amount > balances[msg.sender]) {
            revert InsufficientFunds(amount, balances[msg.sender]);
        }
        
        // Use assert for invariants
        uint256 newBalance = balances[msg.sender] - amount;
        assert(newBalance <= balances[msg.sender]);  // Underflow check
    }
}

// ==================== INTERFACE FOR EXTERNAL CONTRACT ====================

interface IExternalContract {
    function riskyOperation() external;
}

// ==================== SUMMARY TABLE IN CODE ====================

contract ErrorHandlingSummary {
    function comparison() public pure returns (string memory) {
        return string(abi.encodePacked(
            "Custom Errors vs Require:\n",
            "=====================================\n",
            "| Aspect        | Custom Error | Require |\n",
            "| Gas Cost      | Lower (~164) | Higher (~280+) |\n",
            "| Parameters    | Typed        | String only |\n",
            "| Debugging     | Better       | Good |\n",
            "| Readability   | Good         | Better |\n",  
            "| Adoption      | Newer        | Universal |\n",
            "| Error Data    | Structured   | String |\n",
            "=====================================\n",
            "Recommendation: Use custom errors for production contracts"
        ));
    }
}