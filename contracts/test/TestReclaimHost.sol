// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Host } from "../core/Host.sol";
import { ReclaimToBalances } from "../commands/Reclaim.sol";
import { AssetAmount, Block, Cursor, Writer } from "../Blocks.sol";
import { Blocks } from "../blocks/Blocks.sol";
import { Writers } from "../blocks/Writers.sol";
import { Ids } from "../utils/Ids.sol";

using Blocks for Block;
using Blocks for Cursor;
using Writers for Writer;

contract TestReclaimHost is Host, ReclaimToBalances {
    event ReclaimCalled(bytes32 account, bytes32 asset, bytes32 meta, uint amount, bytes inputData);

    bytes32 public returnAsset;
    bytes32 public returnMeta;
    uint    public returnAmount;

    constructor(address cmdr)
        Host(address(0), 1, "test")
        ReclaimToBalances("", 10_000)
    {
        if (cmdr != address(0)) access(Ids.toHost(cmdr), true);
    }

    function setReturn(bytes32 asset, bytes32 meta, uint amount) external {
        returnAsset = asset;
        returnMeta  = meta;
        returnAmount = amount;
    }

    function reclaimToBalances(
        bytes32 account,
        Cursor memory input,
        Writer memory out
    ) internal override {
        Block memory ref = Blocks.at(input.i);
        Cursor memory inner = Blocks.cursorFrom(msg.data[ref.bound:ref.end], 0);
        (bytes32 asset, bytes32 meta, uint amount_) = inner.unpackAmount();
        bytes calldata inputData = msg.data[ref.i:ref.bound];
        emit ReclaimCalled(account, asset, meta, amount_, inputData);
        if (returnAmount > 0) out.appendBalance(returnAsset, returnMeta, returnAmount);
    }

    function getReclaimBalanceId() external view returns (uint) { return reclaimToBalancesId; }
    function getAdminAccount() external view returns (bytes32) { return adminAccount; }
}
