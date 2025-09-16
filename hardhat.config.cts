import type { HardhatUserConfig } from 'hardhat/config';
import type { NetworksUserConfig } from 'hardhat/types';
import '@nomicfoundation/hardhat-toolbox-viem';
import '@nomicfoundation/hardhat-viem';
import '@nomicfoundation/hardhat-chai-matchers';
import '@openzeppelin/hardhat-upgrades';
import '@typechain/hardhat';
import { ChainId, NetworkName, rpcUrls } from './constants/networks';
import 'dotenv/config';

const { PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;
const accounts = PRIVATE_KEY ? [PRIVATE_KEY] : [];
const GAS_PRICE = 2000000000; // 2 gwei = 2 nsei

const config: HardhatUserConfig = {
    solidity: {
        version: '0.8.28',
        settings: {
            optimizer: {
                enabled: true,
                runs: 1000,
            },
        },
    },
    networks: {
        [NetworkName.Sei]: {
            url: rpcUrls[ChainId.Sei],
            accounts,
            chainId: ChainId.Sei,
            gasPrice: GAS_PRICE,
        },
        [NetworkName.SeiTestnet]: {
            url: rpcUrls[ChainId.SeiTestnet],
            accounts,
            chainId: ChainId.SeiTestnet,
            gasPrice: GAS_PRICE,
        },
        [NetworkName.Hardhat]: {
            chainId: ChainId.Hardhat,
        },
    },
    sourcify: {
        enabled: false, // Sourcify doesn't support Sei chain
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
        customChains: [
            {
                network: NetworkName.SeiTestnet,
                chainId: ChainId.SeiTestnet,
                urls: {
                    apiURL: 'https://api.etherscan.io/v2/api',
                    browserURL: 'https://testnet.seiscan.io',
                },
            },
            {
                network: NetworkName.Sei,
                chainId: ChainId.Sei,
                urls: {
                    apiURL: 'https://api.etherscan.io/v2/api',
                    browserURL: 'https://seiscan.io',
                },
            },
        ],
    }
};

export default config;
