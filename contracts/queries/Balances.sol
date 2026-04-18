// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {Cur, Cursors, Writer, Writers} from "../Cursors.sol";
import {QueryBase} from "./Base.sol";

using Cursors for Cur;

string constant NAME = "getBalances";
string constant INPUT = "query(bytes32 account, bytes32 asset, bytes32 meta)";
string constant OUTPUT = "balance(bytes32 asset, bytes32 meta, uint amount)";

/// @title BalancesQuery
/// @notice Rootzero query that resolves balances for one or more `(account, asset, meta)` tuples.
/// The request is a run of `QUERY` blocks, each encoding `(bytes32 account, bytes32 asset, bytes32 meta)`.
/// The response returns one `BALANCE` block per query entry, preserving request order.
abstract contract BalancesQuery is QueryBase {
    uint public immutable getBalancesId = queryId(NAME);

    constructor() {
        emit Query(host, NAME, INPUT, OUTPUT, getBalancesId);
    }

    /// @notice Resolve one account's balance for one supported asset.
    /// Concrete implementations define how assets are resolved.
    /// @param account Account identifier carried by the query payload.
    /// @param asset Requested asset identifier.
    /// @param meta Requested asset metadata slot.
    /// @return amount Current balance in the asset's native units.
    function balanceOf(bytes32 account, bytes32 asset, bytes32 meta) internal view virtual returns (uint amount);

    /// @notice Resolve balances for a run of requested `(account, asset, meta)` tuples.
    /// @param request Block-stream request consisting of `query(account, asset, meta)*`.
    /// @return Block-stream response containing one `balance(asset, meta, amount)` per query block.
    function getBalances(bytes calldata request) external view returns (bytes memory) {
        (Cur memory query, uint count, ) = cursor(request, 1);
        Writer memory response = Writers.allocBalances(count);

        while (query.i < query.bound) {
            (bytes32 account, bytes32 asset, bytes32 meta) = query.unpackQuery96();
            uint balance = balanceOf(account, asset, meta);
            Writers.appendBalance(response, asset, meta, balance);
        }

        return query.complete(response);
    }
}
