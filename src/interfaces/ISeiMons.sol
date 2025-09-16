// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface ISeiMons {
    // Custom errors (more gas efficient than require strings)
    error InvalidMintQuantity();
    error InsufficientPayment(uint256 required, uint256 provided);
    error ExceedsMaxSupply(uint256 requested, uint256 available);
    error NotTokenOwner(address caller, uint256 tokenId);
    error TokenDoesNotExist(uint256 tokenId);

    // Pokemon-inspired type system
    enum ElementType {
        Fire, // 0 - Red/Orange colors
        Water, // 1 - Blue colors
        Grass, // 2 - Green colors
        Electric, // 3 - Yellow colors
        Psychic, // 4 - Purple colors
        Dark, // 5 - Black/Gray colors
        Dragon, // 6 - Multi-color
        Normal // 7 - Brown/Beige colors
    }

    struct Monster {
        string name;
        ElementType primaryType;
        ElementType secondaryType;
        uint8 hp; // 30-255 HP
        uint8 attack; // 10-255 Attack
        uint8 defense; // 10-255 Defense
        uint8 speed; // 10-255 Speed
        uint8 rarity; // 0=Common, 1=Uncommon, 2=Rare, 3=Epic, 4=Legendary
        uint256 seed; // For visual generation
    }

    // Events
    event MonsterMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string name,
        uint8 rarity
    );

    event MonsterEvolved(
        uint256 indexed tokenId,
        string newName,
        uint8 newRarity
    );

    // Core functions
    function mint(uint256 quantity) external payable;

    // Comparison methods for gas efficiency demonstration
    function mintWithRequire(uint256 quantity) external payable;
    function mintWithCustomError(uint256 quantity) external payable;

    // View functions
    function monsters(
        uint256 tokenId
    )
        external
        view
        returns (
            string memory name,
            ElementType primaryType,
            ElementType secondaryType,
            uint8 hp,
            uint8 attack,
            uint8 defense,
            uint8 speed,
            uint8 rarity,
            uint256 seed
        );

    // Future expansion functions (optional to implement)
    function evolveMonster(uint256 tokenId) external;
    function battleMonsters(
        uint256 tokenId1,
        uint256 tokenId2
    ) external view returns (uint256 winner);
    function getMonsterPower(uint256 tokenId) external view returns (uint256);
}
