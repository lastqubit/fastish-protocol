// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {AUTH_PROOF_LEN, AUTH_TOTAL_LEN, HostAsset, AssetAmount, HostAmount, Tx, Keys} from "./Schema.sol";
import {BALANCE_BLOCK_LEN, BOUNTY_BLOCK_LEN, CUSTODY_BLOCK_LEN, TX_BLOCK_LEN, Writer, Writers} from "./Writers.sol";

struct Block {
    bytes4 key;
    uint i;
    uint bound;
    uint end;
    uint cursor;
}

struct Cursor {
    uint start;
    uint i;
    uint end;
    uint cursor;
}

using Blocks for Block;
using Blocks for Cursor;

library Blocks {
    error MalformedBlocks();
    error InvalidBlock();
    error ZeroRecipient();
    error ZeroNode();
    error UnexpectedValue();

    // ── infrastructure ────────────────────────────────────────────────────────

    function at(uint i) internal pure returns (Block memory ref) {
        uint eod = msg.data.length;
        if (i == eod) return Block(bytes4(0), 0, 0, i, i);
        if (i > eod) revert MalformedBlocks();

        unchecked {
            ref.i = i + 12;
        }
        if (ref.i > eod) revert MalformedBlocks();
        ref.key = bytes4(msg.data[i:i + 4]);
        ref.bound = ref.i + uint32(bytes4(msg.data[i + 4:i + 8]));
        ref.end = ref.i + uint32(bytes4(msg.data[i + 8:ref.i]));

        if (ref.bound > ref.end || ref.end > eod) revert MalformedBlocks();
    }

    function from(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        uint base;
        uint eod = source.length;
        assembly ("memory-safe") {
            base := source.offset
        }

        if (i == eod) return Block(bytes4(0), 0, 0, base + i, i);
        if (i > eod) revert MalformedBlocks();

        uint start;
        unchecked {
            start = i + 12;
        }
        if (start > eod) revert MalformedBlocks();

        ref.key = bytes4(source[i:i + 4]);
        ref.i = base + start;
        ref.bound = ref.i + uint32(bytes4(source[i + 4:i + 8]));
        ref.end = ref.i + uint32(bytes4(source[i + 8:start]));
        ref.cursor = i + (ref.end - ref.i) + 12;

        uint eos = base + eod;
        if (ref.bound > ref.end || ref.end > eos) revert MalformedBlocks();
    }

    function expect(
        Cursor memory cur,
        bytes4 key,
        uint min,
        uint max
    ) internal pure returns (uint i, uint bound, uint end) {
        if (cur.i + 12 > cur.end) revert MalformedBlocks();
        if (bytes4(msg.data[cur.i:cur.i + 4]) != key) revert InvalidBlock();

        unchecked {
            i = cur.i + 12;
        }
        bound = i + uint32(bytes4(msg.data[cur.i + 4:cur.i + 8]));
        end = i + uint32(bytes4(msg.data[cur.i + 8:i]));

        if (bound > end || end > cur.end) revert MalformedBlocks();

        uint len = bound - i;
        if (len < min || (max != 0 && len > max)) revert InvalidBlock();
        cur.i = end;
    }

    function cursorFrom(bytes calldata source, uint i) internal pure returns (Cursor memory cur) {
        uint base;
        assembly ("memory-safe") {
            base := source.offset
        }
        Block memory ref = from(source, i);
        cur.start = ref.key == Keys.Bundle ? ref.i : base + i;
        cur.end = ref.end;
        cur.cursor = ref.cursor;
        cur.i = cur.start;
    }

    function cursorFrom(bytes calldata source, uint i, uint n) internal pure returns (Cursor memory cur) {
        if (n == 0) revert InvalidBlock();

        uint next = i;
        for (uint j; j < n; ) {
            next = from(source, next).cursor;
            unchecked {
                ++j;
            }
        }

        uint base;
        assembly ("memory-safe") {
            base := source.offset
        }

        cur.start = base + i;
        cur.i = cur.start;
        cur.end = base + next;
        cur.cursor = next;
    }

    function streamFrom(bytes calldata source, uint i) internal pure returns (Cursor memory cur) {
        uint base;
        uint end = source.length;
        assembly ("memory-safe") {
            base := source.offset
        }
        if (i > end) revert MalformedBlocks();
        cur.start = base + i;
        cur.i = cur.start;
        cur.end = base + end;
        cur.cursor = end;
    }

    function take(Cursor memory cur) internal pure returns (Cursor memory out) {
        Block memory ref = at(cur.i);
        if (ref.end > cur.end) revert MalformedBlocks();

        uint base = cur.end - cur.cursor;
        out.start = ref.key == Keys.Bundle ? ref.i : cur.i;
        out.i = out.start;
        out.end = ref.end;
        out.cursor = ref.end - base;

        cur.i = ref.end;
    }

    function matchingFrom(bytes calldata source, uint i, bytes4 key) internal pure returns (Cursor memory cur, uint count_) {
        uint cursor_;
        (count_, cursor_) = count(source, i, key);
        cur = streamFrom(source, i);
        uint base;
        assembly ("memory-safe") {
            base := source.offset
        }
        cur.end = base + cursor_;
        cur.cursor = cursor_;
    }

    function allFrom(bytes calldata source, uint i) internal pure returns (Cursor memory cur, uint count_) {
        uint cursor_;
        (count_, cursor_) = count(source, i);
        cur = streamFrom(source, i);
        uint base;
        assembly ("memory-safe") {
            base := source.offset
        }
        cur.end = base + cursor_;
        cur.cursor = cursor_;
    }

    function count(bytes calldata source, uint i, bytes4 key) internal pure returns (uint total, uint cursor) {
        cursor = i;
        while (cursor < source.length) {
            Block memory ref = from(source, cursor);
            if (ref.key != key) break;
            unchecked {
                ++total;
            }
            cursor = ref.cursor;
        }
    }

    function count(bytes calldata source, uint i) internal pure returns (uint total, uint cursor) {
        cursor = i;
        while (cursor < source.length) {
            cursor = from(source, cursor).cursor;
            unchecked {
                ++total;
            }
        }
    }

    function isAt(Cursor memory cur, bytes4 key) internal pure returns (bool) {
        if (cur.i + 4 > cur.end) return false;
        return bytes4(msg.data[cur.i:cur.i + 4]) == key;
    }

    function findFrom(bytes calldata source, uint i, uint limit, bytes4 key) internal pure returns (Block memory ref) {
        if (limit > source.length) revert MalformedBlocks();
        while (i < limit) {
            ref = from(source, i);
            if (ref.cursor > limit) revert MalformedBlocks();
            if (ref.key == key) return ref;
            i = ref.cursor;
        }

        return Block(bytes4(0), limit, limit, limit, limit);
    }

    function create32(bytes4 key, bytes32 value) internal pure returns (bytes memory) {
        return bytes.concat(key, bytes4(uint32(0x20)), bytes4(uint32(0x20)), value);
    }

    function create64(bytes4 key, bytes32 a, bytes32 b) internal pure returns (bytes memory) {
        return bytes.concat(key, bytes4(uint32(0x40)), bytes4(uint32(0x40)), a, b);
    }

    function create96(bytes4 key, bytes32 a, bytes32 b, bytes32 c) internal pure returns (bytes memory) {
        return bytes.concat(key, bytes4(uint32(0x60)), bytes4(uint32(0x60)), a, b, c);
    }

    function create128(bytes4 key, bytes32 a, bytes32 b, bytes32 c, bytes32 d) internal pure returns (bytes memory) {
        return bytes.concat(key, bytes4(uint32(0x80)), bytes4(uint32(0x80)), a, b, c, d);
    }

    function toBountyBlock(uint bounty, bytes32 relayer) internal pure returns (bytes memory) {
        return create64(Keys.Bounty, bytes32(bounty), relayer);
    }

    function toBalanceBlock(bytes32 asset, bytes32 meta, uint amount) internal pure returns (bytes memory) {
        return create96(Keys.Balance, asset, meta, bytes32(amount));
    }

    function toCustodyBlock(uint host, bytes32 asset, bytes32 meta, uint amount) internal pure returns (bytes memory) {
        return create128(Keys.Custody, bytes32(host), asset, meta, bytes32(amount));
    }

    function resolveRecipient(
        bytes calldata source,
        uint i,
        uint limit,
        bytes32 backup
    ) internal pure returns (bytes32) {
        Block memory ref = findFrom(source, i, limit, Keys.Recipient);
        bytes32 to = ref.key != 0 ? ref.unpackRecipient() : backup;
        if (to == 0) revert ZeroRecipient();
        return to;
    }

    function resolveNode(bytes calldata source, uint i, uint limit, uint backup) internal pure returns (uint) {
        Block memory ref = findFrom(source, i, limit, Keys.Node);
        uint node = ref.key != 0 ? ref.unpackNode() : backup;
        if (node == 0) revert ZeroNode();
        return node;
    }

    function resolveAuth(
        Cursor memory input,
        uint expectedCid
    ) internal pure returns (bytes32 hash, uint deadline, bytes calldata proof) {
        if (input.end - input.i < AUTH_TOTAL_LEN) revert MalformedBlocks();

        uint authStart = input.end - AUTH_TOTAL_LEN;
        Block memory auth = at(authStart);
        if (auth.end != input.end) revert MalformedBlocks();

        (deadline, proof) = auth.expectAuth(expectedCid);

        hash = keccak256(msg.data[input.i:input.end - AUTH_PROOF_LEN]);
    }

    function ensure(Block memory ref, bytes4 key) internal pure {
        if (key == 0 || key != ref.key) revert InvalidBlock();
    }

    function ensure(Block memory ref, bytes4 key, uint len) internal pure {
        if (key == 0 || key != ref.key || len != (ref.bound - ref.i)) revert InvalidBlock();
    }

    function ensure(Block memory ref, bytes4 key, uint min, uint max) internal pure {
        uint len = ref.bound - ref.i;
        if (key == 0 || key != ref.key || len < min || (max != 0 && len > max)) revert InvalidBlock();
    }

    // ── *From ─────────────────────────────────────────────────────────────────

    function routeFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Route);
    }

    function bundleFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Bundle);
    }

    function nodeFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Node, 32);
    }

    function recipientFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Recipient, 32);
    }

    function partyFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Party, 32);
    }

    function rateFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Rate, 32);
    }

    function quantityFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Quantity, 32);
    }

    function assetFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Asset, 64);
    }

    function fundingFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Funding, 64);
    }

    function bountyFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Bounty, 64);
    }

    function amountFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Amount, 96);
    }

    function balanceFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Balance, 96);
    }

    function minimumFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Minimum, 96);
    }

    function maximumFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Maximum, 96);
    }

    function listingFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Listing, 96);
    }

    function stepFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Step, 64, 0);
    }

    function authFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Auth, 149, 0);
    }

    function custodyFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Custody, 128);
    }

    function allocationFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Allocation, 128);
    }

    function txFrom(bytes calldata source, uint i) internal pure returns (Block memory ref) {
        ref = from(source, i);
        ensure(ref, Keys.Transaction, 160);
    }

    // ── inner* ────────────────────────────────────────────────────────────────

    // ── inner*At ──────────────────────────────────────────────────────────────

    // ── unpack* ───────────────────────────────────────────────────────────────

    function unpackRoute(Block memory ref) internal pure returns (bytes calldata data) {
        ensure(ref, Keys.Route);
        return msg.data[ref.i:ref.bound];
    }


    function unpackRouteUint(Block memory ref) internal pure returns (uint) {
        ensure(ref, Keys.Route, 32);
        return uint(bytes32(msg.data[ref.i:ref.i + 32]));
    }

    function unpackRoute2Uint(Block memory ref) internal pure returns (uint a, uint b) {
        ensure(ref, Keys.Route, 96);
        a = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        b = uint(bytes32(msg.data[ref.i + 32:ref.i + 64]));
    }

    function unpackRoute3Uint(Block memory ref) internal pure returns (uint a, uint b, uint c) {
        ensure(ref, Keys.Route, 96);
        a = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        b = uint(bytes32(msg.data[ref.i + 32:ref.i + 64]));
        c = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function unpackRoute32(Block memory ref) internal pure returns (bytes32) {
        ensure(ref, Keys.Route, 32);
        return bytes32(msg.data[ref.i:ref.i + 32]);
    }


    function unpackRoute64(Block memory ref) internal pure returns (bytes32 a, bytes32 b) {
        ensure(ref, Keys.Route, 64);
        a = bytes32(msg.data[ref.i:ref.i + 32]);
        b = bytes32(msg.data[ref.i + 32:ref.i + 64]);
    }

    function unpackRoute96(Block memory ref) internal pure returns (bytes32 a, bytes32 b, bytes32 c) {
        ensure(ref, Keys.Route, 96);
        a = bytes32(msg.data[ref.i:ref.i + 32]);
        b = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        c = bytes32(msg.data[ref.i + 64:ref.i + 96]);
    }

    function unpackNode(Block memory ref) internal pure returns (uint id) {
        ensure(ref, Keys.Node, 32);
        return uint(bytes32(msg.data[ref.i:ref.i + 32]));
    }


    function unpackRecipient(Block memory ref) internal pure returns (bytes32 account) {
        ensure(ref, Keys.Recipient, 32);
        return bytes32(msg.data[ref.i:ref.i + 32]);
    }


    function unpackParty(Block memory ref) internal pure returns (bytes32 account) {
        ensure(ref, Keys.Party, 32);
        return bytes32(msg.data[ref.i:ref.i + 32]);
    }

    function unpackRate(Block memory ref) internal pure returns (uint value) {
        ensure(ref, Keys.Rate, 32);
        return uint(bytes32(msg.data[ref.i:ref.i + 32]));
    }

    function unpackQuantity(Block memory ref) internal pure returns (uint amount) {
        ensure(ref, Keys.Quantity, 32);
        return uint(bytes32(msg.data[ref.i:ref.i + 32]));
    }

    function unpackAsset(Block memory ref) internal pure returns (bytes32 asset, bytes32 meta) {
        ensure(ref, Keys.Asset, 64);
        return (bytes32(msg.data[ref.i:ref.i + 32]), bytes32(msg.data[ref.i + 32:ref.i + 64]));
    }


    function unpackFunding(Block memory ref) internal pure returns (uint host, uint amount) {
        ensure(ref, Keys.Funding, 64);
        host = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        amount = uint(bytes32(msg.data[ref.i + 32:ref.i + 64]));
    }


    function unpackBounty(Block memory ref) internal pure returns (uint amount, bytes32 relayer) {
        ensure(ref, Keys.Bounty, 64);
        amount = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        relayer = bytes32(msg.data[ref.i + 32:ref.i + 64]);
    }

    function unpackAmount(Block memory ref) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, Keys.Amount, 96);
        asset = bytes32(msg.data[ref.i:ref.i + 32]);
        meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }


    function unpackBalance(Block memory ref) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, Keys.Balance, 96);
        asset = bytes32(msg.data[ref.i:ref.i + 32]);
        meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }


    function unpackMinimum(Block memory ref) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, Keys.Minimum, 96);
        asset = bytes32(msg.data[ref.i:ref.i + 32]);
        meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }


    function unpackMaximum(Block memory ref) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, Keys.Maximum, 96);
        asset = bytes32(msg.data[ref.i:ref.i + 32]);
        meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function unpackListing(Block memory ref) internal pure returns (uint host, bytes32 asset, bytes32 meta) {
        ensure(ref, Keys.Listing, 96);
        host = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        asset = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        meta = bytes32(msg.data[ref.i + 64:ref.i + 96]);
    }

    function unpackStep(Block memory ref) internal pure returns (uint target, uint value, bytes calldata req) {
        ensure(ref, Keys.Step, 64, 0);
        target = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        value = uint(bytes32(msg.data[ref.i + 32:ref.i + 64]));
        req = msg.data[ref.i + 64:ref.bound];
    }

    function expectAuth(Block memory ref, uint expectedCid) internal pure returns (uint deadline, bytes calldata proof) {
        ensure(ref, Keys.Auth, 149);
        if (uint(bytes32(msg.data[ref.i:ref.i + 32])) != expectedCid) revert MalformedBlocks();
        deadline = uint(bytes32(msg.data[ref.i + 32:ref.i + 64]));
        proof = msg.data[ref.i + 64:ref.bound];
    }


    // ── expect* ───────────────────────────────────────────────────────────────

    function expectAmount(Block memory ref, bytes32 asset, bytes32 meta) internal pure returns (uint amount) {
        ensure(ref, Keys.Amount, 96);
        if (bytes32(msg.data[ref.i:ref.i + 32]) != asset) revert UnexpectedValue();
        if (bytes32(msg.data[ref.i + 32:ref.i + 64]) != meta) revert UnexpectedValue();
        return uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function expectBalance(Block memory ref, bytes32 asset, bytes32 meta) internal pure returns (uint amount) {
        ensure(ref, Keys.Balance, 96);
        if (bytes32(msg.data[ref.i:ref.i + 32]) != asset) revert UnexpectedValue();
        if (bytes32(msg.data[ref.i + 32:ref.i + 64]) != meta) revert UnexpectedValue();
        return uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function expectMinimum(Block memory ref, bytes32 asset, bytes32 meta) internal pure returns (uint amount) {
        ensure(ref, Keys.Minimum, 96);
        if (bytes32(msg.data[ref.i:ref.i + 32]) != asset) revert UnexpectedValue();
        if (bytes32(msg.data[ref.i + 32:ref.i + 64]) != meta) revert UnexpectedValue();
        return uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function expectMaximum(Block memory ref, bytes32 asset, bytes32 meta) internal pure returns (uint amount) {
        ensure(ref, Keys.Maximum, 96);
        if (bytes32(msg.data[ref.i:ref.i + 32]) != asset) revert UnexpectedValue();
        if (bytes32(msg.data[ref.i + 32:ref.i + 64]) != meta) revert UnexpectedValue();
        return uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function expectCustody(Block memory ref, uint host) internal pure returns (AssetAmount memory value) {
        ensure(ref, Keys.Custody, 128);
        if (uint(bytes32(msg.data[ref.i:ref.i + 32])) != host) revert UnexpectedValue();
        value.asset = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.meta = bytes32(msg.data[ref.i + 64:ref.i + 96]);
        value.amount = uint(bytes32(msg.data[ref.i + 96:ref.i + 128]));
    }

    // ── to*Value ──────────────────────────────────────────────────────────────

    function toAmountValue(Block memory ref) internal pure returns (AssetAmount memory value) {
        ensure(ref, Keys.Amount, 96);
        value.asset = bytes32(msg.data[ref.i:ref.i + 32]);
        value.meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function toBalanceValue(Block memory ref) internal pure returns (AssetAmount memory value) {
        ensure(ref, Keys.Balance, 96);
        value.asset = bytes32(msg.data[ref.i:ref.i + 32]);
        value.meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function toMinimumValue(Block memory ref) internal pure returns (AssetAmount memory value) {
        ensure(ref, Keys.Minimum, 96);
        value.asset = bytes32(msg.data[ref.i:ref.i + 32]);
        value.meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function toMaximumValue(Block memory ref) internal pure returns (AssetAmount memory value) {
        ensure(ref, Keys.Maximum, 96);
        value.asset = bytes32(msg.data[ref.i:ref.i + 32]);
        value.meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function toListingValue(Block memory ref) internal pure returns (HostAsset memory value) {
        ensure(ref, Keys.Listing, 96);
        value.host = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        value.asset = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.meta = bytes32(msg.data[ref.i + 64:ref.i + 96]);
    }

    function toCustodyValue(Block memory ref) internal pure returns (HostAmount memory value) {
        ensure(ref, Keys.Custody, 128);
        value.host = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        value.asset = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.meta = bytes32(msg.data[ref.i + 64:ref.i + 96]);
        value.amount = uint(bytes32(msg.data[ref.i + 96:ref.i + 128]));
    }


    function toAllocationValue(Block memory ref) internal pure returns (HostAmount memory value) {
        ensure(ref, Keys.Allocation, 128);
        value.host = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        value.asset = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.meta = bytes32(msg.data[ref.i + 64:ref.i + 96]);
        value.amount = uint(bytes32(msg.data[ref.i + 96:ref.i + 128]));
    }


    function toTxValue(Block memory ref) internal pure returns (Tx memory value) {
        ensure(ref, Keys.Transaction, 160);
        value.from = bytes32(msg.data[ref.i:ref.i + 32]);
        value.to = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.asset = bytes32(msg.data[ref.i + 64:ref.i + 96]);
        value.meta = bytes32(msg.data[ref.i + 96:ref.i + 128]);
        value.amount = uint(bytes32(msg.data[ref.i + 128:ref.i + 160]));
    }

    // cursor unpack*

    function unpackRoute(Cursor memory cur) internal pure returns (bytes calldata data) {
        (uint i, uint bound, uint end) = expect(cur, Keys.Route, 0, 0);
        data = msg.data[i:bound];
        cur.i = end;
    }

    function unpackRouteUint(Cursor memory cur) internal pure returns (uint value) {
        (uint i, , uint end) = expect(cur, Keys.Route, 32, 32);
        value = uint(bytes32(msg.data[i:i + 32]));
        cur.i = end;
    }

    function unpackRoute2Uint(Cursor memory cur) internal pure returns (uint a, uint b) {
        (uint i, , uint end) = expect(cur, Keys.Route, 64, 64);
        a = uint(bytes32(msg.data[i:i + 32]));
        b = uint(bytes32(msg.data[i + 32:i + 64]));
        cur.i = end;
    }

    function unpackRoute3Uint(Cursor memory cur) internal pure returns (uint a, uint b, uint c) {
        (uint i, , uint end) = expect(cur, Keys.Route, 96, 96);
        a = uint(bytes32(msg.data[i:i + 32]));
        b = uint(bytes32(msg.data[i + 32:i + 64]));
        c = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function unpackRoute32(Cursor memory cur) internal pure returns (bytes32 value) {
        (uint i, , uint end) = expect(cur, Keys.Route, 32, 32);
        value = bytes32(msg.data[i:i + 32]);
        cur.i = end;
    }

    function unpackRoute64(Cursor memory cur) internal pure returns (bytes32 a, bytes32 b) {
        (uint i, , uint end) = expect(cur, Keys.Route, 64, 64);
        a = bytes32(msg.data[i:i + 32]);
        b = bytes32(msg.data[i + 32:i + 64]);
        cur.i = end;
    }

    function unpackRoute96(Cursor memory cur) internal pure returns (bytes32 a, bytes32 b, bytes32 c) {
        (uint i, , uint end) = expect(cur, Keys.Route, 96, 96);
        a = bytes32(msg.data[i:i + 32]);
        b = bytes32(msg.data[i + 32:i + 64]);
        c = bytes32(msg.data[i + 64:i + 96]);
        cur.i = end;
    }

    function unpackNode(Cursor memory cur) internal pure returns (uint id) {
        (uint i, , uint end) = expect(cur, Keys.Node, 32, 32);
        id = uint(bytes32(msg.data[i:i + 32]));
        cur.i = end;
    }

    function unpackRecipient(Cursor memory cur) internal pure returns (bytes32 account) {
        (uint i, , uint end) = expect(cur, Keys.Recipient, 32, 32);
        account = bytes32(msg.data[i:i + 32]);
        cur.i = end;
    }

    function unpackParty(Cursor memory cur) internal pure returns (bytes32 account) {
        (uint i, , uint end) = expect(cur, Keys.Party, 32, 32);
        account = bytes32(msg.data[i:i + 32]);
        cur.i = end;
    }

    function unpackRate(Cursor memory cur) internal pure returns (uint value) {
        (uint i, , uint end) = expect(cur, Keys.Rate, 32, 32);
        value = uint(bytes32(msg.data[i:i + 32]));
        cur.i = end;
    }

    function unpackQuantity(Cursor memory cur) internal pure returns (uint amount) {
        (uint i, , uint end) = expect(cur, Keys.Quantity, 32, 32);
        amount = uint(bytes32(msg.data[i:i + 32]));
        cur.i = end;
    }

    function unpackAsset(Cursor memory cur) internal pure returns (bytes32 asset, bytes32 meta) {
        (uint i, , uint end) = expect(cur, Keys.Asset, 64, 64);
        asset = bytes32(msg.data[i:i + 32]);
        meta = bytes32(msg.data[i + 32:i + 64]);
        cur.i = end;
    }

    function unpackFunding(Cursor memory cur) internal pure returns (uint host, uint amount) {
        (uint i, , uint end) = expect(cur, Keys.Funding, 64, 64);
        host = uint(bytes32(msg.data[i:i + 32]));
        amount = uint(bytes32(msg.data[i + 32:i + 64]));
        cur.i = end;
    }

    function unpackBounty(Cursor memory cur) internal pure returns (uint amount, bytes32 relayer) {
        (uint i, , uint end) = expect(cur, Keys.Bounty, 64, 64);
        amount = uint(bytes32(msg.data[i:i + 32]));
        relayer = bytes32(msg.data[i + 32:i + 64]);
        cur.i = end;
    }

    function unpackAmount(Cursor memory cur) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        (uint i, , uint end) = expect(cur, Keys.Amount, 96, 96);
        asset = bytes32(msg.data[i:i + 32]);
        meta = bytes32(msg.data[i + 32:i + 64]);
        amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function unpackBalance(Cursor memory cur) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        (uint i, , uint end) = expect(cur, Keys.Balance, 96, 96);
        asset = bytes32(msg.data[i:i + 32]);
        meta = bytes32(msg.data[i + 32:i + 64]);
        amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function unpackMinimum(Cursor memory cur) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        (uint i, , uint end) = expect(cur, Keys.Minimum, 96, 96);
        asset = bytes32(msg.data[i:i + 32]);
        meta = bytes32(msg.data[i + 32:i + 64]);
        amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function unpackMaximum(Cursor memory cur) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        (uint i, , uint end) = expect(cur, Keys.Maximum, 96, 96);
        asset = bytes32(msg.data[i:i + 32]);
        meta = bytes32(msg.data[i + 32:i + 64]);
        amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function unpackListing(Cursor memory cur) internal pure returns (uint host, bytes32 asset, bytes32 meta) {
        (uint i, , uint end) = expect(cur, Keys.Listing, 96, 96);
        host = uint(bytes32(msg.data[i:i + 32]));
        asset = bytes32(msg.data[i + 32:i + 64]);
        meta = bytes32(msg.data[i + 64:i + 96]);
        cur.i = end;
    }

    function unpackStep(Cursor memory cur) internal pure returns (uint target, uint value, bytes calldata req) {
        (uint i, uint bound, uint end) = expect(cur, Keys.Step, 64, 0);
        target = uint(bytes32(msg.data[i:i + 32]));
        value = uint(bytes32(msg.data[i + 32:i + 64]));
        req = msg.data[i + 64:bound];
        cur.i = end;
    }

    // cursor expect*

    function expectAuth(Cursor memory cur, uint expectedCid) internal pure returns (uint deadline, bytes calldata proof) {
        (uint i, uint bound, uint end) = expect(cur, Keys.Auth, 149, 0);
        if (uint(bytes32(msg.data[i:i + 32])) != expectedCid) revert MalformedBlocks();
        deadline = uint(bytes32(msg.data[i + 32:i + 64]));
        proof = msg.data[i + 64:bound];
        cur.i = end;
    }

    function expectAmount(Cursor memory cur, bytes32 asset, bytes32 meta) internal pure returns (uint amount) {
        (uint i, , uint end) = expect(cur, Keys.Amount, 96, 96);
        if (bytes32(msg.data[i:i + 32]) != asset) revert UnexpectedValue();
        if (bytes32(msg.data[i + 32:i + 64]) != meta) revert UnexpectedValue();
        amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function expectBalance(Cursor memory cur, bytes32 asset, bytes32 meta) internal pure returns (uint amount) {
        (uint i, , uint end) = expect(cur, Keys.Balance, 96, 96);
        if (bytes32(msg.data[i:i + 32]) != asset) revert UnexpectedValue();
        if (bytes32(msg.data[i + 32:i + 64]) != meta) revert UnexpectedValue();
        amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function expectMinimum(Cursor memory cur, bytes32 asset, bytes32 meta) internal pure returns (uint amount) {
        (uint i, , uint end) = expect(cur, Keys.Minimum, 96, 96);
        if (bytes32(msg.data[i:i + 32]) != asset) revert UnexpectedValue();
        if (bytes32(msg.data[i + 32:i + 64]) != meta) revert UnexpectedValue();
        amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function expectMaximum(Cursor memory cur, bytes32 asset, bytes32 meta) internal pure returns (uint amount) {
        (uint i, , uint end) = expect(cur, Keys.Maximum, 96, 96);
        if (bytes32(msg.data[i:i + 32]) != asset) revert UnexpectedValue();
        if (bytes32(msg.data[i + 32:i + 64]) != meta) revert UnexpectedValue();
        amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function expectCustody(Cursor memory cur, uint host) internal pure returns (AssetAmount memory value) {
        (uint i, , uint end) = expect(cur, Keys.Custody, 128, 128);
        if (uint(bytes32(msg.data[i:i + 32])) != host) revert UnexpectedValue();
        value.asset = bytes32(msg.data[i + 32:i + 64]);
        value.meta = bytes32(msg.data[i + 64:i + 96]);
        value.amount = uint(bytes32(msg.data[i + 96:i + 128]));
        cur.i = end;
    }

    // cursor to*Value

    function toAmountValue(Cursor memory cur) internal pure returns (AssetAmount memory value) {
        (uint i, , uint end) = expect(cur, Keys.Amount, 96, 96);
        value.asset = bytes32(msg.data[i:i + 32]);
        value.meta = bytes32(msg.data[i + 32:i + 64]);
        value.amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function toBalanceValue(Cursor memory cur) internal pure returns (AssetAmount memory value) {
        (uint i, , uint end) = expect(cur, Keys.Balance, 96, 96);
        value.asset = bytes32(msg.data[i:i + 32]);
        value.meta = bytes32(msg.data[i + 32:i + 64]);
        value.amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function toMinimumValue(Cursor memory cur) internal pure returns (AssetAmount memory value) {
        (uint i, , uint end) = expect(cur, Keys.Minimum, 96, 96);
        value.asset = bytes32(msg.data[i:i + 32]);
        value.meta = bytes32(msg.data[i + 32:i + 64]);
        value.amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function toMaximumValue(Cursor memory cur) internal pure returns (AssetAmount memory value) {
        (uint i, , uint end) = expect(cur, Keys.Maximum, 96, 96);
        value.asset = bytes32(msg.data[i:i + 32]);
        value.meta = bytes32(msg.data[i + 32:i + 64]);
        value.amount = uint(bytes32(msg.data[i + 64:i + 96]));
        cur.i = end;
    }

    function toListingValue(Cursor memory cur) internal pure returns (HostAsset memory value) {
        (uint i, , uint end) = expect(cur, Keys.Listing, 96, 96);
        value.host = uint(bytes32(msg.data[i:i + 32]));
        value.asset = bytes32(msg.data[i + 32:i + 64]);
        value.meta = bytes32(msg.data[i + 64:i + 96]);
        cur.i = end;
    }

    function toCustodyValue(Cursor memory cur) internal pure returns (HostAmount memory value) {
        (uint i, , uint end) = expect(cur, Keys.Custody, 128, 128);
        value.host = uint(bytes32(msg.data[i:i + 32]));
        value.asset = bytes32(msg.data[i + 32:i + 64]);
        value.meta = bytes32(msg.data[i + 64:i + 96]);
        value.amount = uint(bytes32(msg.data[i + 96:i + 128]));
        cur.i = end;
    }

    function toAllocationValue(Cursor memory cur) internal pure returns (HostAmount memory value) {
        (uint i, , uint end) = expect(cur, Keys.Allocation, 128, 128);
        value.host = uint(bytes32(msg.data[i:i + 32]));
        value.asset = bytes32(msg.data[i + 32:i + 64]);
        value.meta = bytes32(msg.data[i + 64:i + 96]);
        value.amount = uint(bytes32(msg.data[i + 96:i + 128]));
        cur.i = end;
    }

    function toTxValue(Cursor memory cur) internal pure returns (Tx memory value) {
        (uint i, , uint end) = expect(cur, Keys.Transaction, 160, 160);
        value.from = bytes32(msg.data[i:i + 32]);
        value.to = bytes32(msg.data[i + 32:i + 64]);
        value.asset = bytes32(msg.data[i + 64:i + 96]);
        value.meta = bytes32(msg.data[i + 96:i + 128]);
        value.amount = uint(bytes32(msg.data[i + 128:i + 160]));
        cur.i = end;
    }

}
