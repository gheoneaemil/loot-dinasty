import hre from "hardhat";
import { address0x0 } from "../utils/constants";
import { getContract, parseEventLogs } from "viem";
import { mkdir } from "fs/promises";
import { utils, writeFile } from "xlsx";

const workbook = utils.book_new();

const initializeContract = async () => {
    const [anotherAccount, gnosisAccount] = await hre.viem.getWalletClients();
    const gnosisAddresses = await gnosisAccount.getAddresses();

    const LootKingdom = await hre.viem.deployContract("LootKingdom", [gnosisAddresses[0]]);
    const publicClient = await hre.viem.getPublicClient();

    return {
        anotherAccount, gnosisAccount, LootKingdom, publicClient
    };
}

const run = async () => {
    const { LootKingdom, anotherAccount, publicClient } = await initializeContract();
    const packPrice = BigInt(500);
    await LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes: [BigInt(0), BigInt(5), BigInt(100)],
        prices: [BigInt(1000), BigInt(2000)],
        price: packPrice
    }]);

    const contract = getContract({
        address: LootKingdom.address,
        abi: LootKingdom.abi,
        client: anotherAccount,
    });

    const packId = 0;
    const qty = 1_000_000; //_000;

    const txHash = await contract.write.open([packId,qty], { value: packPrice * BigInt(qty) });
    const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });

    const logs = parseEventLogs({
        abi: LootKingdom.abi,
        eventName: "Open",
        logs: receipt.logs,
    });

    const receivedPackId = logs[0].args.packId;
    const receivedQty = logs[0].args.qty;

    const worksheet = utils.aoa_to_sheet([]);
    utils.book_append_sheet(workbook, worksheet);

    const filePath = `export/${Date.now()}_export.xls`;
    writeFile(workbook, filePath, { bookType: "xls" });

    let initialHash = receipt.blockHash;

    for (let i = 0 ; i < receivedQty ; ++i ) {
        console.log(`${i}/${receivedQty}`);
        const txHash = await LootKingdom.write.fulfillUserOpen([`LOCAL_${initialHash}`, receipt.from, receivedPackId]);
        const fullfillmentReceipt = await publicClient.waitForTransactionReceipt({ hash: txHash });
        initialHash = fullfillmentReceipt.blockHash;
        const fulfillmentLogs = parseEventLogs({
            abi: LootKingdom.abi,
            eventName: "OpenFulfillment",
            logs: fullfillmentReceipt.logs,
        });
        utils.sheet_add_aoa(worksheet, [[fulfillmentLogs[0].args.randomness.toString()]], { origin: -1 });
        writeFile(workbook, filePath, { bookType: "xls" });
    }
}

run();