import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

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
        chances: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        ids: ["0", "1", "2"]
      }])).to.be.fulfilled;
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

    it("Should fail if onlyOwner method called by other wallet", async function () {
      const { LootKingdom, anotherAccount } = await loadFixture(deployOneYearLockFixture);
      const addresses = await anotherAccount.getAddresses();
      const owner = await LootKingdom.read.owner();
      expect(owner !== addresses[1]);

      await LootKingdom.write.transferOwnership([addresses[1]]);

      await expect(LootKingdom.write.setPack([0, {
          chances: [BigInt(0), BigInt(5), BigInt(10)],
          prices: [BigInt(1000), BigInt(2000)],
          ids: ["0", "1", "2"]
        }]
      )).to.be.rejected;
    });

    it("Should succeed to whitelist address", async function () {
      const { LootKingdom, anotherAccount } = await loadFixture(deployOneYearLockFixture);
      const addresses = await anotherAccount.getAddresses();
      const owner = await LootKingdom.read.owner();
      expect(owner !== addresses[1]);

      const args: Array<`0x${string}`> = [owner as any, addresses[1]];
      await expect(LootKingdom.write.setWhitelist([args])).to.be.fulfilled;
    });

    it("Should succeed to validate opening", async function () {
      const { LootKingdom, anotherAccount } = await loadFixture(deployOneYearLockFixture);
      const addresses = await anotherAccount.getAddresses();
      const owner = await LootKingdom.read.owner();
      expect(owner !== addresses[1]);

      const args: Array<`0x${string}`> = [owner as any, addresses[1]];
      await expect(LootKingdom.write.setWhitelist([args])).to.be.fulfilled;

      await expect(LootKingdom.write.setPack([1, {
        chances: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        ids: ["0", "1", "2"]
      }])).to.be.fulfilled;
      
      await LootKingdom.write.batchValidateOpens(
        [[BigInt(1)], [BigInt(1)], "", ["dfgfdgd32fsd"]]
      );
    });

  });
});
