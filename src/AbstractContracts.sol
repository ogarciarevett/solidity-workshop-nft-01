// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// ==================== ABSTRACT CONTRACT DEFINITIONS ====================

// Basic abstract contract
abstract contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    // Concrete function (has implementation)
    function owner() public view returns (address) {
        return _owner;
    }
    
    // Concrete modifier
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }
    
    // Abstract function (no implementation, must be virtual)
    function _authorizeUpgrade() internal view virtual;
    
    // Concrete function that uses abstract function
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        _authorizeUpgrade();  // Call abstract function
        
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    // Virtual function (has implementation but can be overridden)
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// Abstract contract with multiple abstract functions
abstract contract PaymentProcessor {
    uint256 public constant FEE_PERCENTAGE = 3;  // 3%
    
    struct Payment {
        address payer;
        uint256 amount;
        uint256 timestamp;
        bool processed;
    }
    
    mapping(uint256 => Payment) public payments;
    uint256 public paymentCounter;
    
    event PaymentReceived(uint256 indexed paymentId, address indexed payer, uint256 amount);
    event PaymentProcessed(uint256 indexed paymentId);
    
    // Abstract functions that child contracts must implement
    function validatePayment(address payer, uint256 amount) internal view virtual returns (bool);
    function processPaymentLogic(uint256 paymentId) internal virtual;
    function getRecipient() internal view virtual returns (address);
    
    // Concrete function using abstract functions
    function makePayment() public payable {
        require(msg.value > 0, "Payment required");
        require(validatePayment(msg.sender, msg.value), "Invalid payment");
        
        uint256 paymentId = paymentCounter++;
        payments[paymentId] = Payment({
            payer: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            processed: false
        });
        
        emit PaymentReceived(paymentId, msg.sender, msg.value);
        
        // Automatically process
        _processPayment(paymentId);
    }
    
    // Internal concrete function
    function _processPayment(uint256 paymentId) internal {
        Payment storage payment = payments[paymentId];
        require(!payment.processed, "Already processed");
        
        payment.processed = true;
        
        // Calculate fee
        uint256 fee = (payment.amount * FEE_PERCENTAGE) / 100;
        uint256 netAmount = payment.amount - fee;
        
        // Use abstract function to get recipient
        address recipient = getRecipient();
        
        // Transfer funds
        payable(recipient).transfer(netAmount);
        
        // Call abstract processing logic
        processPaymentLogic(paymentId);
        
        emit PaymentProcessed(paymentId);
    }
}

// ==================== IMPLEMENTING ABSTRACT CONTRACTS ====================

// Concrete implementation of Ownable
contract OwnedContract is Ownable {
    uint256 public value;
    
    // Must implement abstract function
    function _authorizeUpgrade() internal pure override {
        // Simple implementation - could add complex logic
        // For example, could check time locks, multi-sig, etc.
    }
    
    // Can override virtual function
    function renounceOwnership() public override onlyOwner {
        // Add custom logic before calling parent
        require(value == 0, "Cannot renounce with non-zero value");
        super.renounceOwnership();
    }
    
    function setValue(uint256 _value) public onlyOwner {
        value = _value;
    }
}

// Concrete implementation of PaymentProcessor
contract SimplePaymentProcessor is PaymentProcessor {
    address private recipient;
    uint256 public minPayment = 0.01 ether;
    uint256 public maxPayment = 10 ether;
    
    constructor(address _recipient) {
        recipient = _recipient;
    }
    
    // Implement abstract functions
    function validatePayment(address payer, uint256 amount) 
        internal 
        view 
        override 
        returns (bool) 
    {
        // Custom validation logic
        return amount >= minPayment && amount <= maxPayment && payer != address(0);
    }
    
    function processPaymentLogic(uint256 paymentId) internal override {
        // Custom processing logic
        Payment memory payment = payments[paymentId];
        
        // Could add additional logic here:
        // - Update user points/rewards
        // - Send notifications
        // - Update statistics
    }
    
    function getRecipient() internal view override returns (address) {
        return recipient;
    }
    
    // Additional functions specific to this implementation
    function updateLimits(uint256 _min, uint256 _max) public {
        require(_min < _max, "Invalid limits");
        minPayment = _min;
        maxPayment = _max;
    }
}

// ==================== MULTIPLE INHERITANCE WITH ABSTRACT CONTRACTS ====================

