// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC721A} from "./ERC721A.sol";
import {ISeiMons} from "./interfaces/ISeiMons.sol";

contract SeiMons is ISeiMons, ERC721A, ReentrancyGuard {
    // Types are inherited from ISeiMons interface

    // Constants for minting
    uint256 public constant PRICE_PER_TOKEN = 0.0001 ether;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_MINT = 10;

    mapping(uint256 => Monster) public monsters;

    // Name prefixes and suffixes for generation
    string[] private prefixes = [
        "Flame",
        "Aqua",
        "Leaf",
        "Volt",
        "Mind",
        "Shadow",
        "Drake",
        "Wild"
    ];
    string[] private suffixes = [
        "mon",
        "chu",
        "zard",
        "rex",
        "wing",
        "claw",
        "tail",
        "fang"
    ];

    constructor() ERC721A("SeiMons", "SMON") {}

    // Original mint function (kept for compatibility)
    function mint(uint256 quantity) external payable nonReentrant {
        // Use custom errors for efficiency
        if (quantity == 0 || quantity > MAX_PER_MINT)
            revert InvalidMintQuantity();

        uint256 totalPrice = PRICE_PER_TOKEN * quantity;
        if (msg.value < totalPrice)
            revert InsufficientPayment(totalPrice, msg.value);

        uint256 currentSupply = totalSupply();
        if (currentSupply + quantity > MAX_SUPPLY)
            revert ExceedsMaxSupply(quantity, MAX_SUPPLY - currentSupply);

        _mintInternal(msg.sender, quantity);
    }

    // Mint function using require() statements - LESS GAS EFFICIENT
    // This version uses more gas and creates larger bytecode
    function mintWithRequire(uint256 quantity) external payable nonReentrant {
        require(quantity > 0, "Quantity must be greater than 0");
        require(quantity <= MAX_PER_MINT, "Exceeds maximum per mint");

        uint256 totalPrice = PRICE_PER_TOKEN * quantity;
        require(msg.value >= totalPrice, "Insufficient payment sent");

        uint256 currentSupply = totalSupply();
        require(
            currentSupply + quantity <= MAX_SUPPLY,
            "Exceeds maximum supply"
        );

        _mintInternal(msg.sender, quantity);
    }

    // Mint function using custom errors - MORE GAS EFFICIENT
    // This version saves ~2.5K gas on failed transactions
    function mintWithCustomError(
        uint256 quantity
    ) external payable nonReentrant {
        if (quantity == 0 || quantity > MAX_PER_MINT)
            revert InvalidMintQuantity();

        uint256 totalPrice = PRICE_PER_TOKEN * quantity;
        if (msg.value < totalPrice)
            revert InsufficientPayment(totalPrice, msg.value);

        uint256 currentSupply = totalSupply();
        if (currentSupply + quantity > MAX_SUPPLY)
            revert ExceedsMaxSupply(quantity, MAX_SUPPLY - currentSupply);

        _mintInternal(msg.sender, quantity);
    }

    // Internal mint logic shared by all mint functions
    function _mintInternal(address to, uint256 quantity) private {
        uint256 startId = totalSupply();
        _safeMint(to, quantity);

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = startId + i;
            _generateMonster(tokenId);
            // Emit event after monster is generated
            emit MonsterMinted(
                tokenId,
                to,
                monsters[tokenId].name,
                monsters[tokenId].rarity
            );
        }
    }

    function _generateMonster(uint256 tokenId) private {
        // Generate pseudo-random seed
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    tokenId,
                    msg.sender
                )
            )
        );

        Monster memory monster;
        monster.seed = seed;

        // Determine rarity (weighted)
        uint256 rarityRoll = seed % 100;
        if (rarityRoll < 50)
            monster.rarity = 0; // 50% Common
        else if (rarityRoll < 75)
            monster.rarity = 1; // 25% Uncommon
        else if (rarityRoll < 90)
            monster.rarity = 2; // 15% Rare
        else if (rarityRoll < 98)
            monster.rarity = 3; // 8% Epic
        else monster.rarity = 4; // 2% Legendary

        // Generate types
        monster.primaryType = ElementType(seed % 8);
        monster.secondaryType = ElementType((seed >> 8) % 8);

        // Generate stats based on rarity
        uint8 statBonus = monster.rarity * 20;
        monster.hp = uint8(30 + ((seed >> 16) % 100) + statBonus);
        monster.attack = uint8(10 + ((seed >> 24) % 100) + statBonus);
        monster.defense = uint8(10 + ((seed >> 32) % 100) + statBonus);
        monster.speed = uint8(10 + ((seed >> 40) % 100) + statBonus);

        // Generate name
        monster.name = _generateName(seed);

        monsters[tokenId] = monster;
    }

    function _generateName(uint256 seed) private view returns (string memory) {
        uint256 prefixIndex = seed % prefixes.length;
        uint256 suffixIndex = (seed >> 8) % suffixes.length;
        return
            string(
                abi.encodePacked(prefixes[prefixIndex], suffixes[suffixIndex])
            );
    }

    // Future expansion functions (placeholder implementations)
    function evolveMonster(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        // TODO: Implement evolution logic
        // For now, just emit an event
        Monster storage monster = monsters[tokenId];
        emit MonsterEvolved(tokenId, monster.name, monster.rarity);
    }

    function battleMonsters(
        uint256 tokenId1,
        uint256 tokenId2
    ) external view override returns (uint256 winner) {
        // Simple battle logic based on total stats
        uint256 power1 = getMonsterPower(tokenId1);
        uint256 power2 = getMonsterPower(tokenId2);
        return power1 >= power2 ? tokenId1 : tokenId2;
    }

    function getMonsterPower(
        uint256 tokenId
    ) public view override returns (uint256) {
        Monster memory monster = monsters[tokenId];
        // Calculate total power as sum of all stats
        return
            uint256(monster.hp) +
            uint256(monster.attack) +
            uint256(monster.defense) +
            uint256(monster.speed);
    }
}
