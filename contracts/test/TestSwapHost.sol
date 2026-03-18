// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Host} from "../core/Host.sol";
import {SwapExactIn} from "../commands/Swap.sol";
import {AssetAmount, DataRef} from "../blocks/Schema.sol";

contract TestSwapHost is Host, SwapExactIn {
    event SwapMapped(bytes32 account, bytes32 asset, bytes32 meta, uint amount, bytes routeData);

    constructor(address rush)
        Host(rush, 1, "test")
        SwapExactIn("route(bytes data)")
    {}

    function mapBalanceWithRequestRoute(
        bytes32 account,
        AssetAmount memory balance,
        DataRef memory rawRoute
    ) internal override returns (AssetAmount memory out) {
        bytes calldata routeData = msg.data[rawRoute.i:rawRoute.bound];
        emit SwapMapped(account, balance.asset, balance.meta, balance.amount, routeData);
        return AssetAmount({
            asset: balance.asset,
            meta: bytes32(rawRoute.bound - rawRoute.i),
            amount: balance.amount + (rawRoute.bound - rawRoute.i)
        });
    }

    function getSwapExactInAsset32Id() external view returns (uint) {
        return swapExactInId;
    }

    function getAdminAccount() external view returns (bytes32) {
        return adminAccount;
    }
}
