// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {ALLOCATION_KEY, AMOUNT_KEY, ASSET_KEY, AUTH_KEY, BALANCE_KEY, CUSTODY_KEY, BlockRef, BOUNTY_KEY, DataRef, FUNDING_KEY, MAXIMUM_KEY, MemRef, MINIMUM_KEY, NODE_KEY, RECIPIENT_KEY, ROUTE_KEY, STEP_KEY, TX_KEY, AssetAmount, HostAmount, Tx} from "./Schema.sol";

error MalformedBlocks();
error InvalidBlock();
error ZeroRecipient();
error ZeroNode();

uint constant AUTH_PROOF_LEN = 85;
uint constant AUTH_HEAD_LEN = 64;
uint constant AUTH_SELF_LEN = AUTH_HEAD_LEN + AUTH_PROOF_LEN;
uint constant AUTH_TOTAL_LEN = 12 + AUTH_SELF_LEN;

using Blocks for BlockRef;
using Data for DataRef;

library Blocks {
    function from(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        uint eod = source.length;
        if (i == eod) return BlockRef(bytes4(0), 0, 0, i);
        if (i > eod) revert MalformedBlocks();

        unchecked {
            ref.i = i + 12;
        }
        if (ref.i > eod) revert MalformedBlocks();
        ref.key = bytes4(source[i:i + 4]);
        ref.bound = ref.i + uint32(bytes4(source[i + 4:i + 8]));
        ref.end = ref.i + uint32(bytes4(source[i + 8:ref.i]));

        if (ref.bound > ref.end || ref.end > eod) revert MalformedBlocks();
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

    function toBounty(uint bounty, bytes32 relayer) internal pure returns (bytes memory) {
        return create64(BOUNTY_KEY, bytes32(bounty), relayer);
    }

    function isAmount(BlockRef memory ref) internal pure returns (bool) {
        return ref.key == AMOUNT_KEY;
    }

    function isBalance(BlockRef memory ref) internal pure returns (bool) {
        return ref.key == BALANCE_KEY;
    }

    function isCustody(BlockRef memory ref) internal pure returns (bool) {
        return ref.key == CUSTODY_KEY;
    }

    function isRoute(BlockRef memory ref) internal pure returns (bool) {
        return ref.key == ROUTE_KEY;
    }

    function resolveRecipient(bytes calldata source, uint i, bytes32 backup) internal pure returns (bytes32) {
        BlockRef memory ref = find(source, i, source.length, RECIPIENT_KEY);
        bytes32 to = ref.key != 0 ? ref.unpackRecipient(source) : backup;
        if (to == 0) revert ZeroRecipient();
        return to;
    }

    function resolveNode(bytes calldata source, uint i, uint backup) internal pure returns (uint) {
        BlockRef memory ref = find(source, i, source.length, NODE_KEY);
        uint node = ref.key != 0 ? ref.unpackNode(source) : backup;
        if (node == 0) revert ZeroNode();
        return node;
    }

    function ensure(BlockRef memory ref, bytes4 key) internal pure {
        if (key != ref.key) revert InvalidBlock();
    }

    function ensure(BlockRef memory ref, bytes4 key, uint len) internal pure {
        if (key != ref.key || len != (ref.bound - ref.i)) revert InvalidBlock();
    }

    function ensure(BlockRef memory ref, bytes4 key, uint min, uint max) internal pure {
        uint len = ref.bound - ref.i;
        if (key != ref.key || len < min || (max != 0 && len > max)) revert InvalidBlock();
    }

    function routeFrom(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, ROUTE_KEY, 1, 0);
    }

    function ensureAuth(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, AUTH_KEY, AUTH_SELF_LEN);
    }

    function ensureAsset(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, ASSET_KEY, 64, 0);
    }

    function ensureNode(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, NODE_KEY, 32, 0);
    }

    function ensureFunding(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, FUNDING_KEY, 64, 0);
    }

    function ensureBalance(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, BALANCE_KEY, 96, 0);
    }

    function balanceFrom(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, BALANCE_KEY, 96, 0);
    }

    function ensureCustody(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, CUSTODY_KEY, 128, 0);
    }

    function custodyFrom(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, CUSTODY_KEY, 128, 0);
    }

    function ensureAmount(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, AMOUNT_KEY, 96, 0);
    }

    function amountFrom(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, AMOUNT_KEY, 96, 0);
    }

    function ensureMinimum(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, MINIMUM_KEY, 96, 0);
    }

    function ensureMaximum(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, MAXIMUM_KEY, 96, 0);
    }

    function ensureStep(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, STEP_KEY, 64, 0);
    }

    function ensureAllocation(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, ALLOCATION_KEY, 128, 0);
    }

    function ensureTx(bytes calldata source, uint i) internal pure returns (BlockRef memory ref) {
        ref = from(source, i);
        ensure(ref, TX_KEY, 160, 0);
    }

    function unpackNode(BlockRef memory ref, bytes calldata source) internal pure returns (uint id) {
        ensure(ref, NODE_KEY, 32);
        id = uint(bytes32(source[ref.i:ref.i + 32]));
    }

    function unpackAsset(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (bytes32 asset, bytes32 meta) {
        ensure(ref, ASSET_KEY, 64);
        return (bytes32(source[ref.i:ref.i + 32]), bytes32(source[ref.i + 32:ref.i + 64]));
    }

    function unpackRecipient(BlockRef memory ref, bytes calldata source) internal pure returns (bytes32 account) {
        ensure(ref, RECIPIENT_KEY, 32);
        return bytes32(source[ref.i:ref.i + 32]);
    }

    function toAmountValue(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (AssetAmount memory value) {
        ensure(ref, AMOUNT_KEY, 96);
        return toAssetAmount(ref, source);
    }

    function unpackAmount(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, AMOUNT_KEY, 96);
        return unpackAssetAmount(ref, source);
    }

    function unpackBalance(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, BALANCE_KEY, 96);
        return unpackAssetAmount(ref, source);
    }

    function unpackCustody(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (uint host, bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, CUSTODY_KEY, 128);
        return unpackHostAmount(ref, source);
    }

    function toBalanceValue(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (AssetAmount memory value) {
        ensure(ref, BALANCE_KEY, 96);
        return toAssetAmount(ref, source);
    }

    function toCustodyValue(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (HostAmount memory value) {
        ensure(ref, CUSTODY_KEY, 128);
        return toHostAmount(ref, source);
    }

    function unpackMinimum(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (AssetAmount memory value) {
        ensure(ref, MINIMUM_KEY, 96);
        return toAssetAmount(ref, source);
    }

    function unpackMaximum(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (AssetAmount memory value) {
        ensure(ref, MAXIMUM_KEY, 96);
        return toAssetAmount(ref, source);
    }

    function unpackStep(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (uint target, uint value, bytes calldata req) {
        ensure(ref, STEP_KEY, 64, 0);
        target = uint(bytes32(source[ref.i:ref.i + 32]));
        value = uint(bytes32(source[ref.i + 32:ref.i + 64]));
        req = source[ref.i + 64:ref.bound];
    }

    function unpackFunding(BlockRef memory ref, bytes calldata source) internal pure returns (uint host, uint amount) {
        ensure(ref, FUNDING_KEY, 64);
        host = uint(bytes32(source[ref.i:ref.i + 32]));
        amount = uint(bytes32(source[ref.i + 32:ref.i + 64]));
    }

    function unpackAuth(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (uint cid, uint deadline, bytes calldata proof) {
        ensure(ref, AUTH_KEY, AUTH_SELF_LEN);
        cid = uint(bytes32(source[ref.i:ref.i + 32]));
        deadline = uint(bytes32(source[ref.i + 32:ref.i + 64]));
        proof = source[ref.i + 64:ref.bound];
    }

    function unpackAllocation(
        BlockRef memory ref,
        bytes calldata source
    ) internal pure returns (uint host, bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, ALLOCATION_KEY, 128);
        return unpackHostAmount(ref, source);
    }

    function toTxValue(BlockRef memory ref, bytes calldata source) internal pure returns (Tx memory value) {
        ensure(ref, TX_KEY, 160);
        value.from = bytes32(source[ref.i:ref.i + 32]);
        value.to = bytes32(source[ref.i + 32:ref.i + 64]);
        value.asset = bytes32(source[ref.i + 64:ref.i + 96]);
        value.meta = bytes32(source[ref.i + 96:ref.i + 128]);
        value.amount = uint(bytes32(source[ref.i + 128:ref.i + 160]));
    }

    function unpackAssetAmount(
        BlockRef memory ref,
        bytes calldata source
    ) private pure returns (bytes32 asset, bytes32 meta, uint amount) {
        asset = bytes32(source[ref.i:ref.i + 32]);
        meta = bytes32(source[ref.i + 32:ref.i + 64]);
        amount = uint(bytes32(source[ref.i + 64:ref.i + 96]));
    }

    function toAssetAmount(BlockRef memory ref, bytes calldata source) private pure returns (AssetAmount memory value) {
        value.asset = bytes32(source[ref.i:ref.i + 32]);
        value.meta = bytes32(source[ref.i + 32:ref.i + 64]);
        value.amount = uint(bytes32(source[ref.i + 64:ref.i + 96]));
    }

    function unpackHostAmount(
        BlockRef memory ref,
        bytes calldata source
    ) private pure returns (uint host, bytes32 asset, bytes32 meta, uint amount) {
        host = uint(bytes32(source[ref.i:ref.i + 32]));
        asset = bytes32(source[ref.i + 32:ref.i + 64]);
        meta = bytes32(source[ref.i + 64:ref.i + 96]);
        amount = uint(bytes32(source[ref.i + 96:ref.i + 128]));
    }

    function toHostAmount(BlockRef memory ref, bytes calldata source) private pure returns (HostAmount memory value) {
        value.host = uint(bytes32(source[ref.i:ref.i + 32]));
        value.asset = bytes32(source[ref.i + 32:ref.i + 64]);
        value.meta = bytes32(source[ref.i + 64:ref.i + 96]);
        value.amount = uint(bytes32(source[ref.i + 96:ref.i + 128]));
    }

    function unpackSigned(
        BlockRef memory ref,
        bytes calldata source,
        uint expectedCid
    ) internal pure returns (bytes32 hash, uint deadline, bytes calldata proof, uint next) {
        if (ref.end - ref.bound < AUTH_TOTAL_LEN) revert MalformedBlocks();
        BlockRef memory authRef = ref.childAt(source, ref.end - AUTH_TOTAL_LEN);

        uint cid;
        (cid, deadline, proof) = authRef.unpackAuth(source);
        if (cid != expectedCid) revert MalformedBlocks();
        hash = keccak256(source[ref.i - 12:authRef.i + AUTH_HEAD_LEN]);
        next = ref.end;
    }

    function count(bytes calldata source, uint i, bytes4 key) internal pure returns (uint count_, uint next) {
        next = i;
        while (next < source.length) {
            BlockRef memory ref = from(source, next);
            if (ref.key != key) break;
            unchecked {
                ++count_;
            }
            next = ref.end;
        }
    }

    function find(bytes calldata source, uint i, uint limit, bytes4 key) internal pure returns (BlockRef memory ref) {
        if (limit > source.length) revert MalformedBlocks();
        while (i < limit) {
            ref = from(source, i);
            if (ref.end > limit) revert MalformedBlocks();
            if (ref.key == key) return ref;
            i = ref.end;
        }

        return BlockRef(bytes4(0), limit, limit, limit);
    }

    function findChild(
        BlockRef memory parent,
        bytes calldata source,
        bytes4 key
    ) internal pure returns (BlockRef memory ref) {
        return find(source, parent.bound, parent.end, key);
    }

    function childAt(
        BlockRef memory parent,
        bytes calldata source,
        uint i
    ) internal pure returns (BlockRef memory ref) {
        if (i < parent.bound || i >= parent.end) revert MalformedBlocks();
        ref = from(source, i);
        if (ref.end > parent.end) revert MalformedBlocks();
    }

    function rebaseToDataRef(BlockRef memory ref, bytes calldata source) internal pure returns (DataRef memory out) {
        uint base;
        assembly ("memory-safe") {
            base := source.offset
        }
        out.key = ref.key;
        out.i = base + ref.i;
        out.bound = base + ref.bound;
        out.end = base + ref.end;
    }
}

library Data {
    function from(bytes calldata source, uint i) internal pure returns (DataRef memory ref, uint next) {
        uint base;
        uint eod = source.length;
        assembly ("memory-safe") {
            base := source.offset
        }

        if (i == eod) return (DataRef(bytes4(0), 0, 0, base + i), i);
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

        uint eos = base + eod;
        if (ref.bound > ref.end || ref.end > eos) revert MalformedBlocks();
        next = i + (ref.end - ref.i) + 12;
    }

    function at(uint i) internal pure returns (DataRef memory ref) {
        uint eod = msg.data.length;
        if (i == eod) return DataRef(bytes4(0), 0, 0, i);
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

    function ensure(DataRef memory ref, bytes4 key) internal pure {
        if (key != ref.key) revert InvalidBlock();
    }

    function ensure(DataRef memory ref, bytes4 key, uint len) internal pure {
        if (key != ref.key || len != (ref.bound - ref.i)) revert InvalidBlock();
    }

    function ensure(DataRef memory ref, bytes4 key, uint min, uint max) internal pure {
        uint len = ref.bound - ref.i;
        if (key != ref.key || len < min || (max != 0 && len > max)) revert InvalidBlock();
    }

    function routeFrom(bytes calldata source, uint i) internal pure returns (DataRef memory ref, uint next) {
        (ref, next) = from(source, i);
        ensure(ref, ROUTE_KEY, 1, 0);
    }

    function balanceFrom(bytes calldata source, uint i) internal pure returns (DataRef memory ref, uint next) {
        (ref, next) = from(source, i);
        ensure(ref, BALANCE_KEY, 96, 0);
    }

    function amountFrom(bytes calldata source, uint i) internal pure returns (DataRef memory ref, uint next) {
        (ref, next) = from(source, i);
        ensure(ref, AMOUNT_KEY, 96, 0);
    }

    function unpackAsset(DataRef memory ref) internal pure returns (bytes32 asset, bytes32 meta) {
        ensure(ref, ASSET_KEY, 64);
        return (bytes32(msg.data[ref.i:ref.i + 32]), bytes32(msg.data[ref.i + 32:ref.i + 64]));
    }

    function unpackRecipient(DataRef memory ref) internal pure returns (bytes32 account) {
        ensure(ref, RECIPIENT_KEY, 32);
        return bytes32(msg.data[ref.i:ref.i + 32]);
    }

    function toAmountValue(DataRef memory ref) internal pure returns (AssetAmount memory value) {
        ensure(ref, AMOUNT_KEY, 96);
        value.asset = bytes32(msg.data[ref.i:ref.i + 32]);
        value.meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function unpackAmount(DataRef memory ref) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, AMOUNT_KEY, 96);
        asset = bytes32(msg.data[ref.i:ref.i + 32]);
        meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function unpackBalance(DataRef memory ref) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, BALANCE_KEY, 96);
        asset = bytes32(msg.data[ref.i:ref.i + 32]);
        meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function unpackCustody(
        DataRef memory ref
    ) internal pure returns (uint host, bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, CUSTODY_KEY, 128);
        host = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        asset = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        meta = bytes32(msg.data[ref.i + 64:ref.i + 96]);
        amount = uint(bytes32(msg.data[ref.i + 96:ref.i + 128]));
    }

    function toBalanceValue(DataRef memory ref) internal pure returns (AssetAmount memory value) {
        ensure(ref, BALANCE_KEY, 96);
        value.asset = bytes32(msg.data[ref.i:ref.i + 32]);
        value.meta = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.amount = uint(bytes32(msg.data[ref.i + 64:ref.i + 96]));
    }

    function toCustodyValue(DataRef memory ref) internal pure returns (HostAmount memory value) {
        ensure(ref, CUSTODY_KEY, 128);
        value.host = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        value.asset = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.meta = bytes32(msg.data[ref.i + 64:ref.i + 96]);
        value.amount = uint(bytes32(msg.data[ref.i + 96:ref.i + 128]));
    }

    function custodyFrom(bytes calldata source, uint i) internal pure returns (DataRef memory ref, uint next) {
        (ref, next) = from(source, i);
        ensure(ref, CUSTODY_KEY, 128, 0);
    }

    function unpackAuth(DataRef memory ref) internal pure returns (uint cid, uint deadline, bytes calldata proof) {
        ensure(ref, AUTH_KEY, AUTH_SELF_LEN);
        cid = uint(bytes32(msg.data[ref.i:ref.i + 32]));
        deadline = uint(bytes32(msg.data[ref.i + 32:ref.i + 64]));
        proof = msg.data[ref.i + 64:ref.bound];
    }

    function toTxValue(DataRef memory ref) internal pure returns (Tx memory value) {
        ensure(ref, TX_KEY, 160);
        value.from = bytes32(msg.data[ref.i:ref.i + 32]);
        value.to = bytes32(msg.data[ref.i + 32:ref.i + 64]);
        value.asset = bytes32(msg.data[ref.i + 64:ref.i + 96]);
        value.meta = bytes32(msg.data[ref.i + 96:ref.i + 128]);
        value.amount = uint(bytes32(msg.data[ref.i + 128:ref.i + 160]));
    }

    function findFrom(bytes calldata source, uint i, uint limit, bytes4 key) internal pure returns (DataRef memory ref) {
        if (limit > source.length) revert MalformedBlocks();
        while (i < limit) {
            uint next;
            (ref, next) = from(source, i);
            if (next > limit) revert MalformedBlocks();
            if (ref.key == key) return ref;
            i = next;
        }

        return DataRef(bytes4(0), limit, limit, limit);
    }

    function findChild(DataRef memory parent, bytes4 key) internal pure returns (DataRef memory ref) {
        return findFrom(msg.data, parent.bound, parent.end, key);
    }

    function childAt(DataRef memory parent, uint i) internal pure returns (DataRef memory ref) {
        if (i < parent.bound || i >= parent.end) revert MalformedBlocks();
        ref = at(i);
        if (ref.end > parent.end) revert MalformedBlocks();
    }
}

library Mem {
    function from(bytes memory source, uint i) internal pure returns (MemRef memory ref) {
        uint eod = source.length;
        if (i == eod) return MemRef(bytes4(0), 0, 0, i);
        if (i > eod) revert MalformedBlocks();

        unchecked {
            ref.i = i + 12;
        }
        if (ref.i > eod) revert MalformedBlocks();

        bytes32 w;
        assembly ("memory-safe") {
            w := mload(add(add(source, 0x20), i))
        }

        ref.key = bytes4(w);
        ref.bound = ref.i + uint32(bytes4(w << 32));
        ref.end = ref.i + uint32(bytes4(w << 64));

        if (ref.bound > ref.end || ref.end > eod) revert MalformedBlocks();
    }

    function ensure(MemRef memory ref, bytes4 key) internal pure {
        if (key != ref.key) revert InvalidBlock();
    }

    function ensure(MemRef memory ref, bytes4 key, uint len) internal pure {
        if (key != ref.key || len != (ref.bound - ref.i)) revert InvalidBlock();
    }

    function ensure(MemRef memory ref, bytes4 key, uint min, uint max) internal pure {
        uint len = ref.bound - ref.i;
        if (key != ref.key || len < min || (max != 0 && len > max)) revert InvalidBlock();
    }

    function unpackUintHash(MemRef memory ref, bytes memory source) internal pure returns (uint value, bytes32 hash) {
        if (ref.bound < ref.i + 32) revert MalformedBlocks();

        uint i = ref.i;
        uint eoa = i + 32;
        uint bound = ref.bound;

        assembly ("memory-safe") {
            value := mload(add(add(source, 0x20), i))
            hash := keccak256(add(add(source, 0x20), eoa), sub(bound, eoa))
        }
    }

    function unpackBalance(
        MemRef memory ref,
        bytes memory source
    ) internal pure returns (bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, BALANCE_KEY, 96);
        uint i = ref.i;

        assembly ("memory-safe") {
            let p := add(add(source, 0x20), i)
            asset := mload(p)
            meta := mload(add(p, 0x20))
            amount := mload(add(p, 0x40))
        }
    }

    function unpackCustody(
        MemRef memory ref,
        bytes memory source
    ) internal pure returns (uint host, bytes32 asset, bytes32 meta, uint amount) {
        ensure(ref, CUSTODY_KEY, 128);
        uint i = ref.i;

        assembly ("memory-safe") {
            let p := add(add(source, 0x20), i)
            host := mload(p)
            asset := mload(add(p, 0x20))
            meta := mload(add(p, 0x40))
            amount := mload(add(p, 0x60))
        }
    }

    function toTxValue(MemRef memory ref, bytes memory source) internal pure returns (Tx memory value) {
        ensure(ref, TX_KEY, 160);
        uint i = ref.i;

        assembly ("memory-safe") {
            let p := add(add(source, 0x20), i)
            mstore(value, mload(p))
            mstore(add(value, 0x20), mload(add(p, 0x20)))
            mstore(add(value, 0x40), mload(add(p, 0x40)))
            mstore(add(value, 0x60), mload(add(p, 0x60)))
            mstore(add(value, 0x80), mload(add(p, 0x80)))
        }
    }

    function slice(bytes memory source, uint start, uint end) internal pure returns (bytes memory out) {
        if (end < start || end > source.length) revert MalformedBlocks();
        uint len = end - start;
        out = new bytes(len);
        if (len == 0) return out;

        assembly ("memory-safe") {
            mcopy(add(out, 0x20), add(add(source, 0x20), start), len)
        }
    }

    function count(bytes memory source, uint i, bytes4 key) internal pure returns (uint count_, uint next) {
        next = i;
        while (next < source.length) {
            MemRef memory ref = from(source, next);
            if (ref.key != key) break;
            unchecked {
                ++count_;
            }
            next = ref.end;
        }
    }

    function find(bytes memory source, uint i, uint limit, bytes4 key) internal pure returns (MemRef memory ref) {
        if (limit > source.length) revert MalformedBlocks();
        while (i < limit) {
            ref = from(source, i);
            if (ref.end > limit) revert MalformedBlocks();
            if (ref.key == key) return ref;
            i = ref.end;
        }

        return MemRef(bytes4(0), limit, limit, limit);
    }
}
