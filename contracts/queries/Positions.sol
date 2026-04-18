// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {Cur, Cursors, Writer, Writers, Keys} from "../Cursors.sol";
import {Schemas} from "../blocks/Schema.sol";
import {QueryBase} from "./Base.sol";

using Cursors for Cur;

string constant NAME = "getAssetPosition";

/// @title PositionsQuery
/// @notice Rootzero query that resolves one dynamic position response for each requested asset tuple.
/// The request is a run of `ASSET` blocks.
/// The response returns one dynamic `RESPONSE` block per asset entry, preserving request order.
abstract contract AssetPosition is QueryBase {
    uint public immutable getAssetPositionId = queryId(NAME);
    uint internal immutable positionResponseSize;

    constructor(string memory output, uint responseSize) {
        positionResponseSize = responseSize;
        emit Query(host, NAME, Schemas.Asset, output, getAssetPositionId);
    }

    /// @notice Resolve the position payload for one requested asset tuple.
    /// Concrete implementations must append exactly one `RESPONSE` block whose payload
    /// length matches `positionResponseSize`.
    /// @param asset Requested asset identifier.
    /// @param meta Requested asset metadata slot.
    /// @param response Destination writer for the response stream.
    function appendAssetPosition(bytes32 asset, bytes32 meta, Writer memory response) internal view virtual;

    /// @notice Resolve positions for a run of requested `(asset, meta)` tuples.
    /// @dev Allocates from the configured fixed response payload length so each hook call
    ///      can append one `RESPONSE` block directly into the output stream.
    /// @param request Block-stream request consisting of `asset(asset, meta)*`.
    /// @return Block-stream response containing one `response(bytes data)` block per asset block.
    function getAssetPosition(bytes calldata request) external view returns (bytes memory) {
        (Cur memory query, uint count, ) = cursor(request, 1);
        Writer memory response = Writers.allocBytes(count, positionResponseSize);

        while (query.i < query.bound) {
            (bytes32 asset, bytes32 meta) = query.unpackAsset();
            appendAssetPosition(asset, meta, response);
        }

        return query.complete(response);
    }
}
