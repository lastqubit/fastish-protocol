// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CUSTODY_KEY, HostAmount, ROUTE_KEY} from "../Schema.sol";
import {Blocks, BlockRef, Data, DataRef, Writers, Writer} from "../Blocks.sol";

using Blocks for BlockRef;
using Data for DataRef;
using Writers for Writer;

abstract contract MapCustody {
    function mapCustody(bytes32 account, HostAmount memory custody) internal virtual returns (HostAmount memory out);

    function mapCustodies(bytes calldata state, uint i, bytes32 account) internal returns (bytes memory) {
        (Writer memory writer, uint end) = Writers.allocCustodiesFrom(state, i, CUSTODY_KEY);

        while (i < end) {
            BlockRef memory ref = Blocks.custodyFrom(state, i);
            HostAmount memory custody = ref.toCustodyValue(state);
            HostAmount memory out = mapCustody(account, custody);
            if (out.amount > 0) writer.appendCustody(out);
            i = ref.end;
        }

        return writer.finish();
    }
}

abstract contract MapCustodyWithRequestRoute {
    function mapCustodyWithRequestRoute(
        bytes32 account,
        HostAmount memory custody,
        DataRef memory rawRoute
    ) internal virtual returns (HostAmount memory out);

    function mapCustodiesWithRequestRoutes(
        bytes calldata state,
        bytes calldata request,
        uint i,
        uint q,
        bytes32 account
    ) internal returns (bytes memory) {
        (Writer memory writer, uint end) = Writers.allocCustodiesFrom(state, i, CUSTODY_KEY);

        while (i < end) {
            DataRef memory route;
            (route, q) = Data.routeFrom(request, q);
            BlockRef memory ref = Blocks.custodyFrom(state, i);
            HostAmount memory custody = ref.toCustodyValue(state);
            HostAmount memory out = mapCustodyWithRequestRoute(account, custody, route);
            if (out.amount > 0) writer.appendCustody(out);
            i = ref.end;
        }

        return writer.finish();
    }
}
