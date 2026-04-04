// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Host } from "../core/Host.sol";
import { SwapExactBalanceToBalance } from "../commands/Swap.sol";
import { AssetAmount, Block, Cursor, Blocks, Keys } from "../Blocks.sol";

using Blocks for Block;
using Blocks for Cursor;

contract TestSwapHost is Host, SwapExactBalanceToBalance {
    event SwapMapped(bytes32 account, bytes32 asset, bytes32 meta, uint amount, bytes inputData);
    event SwapMinimum(bytes32 asset, bytes32 meta, uint amount);

    constructor(address rootzero)
        Host(rootzero, 1, "test")
        SwapExactBalanceToBalance("route(bytes data)")
    {}

    function swapExactBalanceToBalance(
        bytes32 account,
        AssetAmount memory balance,
        Cursor memory input
    ) internal override returns (AssetAmount memory out) {
        if (input.i == input.end) revert Blocks.InvalidBlock();

        Block memory ref = Blocks.at(input.i);
        bytes calldata inputData = msg.data[ref.i:ref.end];
        emit SwapMapped(account, balance.asset, balance.meta, balance.amount, inputData);

        Cursor memory cur = input;
        if (cur.isAt(Keys.Route)) cur.unpackRoute();
        if (cur.i < cur.end && cur.isAt(Keys.Minimum)) {
            (bytes32 minAsset, bytes32 minMeta, uint minAmount) = cur.unpackMinimum();
            emit SwapMinimum(minAsset, minMeta, minAmount);
        }

        return AssetAmount({
            asset: balance.asset,
            meta: bytes32(inputData.length),
            amount: balance.amount + inputData.length
        });
    }

    function getSwapExactInAsset32Id() external view returns (uint) {
        return swapExactBalanceToBalanceId;
    }

    function getAdminAccount() external view returns (bytes32) {
        return adminAccount;
    }
}
