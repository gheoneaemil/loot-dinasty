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
    const prizes = [
        BigInt(0), BigInt(50), BigInt(110), 
        BigInt(180), BigInt(260), BigInt(350), 
        BigInt(450), BigInt(550), BigInt(650), 
        BigInt(750), BigInt(850), BigInt(950), 
        BigInt(1050), BigInt(1150), BigInt(1250), 
        BigInt(1350), BigInt(1450), BigInt(1550), 
        BigInt(1650), BigInt(1750), BigInt(1850), 
        BigInt(1950), BigInt(2050), BigInt(2150),
        BigInt(2350), BigInt(2550), BigInt(3050),
        BigInt(4050), BigInt(5050), BigInt(7050),
        BigInt(11050), BigInt(14050), BigInt(15050),
        BigInt(16050), BigInt(16550), BigInt(17050), 
        BigInt(18050), BigInt(20050), BigInt(22050),
        BigInt(24050), BigInt(27050), BigInt(31050), 
        BigInt(36050), BigInt(56050), BigInt(66050), 
        BigInt(76050), BigInt(96050), BigInt(126050), 
        BigInt(156050), BigInt(210000), BigInt(1000000)
    ];
    const prices = prizes.map(_ => BigInt(100));
    prices.pop();

    await LootKingdom.write.setPack([0, {
        token: address0x0,
        editable: false,
        prizes,
        prices,
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