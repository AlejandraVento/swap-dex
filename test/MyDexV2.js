const { expect } = require("chai")
const { ethers, upgrades } = require("hardhat")

describe("Swap tokens contract V2", () => {
  let MyDexV2, myDexV2, owner, addr1, addr2, addr3, ERC20, dai, aave
  before(async () => {
    ;[owner, addr1, addr2, addr3, _] = await ethers.getSigners()
    const MyDexV1 = await ethers.getContractFactory("MyDexV1");
    const instance = await upgrades.deployProxy(MyDexV1, [addr2.address]);
    await instance.deployed();
    MyDexV2 = await ethers.getContractFactory("MyDexV2");
    myDexV2 = await upgrades.upgradeProxy(instance.address, MyDexV2);
    ERC20 = await ethers.getContractFactory("ERC20")
    dai = await ERC20.attach('0x6b175474e89094c44da98b954eedeac495271d0f')
    aave = await ERC20.attach('0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9')
  })
  it("gives back the required token", async () => {
    const initialBalance = await dai.balanceOf(addr1.address)
    const recipientInitialBalance = await addr2.getBalance()
    expect(initialBalance).to.equal(0)
    await myDexV2.connect(addr1).Swap(
      [100], ['0x6b175474e89094c44da98b954eedeac495271d0f'],
      {
        value: ethers.utils.parseEther("1.0"),
      }
    )
    const endBalance = await dai.balanceOf(addr1.address)
    expect(endBalance).to.not.equal(0)
    const recipientEndBalance = await addr2.getBalance()
    expect(recipientInitialBalance).to.not.equal(recipientEndBalance)
  })
  it("gives back the required tokens", async () => {
    const daiInitialBalance = await dai.balanceOf(addr3.address)
    const aaveInitialBalance = await aave.balanceOf(addr3.address)
    const recipientInitialBalance = await addr2.getBalance()
    expect(daiInitialBalance).to.equal(0)
    expect(aaveInitialBalance).to.equal(0)
    await myDexV2.connect(addr3).Swap(
      [50,50], ['0x6b175474e89094c44da98b954eedeac495271d0f','0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9'],
      {
        value: ethers.utils.parseEther("1.0"),
      }
    )
    const daiEndBalance = await dai.balanceOf(addr3.address)
    const aaveEndBalance = await aave.balanceOf(addr3.address)
    expect(daiEndBalance).to.not.equal(0)
    expect(aaveEndBalance).to.not.equal(0)
    const recipientEndBalance = await addr2.getBalance()
    expect(recipientInitialBalance).to.not.equal(recipientEndBalance)
  })
})