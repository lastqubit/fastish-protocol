// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Host } from "../core/Host.sol";
import { BorrowAgainstCustodyToBalance } from "../commands/Borrow.sol";
import { AssetAmount, HostAmount } from "../blocks/Schema.sol";
import { Block, Cursor } from "../Blocks.sol";
import { Blocks } from "../blocks/Blocks.sol";
import { Ids } from "../utils/Ids.sol";

using Blocks for Block;
using Blocks for Cursor;

contract TestBorrowHost is Host, BorrowAgainstCustodyToBalance {
    event BorrowCalled(bytes32 account, bytes32 asset, bytes32 meta, uint amount, bytes inputData);

    bytes32 public returnAsset;
    bytes32 public returnMeta;
    uint public returnAmount;

    constructor(address cmdr) Host(address(0), 1, "test") BorrowAgainstCustodyToBalance("") {
        if (cmdr != address(0)) access(Ids.toHost(cmdr), true);
    }

    function setReturn(bytes32 asset, bytes32 meta, uint amount) external {
        returnAsset = asset;
        returnMeta = meta;
        returnAmount = amount;
    }

    function borrowAgainstCustodyToBalance(
        bytes32 account,
        HostAmount memory custody,
        Cursor memory input
    ) internal override returns (AssetAmount memory) {
        if (input.i < input.end) {
            Block memory ref = Blocks.at(input.i);
            emit BorrowCalled(account, custody.asset, custody.meta, custody.amount, msg.data[ref.i:ref.bound]);
        } else {
            emit BorrowCalled(account, custody.asset, custody.meta, custody.amount, "");
        }
        return AssetAmount({asset: returnAsset, meta: returnMeta, amount: returnAmount});
    }

    function getBorrowId() external view returns (uint) {
        return borrowAgainstCustodyToBalanceId;
    }

    function getAdminAccount() external view returns (bytes32) {
        return adminAccount;
    }
}
