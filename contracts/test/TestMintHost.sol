// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Host } from "../core/Host.sol";
import { MintToBalances } from "../commands/Mint.sol";
import { Blocks, Block, Cursor, Writer } from "../Blocks.sol";
import { Writers } from "../blocks/Writers.sol";
import { Ids } from "../utils/Ids.sol";

using Blocks for Block;
using Blocks for Cursor;
using Writers for Writer;

contract TestMintHost is Host, MintToBalances {
    event MintCalled(bytes32 account, bytes inputData);

    bytes32 public returnAsset;
    bytes32 public returnMeta;
    uint    public returnAmount;

    constructor(address cmdr)
        Host(address(0), 1, "test")
        MintToBalances("", 10_000)
    {
        if (cmdr != address(0)) access(Ids.toHost(cmdr), true);
    }

    function setReturn(bytes32 asset, bytes32 meta, uint amount) external {
        returnAsset = asset;
        returnMeta  = meta;
        returnAmount = amount;
    }

    function mintToBalances(bytes32 account, Cursor memory input, Writer memory out) internal override {
        Block memory ref = Blocks.at(input.i);
        bytes calldata inputData = msg.data[ref.i:ref.bound];
        emit MintCalled(account, inputData);
        if (returnAmount > 0) out.appendBalance(returnAsset, returnMeta, returnAmount);
    }

    function getMintId() external view returns (uint) { return mintToBalancesId; }
    function getAdminAccount() external view returns (bytes32) { return adminAccount; }
}
