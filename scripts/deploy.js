const { ethers, upgrades } = require("hardhat");

async function main() {
  // Deploying
  const MyDexV1 = await ethers.getContractFactory("MyDexV1");
  const instance = await upgrades.deployProxy(MyDexV1, ["0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"]);
  await instance.deployed();

  // Upgrading
  const MyDexV2 = await ethers.getContractFactory("MyDexV2");
  const upgraded = await upgrades.upgradeProxy(instance.address, MyDexV2);
}

main();
