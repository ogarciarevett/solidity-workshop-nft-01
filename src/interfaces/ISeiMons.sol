// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface ISeiMons {
    enum ElementType {
        Fire,
        Water,
        Grass,
        Electric,
        Psychic,
        Dark,
        Dragon,
        Normal
    }

    struct Monster {
        string name;
        ElementType primaryType;
        ElementType secondaryType;
        uint8 hp;
        uint8 attack;
        uint8 defense;
        uint8 speed;
        uint8 rarity;
        uint256 seed;
    }

    event MonsterMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string name,
        uint8 rarity
    );
}
