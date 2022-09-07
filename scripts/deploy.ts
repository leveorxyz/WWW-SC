import { ethers } from "hardhat";

async function main() {
  // const lockedAmount = ethers.utils.parseEther("1");

  const Oracle = await ethers.getContractFactory("Oracle");
  // const greeting = await Greeting.deploy("Hello world", { value: lockedAmount });
  const oracle = await Oracle.deploy();

  await oracle.deployed();
  console.log("Greeting contract deployed to: ", oracle.address);


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
