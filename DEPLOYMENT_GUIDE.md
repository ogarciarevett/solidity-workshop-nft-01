# Sei Testnet Deployment Guide

This guide will walk you through deploying and verifying the SeiMons NFT contracts on Sei Testnet.

## Prerequisites

1. **Install Foundry**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Get Sei Testnet ETH**
   - Visit: https://faucet.sei.io/
   - Request testnet SEI tokens for your deployer address

3. (Optional) **Seitrace Account**
   - Not required for verification via Blockscout API

## Setup

1. **Clone and install dependencies**
   ```bash
   # Install contract dependencies
   forge install
   ```

2. **Create `.env` file**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and add:
   ```env
   # Sei Testnet Configuration
   SEI_TESTNET_RPC_URL=https://evm-rpc-testnet.sei-apis.com

   # Your wallet private key (without 0x prefix)
   PRIVATE_KEY=your_private_key_here

   # Seitrace API key for verification
   SEI_TESTNET_ETHERSCAN_KEY=your_seitrace_api_key_here
   ```

3. **Test the setup**
   ```bash
   # Check your wallet balance
   cast balance YOUR_ADDRESS --rpc-url https://evm-rpc-testnet.sei-apis.com

   # Run tests locally
   forge test
   ```

## Deployment

### Deploy All Contracts

```bash
# Deploy to Sei Testnet (without verification)
forge script script/Deploy.s.sol:Deploy \
  --rpc-url https://evm-rpc-testnet.sei-apis.com \
  --chain-id 1328 \
  --broadcast \
  -vvvv

# OR Deploy with verification (Seitrace/Blockscout; no API key required)
source .env  # Load environment variables first (PRIVATE_KEY)
forge script script/Deploy.s.sol:Deploy \
  --rpc-url https://evm-rpc-testnet.sei-apis.com \
  --chain-id 1328 \
  --broadcast \
  --verify \
  --verifier blockscout \
  --verifier-url https://seitrace.com/atlantic-2/api \
  -vvvv
```

### Deploy with Custom Gas Settings

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url https://evm-rpc-testnet.sei-apis.com \
  --chain-id 1328 \
  --gas-price 10gwei \
  --broadcast \
  --verify \
  --verifier blockscout \
  --verifier-url https://seitrace.com/atlantic-2/api \
  -vvvv
```

## Contract Verification

### Automatic Verification
If the `--verify` flag doesn't work automatically, you can verify manually:

### Manual Verification

1. **Verify SeiMons**
   ```bash
   forge verify-contract \
     YOUR_SEIMONS_ADDRESS \
     src/SeiMons.sol:SeiMons \
     --chain-id 1328 \
     --verifier blockscout \
     --verifier-url https://seitrace.com/atlantic-2/api \
     --compiler-version v0.8.28+commit.7893614a \
     --watch
   ```

2. **Verify SeiMonsRandom**
   ```bash
   forge verify-contract \
     YOUR_SEIMONS_RANDOM_ADDRESS \
     src/SeiMonsRandom.sol:SeiMonsRandom \
     --chain-id 1328 \
     --verifier blockscout \
     --verifier-url https://seitrace.com/atlantic-2/api \
     --compiler-version v0.8.28+commit.7893614a \
     --watch
   ```

3. **Verify SeiMonsAssembly**
   ```bash
   forge verify-contract \
     YOUR_SEIMONS_ASSEMBLY_ADDRESS \
     src/SeiMonsAssembly.sol:SeiMonsAssembly \
     --chain-id 1328 \
     --verifier blockscout \
     --verifier-url https://seitrace.com/atlantic-2/api \
     --compiler-version v0.8.28+commit.7893614a \
     --watch
   ```

## Testing on Testnet

### Interact with Deployed Contracts

1. **Mint NFTs**
   ```bash
   # Mint with custom error (more efficient)
   cast send YOUR_SEIMONS_ADDRESS \
     "mintWithCustomError(uint256)" 1 \
     --value 0.0001ether \
     --rpc-url https://evm-rpc-testnet.sei-apis.com \
     --private-key $PRIVATE_KEY
   
   # Mint with require (less efficient - for comparison)
   cast send YOUR_SEIMONS_ADDRESS \
     "mintWithRequire(uint256)" 1 \
     --value 0.0001ether \
     --rpc-url https://evm-rpc-testnet.sei-apis.com \
     --private-key $PRIVATE_KEY
   ```

2. **Check NFT Balance**
   ```bash
   cast call YOUR_SEIMONS_ADDRESS \
     "balanceOf(address)" YOUR_WALLET_ADDRESS \
     --rpc-url https://evm-rpc-testnet.sei-apis.com
   ```

3. **Get Monster Stats (SeiMonsRandom)**
   ```bash
   cast call YOUR_SEIMONS_RANDOM_ADDRESS \
     "getMonster(uint256)" 0 \
     --rpc-url https://evm-rpc-testnet.sei-apis.com
   ```

## Gas Comparison Testing

Run the gas comparison tests on testnet to see the efficiency improvements:

```bash
# Run gas comparison tests
forge test --match-path test/GasComparison.t.sol --gas-report -vvv

# Run assembly optimization tests
forge test --match-path test/SeiMonsAssembly.t.sol --gas-report -vvv
```

## Troubleshooting

### Common Issues

1. **"Insufficient funds"**
   - Make sure you have testnet SEI from the faucet
   - Check balance: `cast balance YOUR_ADDRESS --rpc-url https://evm-rpc-testnet.sei-apis.com`

2. **"Transaction underpriced"**
   - Increase gas price: Add `--gas-price 15gwei` to your command

3. **Verification fails**
   - Ensure you're using the exact compiler version (0.8.28)
   - Check that optimizer settings match: `optimizer = true, optimizer_runs = 200`
   - Try using `--via-ir` flag if verification fails

4. **RPC errors**
   - The RPC endpoint might be rate-limited
   - Try adding delays between transactions
   - Use alternative RPC if available

## Contract Addresses (After Deployment)

Update this section with your deployed contract addresses:

```
Network: Sei Testnet (Chain ID: 1328)
SeiMons: 0x...
SeiMonsRandom: 0x...
SeiMonsAssembly: 0x...
```

## Viewing on Explorer

Once deployed and verified, view your contracts on Seitrace:
- https://seitrace.com/address/YOUR_CONTRACT_ADDRESS?chain=atlantic-2

## Next Steps

1. Test all contract functions on testnet
2. Run gas comparison between different implementations
3. Monitor contract interactions on Seitrace
4. Prepare for mainnet deployment (if applicable)

## Resources

- **Sei Documentation**: https://docs.sei.io/
- **Sei Faucet**: https://faucet.sei.io/
- **Seitrace Explorer**: https://seitrace.com/
- **Foundry Book**: https://book.getfoundry.sh/
- **Sei Discord**: Join for support and updates
