// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

library Keys {
    bytes4 constant AMOUNT = bytes4(keccak256("amount(bytes32 asset, bytes32 meta, uint amount)"));
    bytes4 constant BALANCE = bytes4(keccak256("balance(bytes32 asset, bytes32 meta, uint amount)"));
    bytes4 constant CUSTODY = bytes4(keccak256("custody(uint host, bytes32 asset, bytes32 meta, uint amount)"));
    bytes4 constant MINIMUM = bytes4(keccak256("minimum(bytes32 asset, bytes32 meta, uint amount)"));
    bytes4 constant MAXIMUM = bytes4(keccak256("maximum(bytes32 asset, bytes32 meta, uint amount)"));
    bytes4 constant ROUTE = bytes4(keccak256("route(bytes data)"));
    bytes4 constant QUANTITY = bytes4(keccak256("quantity(uint amount)"));
    bytes4 constant RATE = bytes4(keccak256("rate(uint value)"));
    bytes4 constant PARTY = bytes4(keccak256("party(bytes32 account)"));
    bytes4 constant RECIPIENT = bytes4(keccak256("recipient(bytes32 account)"));
    bytes4 constant TX = bytes4(keccak256("tx(bytes32 from, bytes32 to, bytes32 asset, bytes32 meta, uint amount)"));
    bytes4 constant STEP = bytes4(keccak256("step(uint target, uint value, bytes request)"));
    bytes4 constant AUTH = bytes4(keccak256("auth(uint cid, uint deadline, bytes proof)"));
    bytes4 constant ASSET = bytes4(keccak256("asset(bytes32 asset, bytes32 meta)"));
    bytes4 constant NODE = bytes4(keccak256("node(uint id)"));
    bytes4 constant LISTING = bytes4(keccak256("listing(uint host, bytes32 asset, bytes32 meta)"));
    bytes4 constant FUNDING = bytes4(keccak256("funding(uint host, uint amount)"));
    bytes4 constant ALLOCATION = bytes4(keccak256("allocation(uint host, bytes32 asset, bytes32 meta, uint amount)"));
    bytes4 constant BOUNTY = bytes4(keccak256("bounty(uint amount, bytes32 relayer)"));
}
