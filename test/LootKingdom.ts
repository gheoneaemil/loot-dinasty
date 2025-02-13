import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getContract, parseEventLogs } from "viem";
import { address0x0 } from "../utils/constants";

describe("LootKingdom", function () {
  async function deployOneYearLockFixture() {
    const [anotherAccount, gnosisAccount] = await hre.viem.getWalletClients();
    const gnosisAddresses = await gnosisAccount.getAddresses();

    const LootKingdom = await hre.viem.deployContract("LootKingdom", [gnosisAddresses[0]]);
    const publicClient = await hre.viem.getPublicClient();

    return {
      LootKingdom,
      gnosisAccount,
      anotherAccount,
      publicClient,
    };
  }

  describe("Main Workflows", function () {
    it("Should create the first pack", async function () {
      const { LootKingdom } = await loadFixture(deployOneYearLockFixture);
      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        price: BigInt(500)
      }])).to.be.fulfilled;
    });

    it("Should set allowed edit access to true", async function () {
      const { LootKingdom } = await loadFixture(deployOneYearLockFixture);
      const packBefore = await LootKingdom.read.packs([BigInt(0)]);
      expect(packBefore[2]).to.be.false;
      await expect(LootKingdom.write.setAllowedEditAccess([0])).to.be.fulfilled;
      const packAfter = await LootKingdom.read.packs([BigInt(0)]);
      expect(packAfter[2]).to.be.true;
    });

    it("Should get the right owner", async function () {
      const { LootKingdom, gnosisAccount } = await loadFixture(deployOneYearLockFixture);
      const addresses = await gnosisAccount.getAddresses();
      expect(await LootKingdom.read.owner()).to.equal(addresses[0]);
    });

    it("Should have default balance 0", async function () {
      const { LootKingdom, publicClient } = await loadFixture(
        deployOneYearLockFixture
      );
      expect(
        await publicClient.getBalance({
          address: LootKingdom.address,
        })
      ).to.equal(BigInt(0));
    });

    it("Should fail to overwrite pack when editable status is false", async function () {
      const { LootKingdom } = await loadFixture(deployOneYearLockFixture);

      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        price: BigInt(500)
      }])).to.be.fulfilled;

      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        price: BigInt(500)
      }])).to.be.rejectedWith("Cannot be edited right now");
    });

    it("Should succeed to overwrite pack when editable status is true", async function () {
      const { LootKingdom } = await loadFixture(deployOneYearLockFixture);

      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        price: BigInt(500)
      }])).to.be.fulfilled;

      const packBefore = await LootKingdom.read.packs([BigInt(0)]);
      expect(packBefore[2]).to.be.false;
      await expect(LootKingdom.write.setAllowedEditAccess([0])).to.be.fulfilled;
      const packAfter = await LootKingdom.read.packs([BigInt(0)]);
      expect(packAfter[2]).to.be.true;

      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        price: BigInt(500)
      }])).to.be.fulfilled;
    });

    it("Should fail on invalid input for pack creation", async function () {
      const { LootKingdom } = await loadFixture(deployOneYearLockFixture);

      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5)],
        prices: [BigInt(1000), BigInt(2000)],
        price: BigInt(500)
      }])).to.be.rejectedWith("Invalid length");
    });

    it("Should fail if onlyOwner method called by other wallet", async function () {
      const { LootKingdom, anotherAccount } = await loadFixture(deployOneYearLockFixture);
      const addresses = await anotherAccount.getAddresses();
      const owner = await LootKingdom.read.owner();
      expect(owner !== addresses[1]);

      await LootKingdom.write.transferOwnership([addresses[1]]);

      await expect(LootKingdom.write.setPack([0, {
          token: address0x0,
          editable: false,
          prizes: [BigInt(0), BigInt(5), BigInt(10)],
          prices: [BigInt(1000), BigInt(2000)],
          price: BigInt(500)
        }]
      )).to.be.rejectedWith(`OwnableUnauthorizedAccount("${owner}")`);
    });

    it("Should fail to open due to no funds paid", async function () {
      const { LootKingdom, anotherAccount } = await loadFixture(deployOneYearLockFixture);
      const addresses = await anotherAccount.getAddresses();
      const owner = await LootKingdom.read.owner();
      expect(owner !== addresses[1]);
  
      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        price: BigInt(500)
      }])).to.be.fulfilled;
  
      const contract = getContract({
        address: LootKingdom.address,
        abi: LootKingdom.abi,
        client: anotherAccount,
      });
  
      await expect(contract.write.open([0,1])).to.be.rejectedWith("Insufficient balance");
    });
  
    it("Should succeed to open lootbox", async function () {
      const { LootKingdom, anotherAccount } = await loadFixture(deployOneYearLockFixture);
      const addresses = await anotherAccount.getAddresses();
      const owner = await LootKingdom.read.owner();
      expect(owner !== addresses[1]);
      const packPrice = BigInt(500);
  
      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        price: packPrice
      }])).to.be.fulfilled;
  
      const contract = getContract({
        address: LootKingdom.address,
        abi: LootKingdom.abi,
        client: anotherAccount,
      });

      const packId = 0;
      const qty = 1;

      await expect(contract.write.open([packId,qty], { value: packPrice })).to.be.fulfilled;
    });

    it("Should succeed to open 10.000x lootboxes", async function () {
      const { LootKingdom, anotherAccount, publicClient } = await loadFixture(deployOneYearLockFixture);
      const addresses = await anotherAccount.getAddresses();
      const owner = await LootKingdom.read.owner();
      expect(owner !== addresses[1]);
      const packPrice = BigInt(500);
  
      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        price: packPrice
      }])).to.be.fulfilled;
  
      const contract = getContract({
        address: LootKingdom.address,
        abi: LootKingdom.abi,
        client: anotherAccount,
      });
  
      const qty = 10000;
      const packId = 0;
      const txHash = await contract.write.open([packId,qty], { value: packPrice * BigInt(qty) });
      const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });

      const logs = parseEventLogs({
        abi: LootKingdom.abi,
        eventName: "Open",
        logs: receipt.logs,
      });

      expect(logs).to.have.lengthOf(1);
      expect(logs[0].args.packId).to.equal(packId);
      expect(logs[0].args.qty).to.equal(qty);
    });

    it("Should succeed to open 1.000.000x lootboxes", async function () {
      const { LootKingdom, anotherAccount, publicClient } = await loadFixture(deployOneYearLockFixture);
      const addresses = await anotherAccount.getAddresses();
      const owner = await LootKingdom.read.owner();
      expect(owner !== addresses[1]);
      const packPrice = BigInt(500);
  
      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        price: packPrice
      }])).to.be.fulfilled;
  
      const contract = getContract({
        address: LootKingdom.address,
        abi: LootKingdom.abi,
        client: anotherAccount,
      });

      const qty = 1_000_000;
      const packId = 0;
      const txHash = await contract.write.open([packId,qty], { value: packPrice * BigInt(qty) });
      const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });

      const logs = parseEventLogs({
        abi: LootKingdom.abi,
        eventName: "Open",
        logs: receipt.logs,
      });

      expect(logs).to.have.lengthOf(1);
      expect(logs[0].args.packId).to.equal(packId);
      expect(logs[0].args.qty).to.equal(qty);
    });

    it("Should succeed setting a hash key from user side", async function () {
      const { LootKingdom } = await loadFixture(deployOneYearLockFixture);
      await expect(LootKingdom.write.setHashkey([0, "test_hash_key"])).to.be.fulfilled;
    });

    it("Should fail setting a hash key twice in a row without waiting for cooldown", async function () {
      const { LootKingdom } = await loadFixture(deployOneYearLockFixture);
      await expect(LootKingdom.write.setHashkey([0, "test_hash_key"])).to.be.fulfilled;
      await expect(LootKingdom.write.setHashkey([0, "test_hash_key"])).to.be.rejected;
    });
  });
});
