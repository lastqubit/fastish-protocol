// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { AssetAmount, HostAmount, Tx } from "../blocks/Schema.sol";
import { Block, Cursor, Writer } from "../Blocks.sol";
import { MemRef } from "../blocks/Mem.sol";
import { Blocks, Keys } from "../blocks/Blocks.sol";
import { Mem } from "../blocks/Mem.sol";
import { Writers, BALANCE_BLOCK_LEN, CUSTODY_BLOCK_LEN, TX_BLOCK_LEN } from "../blocks/Writers.sol";

using Blocks for Block;
using Writers for Writer;
using Mem for MemRef;

contract TestBlockHelper {
    function testBlockHeader(bytes4 key, uint len) external pure returns (uint) {
        return Writers.toBlockHeader(key, len);
    }

    function testWriteBalanceBlock(bytes32 asset, bytes32 meta, uint amount) external pure returns (bytes memory) {
        Writer memory w = Writers.alloc(BALANCE_BLOCK_LEN);
        w.appendBalance(asset, meta, amount);
        return w.dst;
    }

    function testWriteTwoBalanceBlocks(
        bytes32 a1,
        bytes32 m1,
        uint v1,
        bytes32 a2,
        bytes32 m2,
        uint v2
    ) external pure returns (bytes memory) {
        Writer memory w = Writers.alloc(BALANCE_BLOCK_LEN * 2);
        w.appendBalance(a1, m1, v1);
        w.appendBalance(a2, m2, v2);
        return w.dst;
    }

    function testWriteCustodyBlock(
        uint host_,
        bytes32 asset,
        bytes32 meta,
        uint amount
    ) external pure returns (bytes memory) {
        Writer memory w = Writers.alloc(CUSTODY_BLOCK_LEN);
        w.appendCustody(host_, asset, meta, amount);
        return w.dst;
    }

    function testWriteTxBlock(
        bytes32 from_,
        bytes32 to_,
        bytes32 asset,
        bytes32 meta,
        uint amount
    ) external pure returns (bytes memory) {
        Writer memory w = Writers.alloc(TX_BLOCK_LEN);
        w.appendTx(Tx({ from: from_, to: to_, asset: asset, meta: meta, amount: amount }));
        return w.dst;
    }

    function testWriterDone() external pure returns (bytes memory) {
        Writer memory w = Writers.alloc(BALANCE_BLOCK_LEN);
        return Writers.done(w);
    }

    function testWriterFinish(bytes32 asset, bytes32 meta, uint amount) external pure returns (bytes memory) {
        Writer memory w = Writers.alloc(BALANCE_BLOCK_LEN * 2);
        w.appendBalance(asset, meta, amount);
        return Writers.finish(w);
    }

    function testParseBlock(bytes calldata source, uint i) external pure returns (bytes4 key, uint end) {
        uint base;
        assembly ("memory-safe") {
            base := source.offset
        }
        Block memory ref = Blocks.from(source, i);
        if (ref.key == 0) return (bytes4(0), ref.cursor);
        return (ref.key, ref.end - base);
    }

    function testUnpackAmount(bytes calldata source, uint i)
        external
        pure
        returns (bytes32 asset, bytes32 meta, uint amount)
    {
        Block memory ref = Blocks.amountFrom(source, i);
        return ref.unpackAmount();
    }

    function testUnpackBalance(bytes calldata source, uint i)
        external
        pure
        returns (bytes32 asset, bytes32 meta, uint amount)
    {
        Block memory ref = Blocks.balanceFrom(source, i);
        return ref.unpackBalance();
    }

    function testUnpackCustody(bytes calldata source, uint i)
        external
        pure
        returns (uint host_, bytes32 asset, bytes32 meta, uint amount)
    {
        Block memory ref = Blocks.custodyFrom(source, i);
        HostAmount memory value = ref.toCustodyValue();
        return (value.host, value.asset, value.meta, value.amount);
    }

    function testUnpackRecipient(bytes calldata source, uint i) external pure returns (bytes32 account) {
        Block memory ref = Blocks.from(source, i);
        return ref.unpackRecipient();
    }

    function testUnpackNode(bytes calldata source, uint i) external pure returns (uint id) {
        Block memory ref = Blocks.from(source, i);
        return ref.unpackNode();
    }

    function testUnpackQuantity(bytes calldata source, uint i) external pure returns (uint amount) {
        Block memory ref = Blocks.quantityFrom(source, i);
        return ref.unpackQuantity();
    }

    function testExpectMinimum(bytes calldata source, uint i, bytes32 asset, bytes32 meta)
        external
        pure
        returns (uint amount)
    {
        Block memory ref = Blocks.from(source, i);
        return ref.expectMinimum(asset, meta);
    }

    function testExpectAmount(bytes calldata source, uint i, bytes32 asset, bytes32 meta)
        external
        pure
        returns (uint amount)
    {
        Block memory ref = Blocks.from(source, i);
        return ref.expectAmount(asset, meta);
    }

    function testExpectBalance(bytes calldata source, uint i, bytes32 asset, bytes32 meta)
        external
        pure
        returns (uint amount)
    {
        Block memory ref = Blocks.from(source, i);
        return ref.expectBalance(asset, meta);
    }

    function testExpectMaximum(bytes calldata source, uint i, bytes32 asset, bytes32 meta)
        external
        pure
        returns (uint amount)
    {
        Block memory ref = Blocks.from(source, i);
        return ref.expectMaximum(asset, meta);
    }

    function testExpectCustody(bytes calldata source, uint i, uint host_)
        external
        pure
        returns (bytes32 asset, bytes32 meta, uint amount)
    {
        Block memory ref = Blocks.from(source, i);
        AssetAmount memory value = ref.expectCustody(host_);
        return (value.asset, value.meta, value.amount);
    }

    function testUnpackFunding(bytes calldata source, uint i) external pure returns (uint host_, uint amount) {
        Block memory ref = Blocks.from(source, i);
        return ref.unpackFunding();
    }

    function testUnpackAsset(bytes calldata source, uint i) external pure returns (bytes32 asset, bytes32 meta) {
        Block memory ref = Blocks.from(source, i);
        return ref.unpackAsset();
    }

    function testUnpackAllocation(bytes calldata source, uint i)
        external
        pure
        returns (uint host_, bytes32 asset, bytes32 meta, uint amount)
    {
        Block memory ref = Blocks.from(source, i);
        HostAmount memory value = ref.toAllocationValue();
        return (value.host, value.asset, value.meta, value.amount);
    }

    function testToTxValue(bytes calldata source, uint i)
        external
        pure
        returns (bytes32 from_, bytes32 to_, bytes32 asset, bytes32 meta, uint amount)
    {
        Block memory ref = Blocks.from(source, i);
        Tx memory value = ref.toTxValue();
        return (value.from, value.to, value.asset, value.meta, value.amount);
    }

    function testCountBlocks(bytes calldata source, uint i, bytes4 key) external pure returns (uint count, uint cursor) {
        return Blocks.count(source, i, key);
    }

    function testBundleFrom(bytes calldata source, uint i)
        external
        pure
        returns (bytes4 key, uint start, uint end, uint cursor)
    {
        uint base;
        assembly ("memory-safe") {
            base := source.offset
        }
        Block memory ref = Blocks.bundleFrom(source, i);
        return (ref.key, ref.i - base, ref.end - base, ref.cursor);
    }

    function testCursorFrom(bytes calldata source, uint i)
        external
        pure
        returns (uint start, uint end, uint cursor)
    {
        uint base;
        assembly ("memory-safe") {
            base := source.offset
        }
        Cursor memory cur = Blocks.cursorFrom(source, i);
        return (cur.i - base, cur.end - base, cur.cursor);
    }

    function testCursorFromN(bytes calldata source, uint i, uint n)
        external
        pure
        returns (uint start, uint end, uint cursor)
    {
        uint base;
        assembly ("memory-safe") {
            base := source.offset
        }
        Cursor memory cur = Blocks.cursorFrom(source, i, n);
        return (cur.i - base, cur.end - base, cur.cursor);
    }

    function testMember(bytes calldata source, uint i, uint index)
        external
        pure
        returns (bytes4 key, uint start, uint end, uint cursor)
    {
        uint base;
        assembly ("memory-safe") {
            base := source.offset
        }
        Cursor memory input = Blocks.cursorFrom(source, i);
        uint n;
        Block memory ref;
        while (input.i < input.end) {
            ref = Blocks.at(input.i);
            if (ref.end > input.end) revert Blocks.MalformedBlocks();
            ref.cursor = ref.end;
            if (n == index) return (ref.key, ref.i - base, ref.end - base, ref.cursor - base);
            input.i = ref.end;
            unchecked {
                ++n;
            }
        }
        revert Blocks.MalformedBlocks();
    }

    function testMemberAt(bytes calldata source, uint i, uint at_)
        external
        pure
        returns (bytes4 key, uint start, uint end, uint cursor)
    {
        uint base;
        assembly ("memory-safe") {
            base := source.offset
        }
        Cursor memory input = Blocks.cursorFrom(source, i);
        uint atAbs = base + at_;
        if (atAbs < input.i || atAbs >= input.end) revert Blocks.MalformedBlocks();
        Block memory ref = Blocks.at(atAbs);
        if (ref.end > input.end) revert Blocks.MalformedBlocks();
        ref.cursor = ref.end;
        return (ref.key, ref.i - base, ref.end - base, ref.cursor - base);
    }

    function testResolveRecipient(bytes calldata source, uint i, uint limit, bytes32 backup)
        external
        pure
        returns (bytes32)
    {
        return Blocks.resolveRecipient(source, i, limit, backup);
    }

    function testResolveNode(bytes calldata source, uint i, uint limit, uint backup)
        external
        pure
        returns (uint)
    {
        return Blocks.resolveNode(source, i, limit, backup);
    }

    function testVerifyAuth(bytes calldata source, uint i, uint expectedCid)
        external
        pure
        returns (bytes32 hash, uint deadline, bytes calldata proof)
    {
        Cursor memory input = Blocks.cursorFrom(source, i);
        return Blocks.resolveAuth(input, expectedCid);
    }

    function testMemParseBalance(bytes memory source, uint i)
        external
        pure
        returns (bytes32 asset, bytes32 meta, uint amount)
    {
        MemRef memory ref = Mem.from(source, i);
        return ref.unpackBalance(source);
    }

    function testMemParseCustody(bytes memory source, uint i) external pure returns (HostAmount memory value) {
        MemRef memory ref = Mem.from(source, i);
        return ref.toCustodyValue(source);
    }

    function testMemSlice(bytes memory source, uint start, uint end_) external pure returns (bytes memory) {
        return Mem.slice(source, start, end_);
    }

    function testMemCount(bytes memory source, uint i, bytes4 key) external pure returns (uint count, uint cursor) {
        return Mem.count(source, i, key);
    }

    function testAllocBalancesFromCount(bytes calldata source, uint i, bytes4 sourceKey)
        external
        pure
        returns (uint count, uint cursor)
    {
        return Blocks.count(source, i, sourceKey);
    }
}
