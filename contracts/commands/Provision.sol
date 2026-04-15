// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {CommandContext, CommandBase, CommandPayable, State} from "./Base.sol";
import {Cursors, Cur, HostAmount, Schemas, Writer, Writers} from "../Cursors.sol";
import {Budget, Values} from "../utils/Value.sol";
using Cursors for Cur;
using Writers for Writer;

string constant PROVISION = "provision";
string constant PP = "provisionPayable";
string constant PFB = "provisionFromBalance";

/// @notice Shared provision hook used by both `Provision` and `ProvisionFromBalance`.
abstract contract ProvisionHook {
    /// @notice Override to send or provision a custody value.
    /// Called once per provisioned asset. Implementations should perform only the
    /// side effect (e.g. transfer or record); output blocks are written by the caller.
    /// @param account Caller's account identifier.
    /// @param custody Destination host plus asset amount to provision.
    function provision(bytes32 account, HostAmount memory custody) internal virtual;
}

/// @notice Shared provision hook used by `ProvisionPayable`.
abstract contract ProvisionPayableHook {
    /// @notice Override to send or provision a custody value.
    /// Called once per provisioned asset. Implementations should perform only the
    /// side effect (e.g. transfer or record); output blocks are written by the caller.
    /// @param account Caller's account identifier.
    /// @param custody Destination host plus asset amount to provision.
    /// @param budget Mutable native-value budget drawn from `msg.value`.
    function provision(
        bytes32 account,
        HostAmount memory custody,
        Budget memory budget
    ) internal virtual;
}

/// @title Provision
/// @notice Command that provisions assets to remote hosts from CUSTODY request blocks.
/// Each request block supplies the target host plus an asset amount; the output is a CUSTODY state stream.
abstract contract Provision is CommandBase, ProvisionHook {
    uint internal immutable provisionId = commandId(PROVISION);

    constructor() {
        emit Command(host, PROVISION, Schemas.Custody, provisionId, State.Empty, State.Custodies, false);
    }

    function provision(
        CommandContext calldata c
    ) external onlyCommand(provisionId, c.target) returns (bytes memory) {
        (Cur memory request, uint count, ) = cursor(c.request, 1);
        Writer memory writer = Writers.allocCustodies(count);

        while (request.i < request.bound) {
            HostAmount memory custody = request.unpackCustodyValue();
            provision(c.account, custody);
            writer.appendCustody(custody);
        }

        return request.complete(writer);
    }
}

/// @title ProvisionPayable
/// @notice Command that provisions assets to remote hosts from CUSTODY request blocks.
/// Each request block supplies the target host plus an asset amount; the output is a CUSTODY state stream.
/// The hook receives a mutable native-value budget drawn from `msg.value`.
abstract contract ProvisionPayable is CommandPayable, ProvisionPayableHook {
    uint internal immutable provisionPayableId = commandId(PP);

    constructor() {
        emit Command(host, PP, Schemas.Custody, provisionPayableId, State.Empty, State.Custodies, true);
    }

    function provisionPayable(
        CommandContext calldata c
    ) external payable onlyCommand(provisionPayableId, c.target) returns (bytes memory) {
        (Cur memory request, uint count, ) = cursor(c.request, 1);
        Writer memory writer = Writers.allocCustodies(count);
        Budget memory budget = Values.fromMsg();

        while (request.i < request.bound) {
            HostAmount memory custody = request.unpackCustodyValue();
            provision(c.account, custody, budget);
            writer.appendCustody(custody);
        }

        settleValue(c.account, budget);
        return request.complete(writer);
    }
}

/// @title ProvisionFromBalance
/// @notice Command that converts BALANCE state into CUSTODY state for a destination host.
/// The destination node is read from an optional NODE trailing block; reverts if absent.
abstract contract ProvisionFromBalance is CommandBase, ProvisionHook {
    uint internal immutable provisionFromBalanceId = commandId(PFB);

    constructor() {
        emit Command(host, PFB, Schemas.Node, provisionFromBalanceId, State.Balances, State.Custodies, false);
    }

    function provisionFromBalance(
        CommandContext calldata c
    ) external onlyCommand(provisionFromBalanceId, c.target) returns (bytes memory) {
        (Cur memory state, uint stateCount, ) = cursor(c.state, 1);
        Cur memory request = cursor(c.request);
        Writer memory writer = Writers.allocCustodies(stateCount);
        uint toHost = request.nodeAfter(0);
        if (toHost == 0) revert Cursors.ZeroNode();

        while (state.i < state.bound) {
            (bytes32 asset, bytes32 meta, uint amount) = state.unpackBalance();
            HostAmount memory custody = HostAmount(toHost, asset, meta, amount);
            provision(c.account, custody);
            writer.appendCustody(custody);
        }

        return state.complete(writer);
    }
}

