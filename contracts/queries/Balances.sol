// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {Cur, Cursors, Keys, Schemas, Writer, Writers} from "../Cursors.sol";
import {QueryBase} from "./Base.sol";

using Cursors for Cur;

string constant NAME = "getBalances";
string constant INPUT = "query(bytes32 account, bytes32 asset, bytes32 meta)";

abstract contract GetBalancesHook {
    /// @notice Resolve one account's balance for one supported asset.
    /// Concrete implementations define how assets are resolved.
    /// @param account Account identifier carried by the query payload.
    /// @param asset Requested asset identifier.
    /// @param meta Requested asset metadata slot.
    /// @return amount Current balance in the asset's native units.
    function getBalance(bytes32 account, bytes32 asset, bytes32 meta) internal view virtual returns (uint amount);
}

/// @title GetBalances
/// @notice Rootzero query that resolves balances for one or more `(account, asset, meta)` tuples.
/// The request is a run of `QUERY` blocks, each encoding `(bytes32 account, bytes32 asset, bytes32 meta)`.
/// The response returns one `BALANCE` block per query entry, preserving request order.
abstract contract GetBalances is QueryBase, GetBalancesHook {
    uint public immutable getBalancesId = queryId(NAME);

    constructor() {
        emit Query(host, NAME, INPUT, Schemas.Balance, getBalancesId);
    }

    /// @notice Resolve balances for a run of requested `(account, asset, meta)` tuples.
    /// @param request Block-stream request consisting of `query(account, asset, meta)*`.
    /// @return Block-stream response containing one `balance(asset, meta, amount)` per query block.
    function getBalances(bytes calldata request) external view returns (bytes memory) {
        (Cur memory query, uint count, ) = cursor(request, 1);
        Writer memory response = Writers.allocBalances(count);

        while (query.i < query.bound) {
            (bytes32 account, bytes32 asset, bytes32 meta) = query.unpack96(Keys.Query);
            uint balance = getBalance(account, asset, meta);
            Writers.appendBalance(response, asset, meta, balance);
        }

        return query.complete(response);
    }
}
