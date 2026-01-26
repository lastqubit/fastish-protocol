// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {AccessControl} from "./Access.sol";
import {AccessEvent} from "./Events/Node/Access.sol";
import {EndpointEvent} from "./Events/Node/Endpoint.sol";
import {toValueId, toHostId, toEndpointId} from "./Utils.sol";

abstract contract Host is AccessControl, AccessEvent, EndpointEvent {
    uint public immutable hostId = toHostId(address(this));
    uint public immutable valueId = toValueId();

    error FailedCall(address addr, bytes4 selector, bytes err);

    function toEid(bytes4 selector) internal view returns (uint) {
        return toEndpointId(address(this), selector);
    }

    function access(address addr, bool allow) internal {
        authorized[addr] = allow;
        emit Access(hostId, addr, allow);
    }

    function callTo(address addr, uint value, bytes memory data) internal returns (bytes memory out) {
        bool success;
        (success, out) = payable(ensureTrusted(addr)).call{value: value}(data);
        if (success == false) {
            revert FailedCall(addr, bytes4(data), out);
        }
    }
}
