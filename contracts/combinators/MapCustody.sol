// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandBase} from "../commands/Base.sol";
import {BlockRef, CUSTODY_KEY, DataRef, HostAmount, ROUTE_KEY, Writer} from "../blocks/Schema.sol";
import {Blocks, Data} from "../blocks/Readers.sol";
import {Writers} from "../blocks/Writers.sol";

using Blocks for BlockRef;
using Data for DataRef;
using Writers for Writer;

abstract contract MapCustody is CommandBase {
    function mapCustody(bytes32 account, HostAmount memory custody) internal virtual returns (bool keep, HostAmount memory out);

    function mapCustodies(bytes calldata state, uint i, bytes32 account) internal returns (bytes memory) {
        (Writer memory writer, uint next) = Writers.allocCustodiesFrom(state, i, CUSTODY_KEY);

        while (i < next) {
            BlockRef memory ref = Blocks.custodyFrom(state, i);
            HostAmount memory custody = ref.toCustodyValue(state);
            (bool keep, HostAmount memory out) = mapCustody(account, custody);
            if (keep) writer.appendCustody(out);
            i = ref.end;
        }

        return writer.finish();
    }
}

abstract contract MapCustodyWithRequestRoute is CommandBase {
    function mapCustodyWithRequestRoute(
        bytes32 account,
        HostAmount memory custody,
        DataRef memory rawRoute
    ) internal virtual returns (bool keep, HostAmount memory out);

    function mapCustodiesWithRequestRoutes(
        bytes calldata state,
        bytes calldata request,
        uint i,
        uint q,
        bytes32 account
    ) internal returns (bytes memory) {
        (Writer memory writer, uint next) = Writers.allocCustodiesFrom(state, i, CUSTODY_KEY);

        while (i < next) {
            BlockRef memory ref = Blocks.custodyFrom(state, i);
            DataRef memory rawRoute;
            (rawRoute, q) = Data.routeFrom(request, q);
            HostAmount memory custody = ref.toCustodyValue(state);
            (bool keep, HostAmount memory out) = mapCustodyWithRequestRoute(account, custody, rawRoute);
            if (keep) writer.appendCustody(out);
            i = ref.end;
        }

        return writer.finish();
    }
}