// First abstract contract
abstract contract Pausable {
    bool private _paused;
    
    event Paused(address account);
    event Unpaused(address account);
    
    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }
    
    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }
    
    function paused() public view returns (bool) {
        return _paused;
    }
    
    // Abstract function for authorization
    function _canPause() internal view virtual returns (bool);
    
    function pause() public {
        require(_canPause(), "Not authorized to pause");
        require(!_paused, "Already paused");
        _paused = true;
        emit Paused(msg.sender);
    }
    
    function unpause() public {
        require(_canPause(), "Not authorized to unpause");
        require(_paused, "Not paused");
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// Second abstract contract  
abstract contract RateLimited {
    mapping(address => uint256) private lastAction;
    uint256 public constant RATE_LIMIT = 1 minutes;
    
    modifier rateLimited() {
        require(
            block.timestamp >= lastAction[msg.sender] + RATE_LIMIT,
            "Rate limit exceeded"
        );
        lastAction[msg.sender] = block.timestamp;
        _;
    }
    
    // Abstract function to determine if rate limit applies
    function _isRateLimitExempt(address user) internal view virtual returns (bool);
    
    function checkRateLimit(address user) public view returns (bool) {
        if (_isRateLimitExempt(user)) return true;
        return block.timestamp >= lastAction[user] + RATE_LIMIT;
    }
}

// Concrete contract inheriting multiple abstract contracts
contract ComplexContract is Ownable, Pausable, RateLimited {
    mapping(address => uint256) public balances;
    
    // Implement all abstract functions
    function _authorizeUpgrade() internal view override {
        // Only owner can upgrade
        require(msg.sender == owner(), "Not authorized");
    }
    
    function _canPause() internal view override returns (bool) {
        // Only owner can pause
        return msg.sender == owner();
    }
    
    function _isRateLimitExempt(address user) internal view override returns (bool) {
        // Owner is exempt from rate limits
        return user == owner();
    }
    
    // Contract functionality using inherited features
    function deposit() public payable whenNotPaused rateLimited {
        require(msg.value > 0, "No value sent");
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 amount) public whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}

// ==================== ADVANCED ABSTRACT PATTERNS ====================

// Template method pattern
abstract contract TokenSale {
    uint256 public totalSold;
    uint256 public saleEndTime;
    
    constructor(uint256 duration) {
        saleEndTime = block.timestamp + duration;
    }
    
    // Template method defining the algorithm
    function buyTokens(uint256 amount) public payable {
        // Step 1: Validate (abstract)
        require(validatePurchase(msg.sender, amount, msg.value), "Invalid purchase");
        
        // Step 2: Check sale is active (concrete)
        require(block.timestamp < saleEndTime, "Sale ended");
        
        // Step 3: Process payment (abstract)
        processPayment(msg.sender, msg.value);
        
        // Step 4: Deliver tokens (abstract)  
        deliverTokens(msg.sender, amount);
        
        // Step 5: Update state (concrete)
        totalSold += amount;
        
        // Step 6: Post-purchase hook (virtual)
        afterPurchase(msg.sender, amount);
    }
    
    // Abstract methods that subclasses must implement
    function validatePurchase(address buyer, uint256 amount, uint256 value) 
        internal view virtual returns (bool);
    function processPayment(address buyer, uint256 value) internal virtual;
    function deliverTokens(address buyer, uint256 amount) internal virtual;
    
    // Virtual method with default implementation
    function afterPurchase(address buyer, uint256 amount) internal virtual {
        // Default: do nothing
        // Subclasses can override to add functionality
    }
}

// Factory pattern with abstract contracts
abstract contract Factory {
    address[] public deployedContracts;
    
    event ContractDeployed(address indexed contractAddress, address indexed deployer);
    
    // Abstract function for contract creation
    function createContract(bytes memory data) internal virtual returns (address);
    
    // Abstract function for initialization
    function initializeContract(address contractAddress, bytes memory data) internal virtual;
    
    // Concrete function using abstract functions
    function deployContract(bytes memory creationData, bytes memory initData) public returns (address) {
        // Create contract
        address newContract = createContract(creationData);
        require(newContract != address(0), "Deployment failed");
        
        // Initialize
        initializeContract(newContract, initData);
        
        // Track
        deployedContracts.push(newContract);
        emit ContractDeployed(newContract, msg.sender);
        
        return newContract;
    }
    
    function getDeployedCount() public view returns (uint256) {
        return deployedContracts.length;
    }
}

// ==================== BEST PRACTICES ====================

contract AbstractContractBestPractices {
    // 1. Use abstract contracts for shared functionality
    // 2. Define clear interfaces through abstract functions
    // 3. Use virtual for functions that might be overridden
    // 4. Always use override keyword when implementing
    // 5. Consider the order of inheritance (linearization)
    
    // Good pattern: Separating concerns
    // - Abstract contracts for business logic templates
    // - Interfaces for external contracts
    // - Libraries for pure utility functions
    
    // Common use cases for abstract contracts:
    // - Access control (Ownable, Role-based)
    // - Pausable functionality
    // - Upgradeable patterns
    // - Payment processing
    // - Token standards base implementations
}