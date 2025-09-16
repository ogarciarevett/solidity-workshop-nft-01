import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const FEE_PERCENTAGE = 2; // 2%
const FEE_MANAGER_ADDRESS = '0xB83a590E604beCaDF71D6fC94C6cf600BBFc29Be';

const SeimonModule = buildModule('SeimonModule', (m) => {
    const feePercentage = m.getParameter('feePercentage', FEE_PERCENTAGE);
    const feeManager = m.getParameter('feeManager', FEE_MANAGER_ADDRESS);

    const mockNft = m.contract('MockNFT');
    const seimon = m.contract('Seimon', [feePercentage, feeManager], {
        after: [mockNft],
    });

    return { seimon, mockNft };
});

export default SeimonModule;
