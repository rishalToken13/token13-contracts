const hre = require("hardhat");
const saveToConfig = require('../utils/saveToConfig');
const { USDC } = require("../config");
const {NAME,SYMBOL,INITIAL_SUPPLY,DECIMALS} = USDC

async function deploy() {

  console.log("Deploying USDC Custom Token Contract....")
  const CustomToken = await ethers.getContractFactory("CustomToken");

  const usdc = await CustomToken.deploy(NAME,SYMBOL,INITIAL_SUPPLY,DECIMALS);
  await saveToConfig(SYMBOL, 'ADDRESS', usdc.address)
  console.log("USDC / STABLE_COIN:-", usdc.address);
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
