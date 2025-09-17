// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SeiMons} from "./SeiMons.sol";
import {ISeiMons} from "./interfaces/ISeiMons.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract SeiMonsRandom is SeiMons {
    using Strings for uint256;

    // State variables
    // Using the Monster struct and ElementType enum from ISeiMons interface
    mapping(uint256 => ISeiMons.Monster) public monsters;

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

    // Events
    event MonsterGenerated(
        uint256 indexed tokenId,
        string name,
        uint8 rarity,
        ISeiMons.ElementType primaryType,
        ISeiMons.ElementType secondaryType
    );

    // Override mint to generate monsters
    function mint(uint256 quantity) internal override {
        uint256 startTokenId = totalSupply();
        _safeMint(msg.sender, quantity);

        // Generate monster data for each minted token
        for (uint256 i = 0; i < quantity; i++) {
            _generateMonster(startTokenId + i);
        }
    }

    function _generateMonster(uint256 tokenId) private {
        // Pseudo-random seed (no Chainlink VRF on SEI)
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao, // Post-merge randomness
                    tokenId,
                    msg.sender
                )
            )
        );

        ISeiMons.Monster memory monster;
        monster.seed = seed;

        // Weighted rarity distribution
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

        // Type generation
        monster.primaryType = ISeiMons.ElementType(seed % 8);
        monster.secondaryType = ISeiMons.ElementType((seed >> 8) % 8);

        // Stats based on rarity
        uint8 statBonus = monster.rarity * 20;
        monster.hp = uint8(30 + ((seed >> 16) % 100) + statBonus);
        monster.attack = uint8(10 + ((seed >> 24) % 100) + statBonus);
        monster.defense = uint8(10 + ((seed >> 32) % 100) + statBonus);
        monster.speed = uint8(10 + ((seed >> 40) % 100) + statBonus);

        monster.name = _generateName(seed);
        monsters[tokenId] = monster;

        emit MonsterGenerated(
            tokenId,
            monster.name,
            monster.rarity,
            monster.primaryType,
            monster.secondaryType
        );
    }

    function _generateName(uint256 seed) private view returns (string memory) {
        uint256 prefixIndex = (seed >> 48) % prefixes.length;
        uint256 suffixIndex = (seed >> 56) % suffixes.length;
        return
            string(
                abi.encodePacked(prefixes[prefixIndex], suffixes[suffixIndex])
            );
    }

    // View functions
    function getMonster(
        uint256 tokenId
    ) external view returns (ISeiMons.Monster memory) {
        require(_exists(tokenId), "Token does not exist");
        return monsters[tokenId];
    }

    function getRarityName(uint8 rarity) external pure returns (string memory) {
        string[5] memory rarityNames = [
            "Common",
            "Uncommon",
            "Rare",
            "Epic",
            "Legendary"
        ];
        require(rarity < 5, "Invalid rarity");
        return rarityNames[rarity];
    }

    function getElementName(
        ISeiMons.ElementType element
    ) external pure returns (string memory) {
        string[8] memory elementNames = [
            "Fire",
            "Water",
            "Grass",
            "Electric",
            "Psychic",
            "Dark",
            "Dragon",
            "Normal"
        ];
        return elementNames[uint8(element)];
    }
}
