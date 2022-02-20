import { ethers } from "hardhat";

const main = async () => {
  const domainContractFactory = await ethers.getContractFactory("Domains");
  // We pass in "ninja" to the constructor when deploying
  const domainContract = await domainContractFactory.deploy("f1");
  await domainContract.deployed();

  console.log("Contract deployed to:", domainContract.address);

  // We're passing in a second variable - value. This is the moneyyyyyyyyyy
  let txn = await domainContract.register("shreyas", {
    value: ethers.utils.parseEther("0.1"),
  });
  await txn.wait();

  const address = await domainContract.getAddress("shreyas");
  console.log("Owner of domain shreyas:", address);

  const balance = await ethers.provider.getBalance(domainContract.address);
  console.log("Contract balance:", ethers.utils.formatEther(balance));
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
