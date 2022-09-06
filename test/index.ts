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

describe("Landing token test suite", function () {
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
    const masterAccount = otherAccounts[0];
 
    oracle = (await deployContract(owner, OracleArtifacts)) as Oracle;
    protocol = (await deployContract(owner, ProtocolArtifacts, [oracle.address, initTimestamp, masterAccount.address])) as Protocol;
    landingToken = LandingToken__factory.connect(await protocol.getLandingTokenAddress(), owner) as LandingToken;
  
    // console.log(oracle.address);
    // console.log(protocol.address);
    // console.log(landingToken.address);
    
    return {  owner, masterAccount, otherAccounts, oracle, protocol, landingToken };
  }

  describe("Test suite", function () {

    function strToUtf16Bytes(str: string) {
      const bytes = [];
      for (let index = 0; index < str.length; index++) {
        const code = str.charCodeAt(index); // x00-xFFFF
        bytes.push(code & 255, code >> 8); // low, high
      }
      return bytes;
    }

    function hex_to_ascii(str1: { toString: () => any; })
    {
      var hex  = str1.toString();
      var str = '';
      for (var n = 0; n < hex.length; n += 2) {
        str += String.fromCharCode(parseInt(hex.substr(n, 2), 16));
      }
      return str;
    }

   const getBalance = async (tokenContract: LandingToken, address: string) => {
     return Number(await tokenContract.balanceOf(address))/ 10**18;
   }

   const getPrice = async (tokenContract: LandingToken) => {
    return Number(await tokenContract.getPrice())/ 10**18;
  }

   const getAllowance = async (tokenContract: LandingToken, ownerAddress: string, spenderAddress: string) => {
    return Number(await tokenContract.allowance(ownerAddress, spenderAddress))/ 10**18;
  }
    it("Should initial price be 1", async function () {
      const { landingToken } = await loadFixture(deployOnceFixture);
      const price = Number(await landingToken.getPrice()) / (10**18);
      expect(price).to.eq(1);
    });

    it("Should initial supply be be 1000000000000", async function () {
      const { landingToken } = await loadFixture(deployOnceFixture);
      const supply = Number(await landingToken.totalSupply()) / (10**18);
      expect(supply).to.eq(1000000000000);
    });

    it("Should initial allowance for protocol from token contract be 1000000000000", async function () {
      const { landingToken, protocol } = await loadFixture(deployOnceFixture);
      const allowance = Number(await landingToken.allowance(landingToken.address, protocol.address)) / (10**18);
      expect(allowance).to.eq(1000000000000);
    });

    it("Should buy landc", async function () {
      const { owner, protocol, oracle, landingToken } = await loadFixture(deployOnceFixture);
      let txID = "6pRNASCoBOKtIshFeQd4XMUh";
      let usdAmount = 100;
      
      expect(await getAllowance(landingToken, owner.address, protocol.address)).to.eq(0);
      expect(await getPrice(landingToken)).to.eq(1);
      
      expect(await getBalance(landingToken, owner.address)).to.eq(0);
      expect(await getBalance(landingToken, landingToken.address)).to.eq(1000000000000);
      let tx = await oracle.addBuyTx(txID, usdAmount);
      await tx.wait();
      tx = await protocol.buyLANDC(usdAmount, txID);
      await tx.wait();
      expect(await getBalance(landingToken, owner.address)).to.eq(96);
      expect(await getBalance(landingToken, landingToken.address)).to.eq(999999999900);
      expect(await getAllowance(landingToken, owner.address, protocol.address)).to.eq(96);
      expect(await getPrice(landingToken)).to.eq(1.000000000004);
      
    });

    it("Should sell token", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);
      let txID = "6pRNASCoBOKtIshFeQd4XMUh";
      let usdAmount = 100;
      let tx = await oracle.addBuyTx(txID, usdAmount);
      await tx.wait();
      tx = await protocol.buyLANDC(usdAmount, txID);
      await tx.wait();
      expect(await getPrice(landingToken)).to.eq(1.000000000004);

      expect(await getAllowance(landingToken, owner.address, protocol.address)).to.eq(96);
      expect(await getBalance(landingToken, owner.address)).to.eq(96);
      expect(await getBalance(landingToken, landingToken.address)).to.eq(999999999900);
      
      usdAmount = 90;
      tx = await oracle.addSellTx(txID, usdAmount);
      await tx.wait();
      tx = await protocol.sellLANDC(1, usdAmount, txID);
      await tx.wait();
      expect(await getPrice(landingToken)).to.eq(1.000000000004);
      
      expect(await getAllowance(landingToken, owner.address, protocol.address)).to.eq(5.999999999640001);
      expect(await getBalance(landingToken, owner.address)).to.eq(5.999999999640001);
      expect(await getBalance(landingToken, landingToken.address)).to.eq(999999999990);
    });

    it("Should add new property", async function () {
      const { protocol } = await loadFixture(deployOnceFixture);
      const propertyID = 43947893;
      const imageID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
      const legalDocID = "bafkreidgvpkjawlxz6sffxzwgooowe5yt7i6wsyg236mfoks77nywkptdq";
      let tx = await protocol.addProperty(propertyID, strToUtf16Bytes(imageID), strToUtf16Bytes(legalDocID));
      await tx.wait();
      const propertyDetails = await protocol.getProperty(propertyID);
      let resImageID = hex_to_ascii(propertyDetails[0]).toString().replace(/[^\w\s]/gi, '');
      let resDocID = hex_to_ascii(propertyDetails[1]).toString().replace(/[^\w\s]/gi, '');
      expect(resImageID).to.eq(imageID);
      expect(resDocID).to.eq(legalDocID);
    });


    it.only("Should pay rent in landc", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);
      const propertyID = 43947893;
      const imageID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
      const legalDocID = "bafkreidgvpkjawlxz6sffxzwgooowe5yt7i6wsyg236mfoks77nywkptdq";
      let tx = await protocol.addProperty(propertyID, strToUtf16Bytes(imageID), strToUtf16Bytes(legalDocID));
      await tx.wait();
      let txID = "6pRNASCoBOKtIshFeQd4XMUh";
      let usdAmount = 100;
      tx = await oracle.addBuyTx(txID, usdAmount);
      await tx.wait();
      tx = await protocol.buyLANDC(usdAmount, txID);
      await tx.wait();

      expect(await getAllowance(landingToken, owner.address, protocol.address)).to.eq(96);
      expect(await getBalance(landingToken, owner.address)).to.eq(96);
      expect(await getBalance(landingToken, protocol.address)).to.eq(0);

      let rentPaid =  ethers.utils.parseUnits("50", "ether");
      tx = await  protocol.payRentLandc(rentPaid, 1661990400, propertyID);
      await tx.wait();
      expect(await getAllowance(landingToken, owner.address, protocol.address)).to.eq(46);
     
      expect(await getBalance(landingToken, owner.address)).to.eq(46);
      expect(await getBalance(landingToken, protocol.address)).to.eq(50);
    });

    it("Should convert usd to landc", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);

    });

    it("Should ", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);
    });

    it("Should ", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);
    });

    it("Should ", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);
    });

    it("Should ", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);
    });

    it("Should ", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);
    });

    it("Should ", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);
    });

    it("Should ", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);
    });

    it("Should ", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);
    });

    it("Should ", async function () {
      const { owner, landingToken, protocol, oracle } = await loadFixture(deployOnceFixture);
    });

  });

 
});
