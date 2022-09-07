import { ethers } from "hardhat";

async function main() {
  // const lockedAmount = ethers.utils.parseEther("1");

  const Oracle = await ethers.getContractFactory("Oracle");
  const Protocol = await ethers.getContractFactory("Protocol");
  // const greeting = await Greeting.deploy("Hello world", { value: lockedAmount });
  const oracle = await Oracle.deploy();
 
  const initTimestamp: number = 1659312000; // UTC timestamp, August 1st, 2022, 12:00 am 
  const masterAccount = "0xe85e8024AbD6E38BE80Df5678882303B8787C242";
  await oracle.deployed();
  const protocol = await Protocol.deploy(oracle.address, initTimestamp, masterAccount);
  await protocol.deployed();

  console.log("Oracle contract deployed to: ", oracle.address);
  console.log("Protocol contract deployed to: ", protocol.address);
  console.log(await protocol.functions.getLandingTokenAddress());
  

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
