// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {Layout} from "./Layout.sol";
import {isLocalFamily, matchesBase, toLocalBase} from "./Utils.sol";

library Ids {
    error InvalidId();

    uint24 constant Node = (uint24(Layout.Evm32) << 8) | uint24(Layout.Node);
    uint32 constant Host = (uint32(Layout.Evm32) << 16) | (uint32(Layout.Node) << 8) | uint32(Layout.Host);
    uint32 constant Command = (uint32(Layout.Evm32) << 16) | (uint32(Layout.Node) << 8) | uint32(Layout.Command);
    uint32 constant Peer = (uint32(Layout.Evm32) << 16) | (uint32(Layout.Node) << 8) | uint32(Layout.Peer);

    function isHost(uint id) internal pure returns (bool) {
        return uint32(id >> 224) == Host;
    }

    function isCommand(uint id) internal pure returns (bool) {
        return uint32(id >> 224) == Command;
    }

    function isPeer(uint id) internal pure returns (bool) {
        return uint32(id >> 224) == Peer;
    }

    function command(uint id) internal pure returns (uint cid) {
        if (!isCommand(id)) revert InvalidId();
        return id;
    }

    function host(uint id, address target) internal view returns (uint hid) {
        if (id != toHost(target)) revert InvalidId();
        return id;
    }

    function toHost(address target) internal view returns (uint) {
        return toLocalBase(Host) | uint(uint160(target));
    }

    function toCommand(bytes4 selector, address target) internal view returns (uint) {
        uint id = toLocalBase(Command) | uint(uint160(target));
        id |= uint(uint32(selector)) << 160;
        return id;
    }

    function toPeer(bytes4 selector, address target) internal view returns (uint) {
        uint id = toLocalBase(Peer) | uint(uint160(target));
        id |= uint(uint32(selector)) << 160;
        return id;
    }

    function nodeAddr(uint id) internal view returns (address) {
        if (!isLocalFamily(id, Node)) revert InvalidId();
        return address(uint160(id));
    }

    function hostAddr(uint id) internal view returns (address) {
        if (!matchesBase(bytes32(id), toLocalBase(Host))) revert InvalidId();
        return address(uint160(id));
    }
}

library Selectors {
    string constant CommandArgs = "((uint256,bytes32,bytes,bytes))";
    string constant PeerArgs = "(bytes)";

    function command(string memory name) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes.concat(bytes(name), bytes(CommandArgs))));
    }

    function peer(string memory name) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes.concat(bytes(name), bytes(PeerArgs))));
    }
}



