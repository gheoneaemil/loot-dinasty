import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getAddress, parseGwei } from "viem";

const address0x0 = "0x0000000000000000000000000000000000000000";

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
        prices: [BigInt(1000), BigInt(2000), BigInt(3000)],
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
        prices: [BigInt(1000), BigInt(2000), BigInt(3000)],
        price: BigInt(500)
      }])).to.be.fulfilled;

      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000), BigInt(3000)],
        price: BigInt(500)
      }])).to.be.rejectedWith("Cannot be edited right now");
    });

    it("Should succeed to overwrite pack when editable status is true", async function () {
      const { LootKingdom } = await loadFixture(deployOneYearLockFixture);

      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000), BigInt(3000)],
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
        prices: [BigInt(1000), BigInt(2000), BigInt(3000)],
        price: BigInt(500)
      }])).to.be.fulfilled;
    });

    it("Should fail on invalid input for pack creation", async function () {
      const { LootKingdom } = await loadFixture(deployOneYearLockFixture);

      await expect(LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5)],
        prices: [BigInt(1000), BigInt(2000), BigInt(3000)],
        price: BigInt(500)
      }])).to.be.rejectedWith("Invalid length");
    });

    it("Should fail if onlyOwner method called by other wallet", async function () {
      const { LootKingdom, publicClient, anotherAccount } = await loadFixture(deployOneYearLockFixture);
      const hash = await LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(10)],
        prices: [BigInt(1000), BigInt(2000), BigInt(3000)],
        price: BigInt(500)
      }]);
      const ok = await publicClient.waitForTransactionReceipt({ hash });

      const request = await publicClient.prepareTransactionRequest({
        account: anotherAccount.account,
        to: LootKingdom.address,
        value: 1000000000000000000n
      })

      await publicClient.sendRawTransaction({
        serializedTransaction 
      });
      console.log(ok);
    });
  });

  describe("Withdrawals", function () {
    describe("Validations", function () {
      it("Should revert with the right error if called too soon", async function () {
        const { LootKingdom } = await loadFixture(deployOneYearLockFixture);

        await expect(LootKingdom.write.withdraw()).to.be.rejectedWith(
          "You can't withdraw yet"
        );
      });

      it("Should revert with the right error if called from another account", async function () {
        const { unlockTime, gnosisAccount } = await loadFixture(
          deployOneYearLockFixture
        );

        // We can increase the time in Hardhat Network
        await time.increaseTo(unlockTime);

        /*
        // We retrieve the contract with a different account to send a transaction
        const lockAsOtherAccount = await hre.viem.getContractAt(
          "LootKingdom",
          gnosisAccount.address,
          { client: { wallet: gnosisAccount } }
        );
        await expect(lockAsOtherAccount.write.withdraw()).to.be.rejectedWith(
          "You aren't the owner"
        );
        */
      });

      it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
        const { LootKingdom, unlockTime } = await loadFixture(
          deployOneYearLockFixture
        );

        // Transactions are sent using the first signer by default
        await time.increaseTo(unlockTime);

        await expect(LootKingdom.write.withdraw()).to.be.fulfilled;
      });
    });

    describe("Events", function () {
      it("Should emit an event on withdrawals", async function () {
        const { LootKingdom, unlockTime, lockedAmount, publicClient } =
          await loadFixture(deployOneYearLockFixture);

        await time.increaseTo(unlockTime);

        const hash = await LootKingdom.write.withdraw();
        await publicClient.waitForTransactionReceipt({ hash });

        // get the withdrawal events in the latest block
        const withdrawalEvents = await LootKingdom.getEvents.Withdrawal();
        expect(withdrawalEvents).to.have.lengthOf(1);
        //expect(withdrawalEvents[0].args.amount).to.equal(lockedAmount);
      });
    });
  });
});
