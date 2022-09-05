import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, waffle} from 'hardhat';
import LandingTokenArtifacts from '../artifacts/contracts/LandingToken.sol/LandingToken.json';
import {LandingToken} from '../typechain/contracts/LandingToken';
import OracleArtifacts from '../artifacts/contracts/Oracle.sol/Oracle.json';
import {Oracle} from '../typechain/contracts/Oracle';
import ProtocolArtifacts from '../artifacts/contracts/Protocol.sol/Protocol.json';
import {Protocol} from '../typechain/contracts/Protocol';
import { LandingToken__factory } from '../typechain/factories/contracts/LandingToken__factory';

const {deployContract} = waffle;

describe("Greeter test", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshopt in every test.
  async function deployOnceFixture() {
    const initTimestamp: number = 1661990400; // UTC timestamp, Sept 1st, 2022, 12:00 am 
    let landingToken: LandingToken;
    let oracle: Oracle;
    let protocol: Protocol;
    // Contracts are deployed using the first signer/account by default
    const [owner, ...otherAccounts] = await ethers.getSigners();

    oracle = (await deployContract(owner, LandingTokenArtifacts)) as Oracle;
    protocol = (await deployContract(owner, LandingTokenArtifacts, [oracle.address, initTimestamp])) as Protocol;
    landingToken = LandingToken__factory.connect(await protocol.getLandingTokenAddress(), owner) as LandingToken;
    
    return {  owner, otherAccounts, protocol, landingToken, oracle };
  }

  describe("Test suite", function () {
    it("Test 1", async function () {
      const { owner } = await loadFixture(deployOnceFixture);
      expect(true);
    });

    it("Test 2", async function () {
      const {  owner } = await loadFixture(deployOnceFixture);
      expect(1).to.equal(1);
    });



  });

 
});
