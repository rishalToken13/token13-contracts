const { ethers } = require('hardhat');
const saveToConfig = require('../utils/saveToConfig');
const { USDC, TOKEN_HOLDER, ADMIN_ADDRESS } = require('../config');

async function main() {

    console.log("Deploying Stable US Dollar Coin (USDC) Contract....")
    const USDCToken = await ethers.getContractFactory("USDCToken");
    const USDCTokenABI = (await artifacts.readArtifact('USDCToken')).abi
    await saveToConfig('USDC_TOKEN', 'ABI', USDCTokenABI)
    const initialSupply = ethers.utils.parseUnits(USDC.INITIAL_SUPPLY,6) // 1 million
    const usdc = await upgrades.deployProxy(
        USDCToken,
        [ADMIN_ADDRESS,TOKEN_HOLDER,initialSupply],
        { initializer: "initialize" }
    );
    await saveToConfig('USDC_TOKEN', 'ADDRESS', usdc.address)
    console.log(`USDC_TOKEN:- ${usdc.address} `);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});