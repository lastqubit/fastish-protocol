import { expect } from "chai";
import { ethers } from "ethers";
import { deploy } from "./helpers/setup.js";
import "./helpers/matchers.js";
import {
  Keys,
  encodeAllocationBlock,
  encodeAmountBlock,
  encodeAuthBlock,
  encodeAssetBlock,
  encodeBalanceBlock,
  encodeBoundsBlock,
  encodeBountyBlock,
  encodeBundleBlock,
  encodeListBlock,
  encodeCustodyBlock,
  encodeFeeBlock,
  encodeFundingBlock,
  encodeListingBlock,
  encodeMaximumsBlock,
  encodeMaximumBlock,
  encodeMinimumsBlock,
  encodeMinimumBlock,
  encodeNodeBlock,
  encodePathBlock,
  encodeRecipientBlock,
  encodeRouteBlock,
  encodeStepBlock,
  encodeTxBlock,
  encodeUserAccount,
  concat,
} from "./helpers/blocks.js";

describe("Cursors", () => {
  let helper: Awaited<ReturnType<typeof deploy>>;
  let operation: Awaited<ReturnType<typeof deploy>>;

  before(async () => {
    helper = await deploy("TestCursorHelper");
    operation = await deploy("TestOperation");
  });

  describe("Writers", () => {
    const asset = ethers.zeroPadValue("0x01", 32);
    const meta = ethers.zeroPadValue("0x02", 32);
    const amount = 12345n;

    it("toBlockHeader packs key and payloadLen", async () => {
      const header: bigint = await helper.testBlockHeader(Keys.Balance, 96n);
      expect((header >> 224n) & 0xffffffffn).to.equal(BigInt(Keys.Balance));
      expect((header >> 192n) & 0xffffffffn).to.equal(96n);
    });

    it("toBlockHeader reverts BlockLengthOverflow when payloadLen exceeds uint32", async () => {
      await expect(helper.testBlockHeader(Keys.Balance, 0x1_0000_0000n))
        .to.be.revertedWithCustomError(helper, "BlockLengthOverflow");
    });

    it("writeBalanceBlock round-trips", async () => {
      const data: string = await helper.testWriteBalanceBlock(asset, meta, amount);
      expect(ethers.getBytes(data).length).to.equal(104);
      expect(data.slice(0, 10)).to.equal(Keys.Balance);
      expect(await helper.testUnpackBalance(data)).to.deep.equal([asset, meta, amount]);
    });

    it("writeCustodyBlock produces 136 bytes", async () => {
      const data: string = await helper.testWriteCustodyBlock(1234n, asset, meta, amount);
      expect(ethers.getBytes(data).length).to.equal(136);
    });

    it("writeTxBlock round-trips", async () => {
      const from_ = encodeUserAccount("0x03");
      const to_ = encodeUserAccount("0x04");
      const data: string = await helper.testWriteTxBlock(from_, to_, asset, meta, amount);
      expect(ethers.getBytes(data).length).to.equal(168);
      expect(await helper.testToTxValue(data)).to.deep.equal([from_, to_, asset, meta, amount]);
    });

    it("toBalanceBlock returns a valid encoded BALANCE block", async () => {
      const data: string = await helper.testToBalanceBlock(asset, meta, amount);
      expect(ethers.getBytes(data).length).to.equal(104);
      expect(data.slice(0, 10)).to.equal(Keys.Balance);
      expect(await helper.testUnpackBalance(data)).to.deep.equal([asset, meta, amount]);
    });

    it("toCustodyBlock returns a valid encoded CUSTODY block", async () => {
      const data: string = await helper.testToCustodyBlock(1234n, asset, meta, amount);
      expect(ethers.getBytes(data).length).to.equal(136);
      expect(data.slice(0, 10)).to.equal(Keys.Custody);
    });

    it("toBountyBlock returns a valid encoded BOUNTY block", async () => {
      const relayer = ethers.zeroPadValue("0x05", 32);
      const data: string = await helper.testToBountyBlock(amount, relayer);
      const bytes = ethers.getBytes(data);
      expect(bytes.length).to.equal(72);
      expect(data.slice(0, 10)).to.equal(Keys.Bounty);
      expect(ethers.hexlify(bytes.slice(4, 8))).to.equal("0x00000040");
    });

    it("finish reverts EmptyRequest when writer is unused", async () => {
      await expect(helper.testWriterFinishIncomplete()).to.be.revertedWithCustomError(helper, "EmptyRequest");
    });

    it("finish truncates to actual written length", async () => {
      const data: string = await helper.testWriterFinish(asset, meta, amount);
      expect(ethers.getBytes(data).length).to.equal(104);
    });
  });

  describe("Cursor helpers", () => {
    const asset = ethers.zeroPadValue("0xaa", 32);
    const meta = ethers.zeroPadValue("0xbb", 32);
    const amount = 9999n;

    it("primeRun sets key, count, len, and bound for a prime run", async () => {
      const a = encodeAmountBlock(asset, meta, 1n);
      const b = encodeAmountBlock(asset, meta, 2n);
      const c = encodeBalanceBlock(asset, meta, 3n);
      const source = concat(a, b, c);
      const [key, count, quotient, offset, i, len, bound] = await helper.testPrimeRun(source, 1n);
      expect(key).to.equal(Keys.Amount);
      expect(count).to.equal(2n);
      expect(quotient).to.equal(2n);
      expect(offset).to.equal(0n);
      expect(i).to.equal(0n);
      expect(len).to.equal(BigInt(ethers.getBytes(source).length));
      expect(bound).to.equal(BigInt(ethers.getBytes(concat(a, b)).length));
    });

    it("primeRun reverts ZeroGroup when group is 0", async () => {
      const source = encodeAmountBlock(asset, meta, amount);
      await expect(helper.testPrimeRun(source, 0n))
        .to.be.revertedWithCustomError(helper, "ZeroGroup");
    });

    it("peek returns the next key and payload length", async () => {
      const source = encodeBalanceBlock(asset, meta, amount);
      expect(await helper.testPeek(source, 0n)).to.deep.equal([Keys.Balance, 96n]);
    });

    it("countRun counts consecutive matching blocks from i", async () => {
      const a = encodeAmountBlock(asset, meta, 1n);
      const b = encodeAmountBlock(asset, meta, 2n);
      const c = encodeBalanceBlock(asset, meta, 3n);
      const [count, next] = await helper.testCountRun(concat(a, b, c), 0n, Keys.Amount);
      expect(count).to.equal(2n);
      expect(next).to.equal(BigInt(ethers.getBytes(concat(a, b)).length));
    });

    it("slice creates a subcursor over the requested range", async () => {
      const a = encodeAssetBlock(asset, meta);
      const b = encodeRecipientBlock(encodeUserAccount("0x12"));
      const source = concat(a, b);
      const from = BigInt(ethers.getBytes(a).length);
      const to = BigInt(ethers.getBytes(source).length);
      const [offset, i, len, bound] = await helper.testSlice(source, from, to);
      expect(offset).to.equal(from);
      expect(i).to.equal(0n);
      expect(len).to.equal(BigInt(ethers.getBytes(b).length));
      expect(bound).to.equal(0n);
    });

    it("slice reverts MalformedBlocks when the requested range is invalid", async () => {
      const source = concat(encodeAssetBlock(asset, meta), encodeRecipientBlock(encodeUserAccount("0x12")));
      await expect(helper.testSlice(source, 10n, 9n))
        .to.be.revertedWithCustomError(helper, "MalformedBlocks");
      await expect(helper.testSlice(source, 0n, BigInt(ethers.getBytes(source).length + 1)))
        .to.be.revertedWithCustomError(helper, "MalformedBlocks");
    });

    it("bundle returns a relative subcursor and advances the source cursor", async () => {
      const route = encodeRecipientBlock(encodeUserAccount("0x12"));
      const minimum = encodeMinimumBlock(asset, meta, amount);
      const bundle = encodeBundleBlock(route, minimum);
      const [inputI, end] = await helper.testBundle(bundle);
      expect(inputI).to.equal(8n);
      expect(end).to.equal(BigInt(ethers.getBytes(bundle).length));
    });

    it("resume moves the cursor to the provided end offset", async () => {
      const source = concat(encodeAssetBlock(asset, meta), encodeAssetBlock(meta, asset));
      expect(await helper.testResume(source, BigInt(ethers.getBytes(source).length))).to.equal(BigInt(ethers.getBytes(source).length));
    });

    it("resume reverts IncompleteCursor when the cursor has passed the end offset", async () => {
      const source = concat(encodeAssetBlock(asset, meta), encodeAssetBlock(meta, asset));
      const end = BigInt(ethers.getBytes(source).length - ethers.getBytes(encodeAssetBlock(meta, asset)).length);
      await expect(helper.testResumePastEnd(source, end))
        .to.be.revertedWithCustomError(helper, "IncompleteCursor");
    });

    it("ensure succeeds when the cursor is exactly at the requested offset", async () => {
      const source = concat(encodeAssetBlock(asset, meta), encodeAssetBlock(meta, asset));
      const at = BigInt(ethers.getBytes(source).length);
      expect(await helper.testEnsure(source, at)).to.equal(at);
    });

    it("ensure reverts IncompleteCursor when the cursor is not exactly at the requested offset", async () => {
      const source = concat(encodeAssetBlock(asset, meta), encodeAssetBlock(meta, asset));
      const at = BigInt(ethers.getBytes(encodeAssetBlock(asset, meta)).length);
      await expect(helper.testEnsureMismatch(source, at))
        .to.be.revertedWithCustomError(helper, "IncompleteCursor");
    });

    it("list returns the next offset and advances past the list header", async () => {
      const item1 = encodeAssetBlock(asset, meta);
      const item2 = encodeAssetBlock(meta, asset);
      const list = encodeListBlock(item1, item2);
      const [inputI, next] = await helper.testList(list);
      expect(inputI).to.equal(8n);
      expect(next).to.equal(BigInt(ethers.getBytes(list).length));
    });

    it("list(group) primes the list payload on the same cursor", async () => {
      const item1 = encodeAssetBlock(asset, meta);
      const item2 = encodeAssetBlock(meta, asset);
      const list = encodeListBlock(item1, item2);
      const [inputI, bound, count, next] = await helper.testListPrime(list, 1n);
      expect(inputI).to.equal(8n);
      expect(bound).to.equal(BigInt(ethers.getBytes(list).length));
      expect(count).to.equal(2n);
      expect(next).to.equal(BigInt(ethers.getBytes(list).length));
    });

    it("list(group, requiredCount) succeeds when the raw count matches", async () => {
      const item1 = encodeAssetBlock(asset, meta);
      const item2 = encodeAssetBlock(meta, asset);
      const list = encodeListBlock(item1, item2);
      const [inputI, bound, next] = await helper.testListPrimeRequired(list, 1n, 2n);
      expect(inputI).to.equal(8n);
      expect(bound).to.equal(BigInt(ethers.getBytes(list).length));
      expect(next).to.equal(BigInt(ethers.getBytes(list).length));
    });

    it("list(group, requiredCount) reverts BadRatio when the count mismatches", async () => {
      const item1 = encodeAssetBlock(asset, meta);
      const item2 = encodeAssetBlock(meta, asset);
      const list = encodeListBlock(item1, item2);
      await expect(helper.testListPrimeRequired(list, 1n, 1n))
        .to.be.revertedWithCustomError(helper, "BadRatio");
    });

    it("list(group) reverts IncompleteCursor when trailing blocks remain in the list payload", async () => {
      const item1 = encodeAssetBlock(asset, meta);
      const item2 = encodeAssetBlock(meta, asset);
      const extra = encodeRecipientBlock(encodeUserAccount("0x12"));
      const list = encodeListBlock(item1, item2, extra);
      await expect(helper.testListPrime(list, 1n))
        .to.be.revertedWithCustomError(helper, "IncompleteCursor");
    });

    it("unpackStep consumes the block and returns the trailing request", async () => {
      const req = encodeAmountBlock(asset, meta, amount);
      const step = encodeStepBlock(7n, 55n, req);
      const [target, value, outReq, i] = await helper.testUnpackStep(step);
      expect(target).to.equal(7n);
      expect(value).to.equal(55n);
      expect(outReq).to.equal(req);
      expect(i).to.equal(BigInt(ethers.getBytes(step).length));
    });

    it("unpackBounds preserves signed min and max values", async () => {
      const source = encodeBoundsBlock(-5n, 42n);
      expect(await helper.testUnpackBounds(source)).to.deep.equal([-5n, 42n]);
    });

    it("unpackMinimums returns the two minimum amounts", async () => {
      const source = encodeMinimumsBlock(11n, 22n);
      expect(await helper.testUnpackMinimums(source)).to.deep.equal([11n, 22n]);
    });

    it("unpackMaximums returns the two maximum amounts", async () => {
      const source = encodeMaximumsBlock(33n, 44n);
      expect(await helper.testUnpackMaximums(source)).to.deep.equal([33n, 44n]);
    });

    it("unpackFee returns the fee amount", async () => {
      const source = encodeFeeBlock(77n);
      expect(await helper.testUnpackFee(source)).to.equal(77n);
    });

    it("unpackPath returns the raw path payload", async () => {
      const path = "0x1234567890abcdef";
      const source = encodePathBlock(path);
      expect(await helper.testUnpackPath(source)).to.equal(path);
    });

    it("requireAmount validates and advances by one fixed-size block", async () => {
      const source = encodeAmountBlock(asset, meta, amount);
      const [out, i] = await helper.testRequireAmount(source, asset, meta);
      expect(out).to.equal(amount);
      expect(i).to.equal(104n);
    });

    it("requireAuth validates and advances by the auth block size", async () => {
      const proof = ethers.concat(["0x" + "11".repeat(20), "0x" + "22".repeat(65)]);
      const source = encodeAuthBlock(77n, 123456n, proof);
      const [deadline, outProof, i] = await helper.testRequireAuth(source, 77n);
      expect(deadline).to.equal(123456n);
      expect(outProof).to.equal(proof);
      expect(i).to.equal(149n);
    });

    it("complete reverts ZeroCursor when prime run is empty", async () => {
      await expect(helper.testCursorCompleteEmpty("0x", 1n))
        .to.be.revertedWithCustomError(helper, "ZeroCursor");
    });

    it("complete reverts IncompleteCursor when prime input remains", async () => {
      const source = concat(encodeBalanceBlock(asset, meta, 1n), encodeBalanceBlock(asset, meta, 2n));
      await expect(helper.testCursorCompletePartial(source, 1n))
        .to.be.revertedWithCustomError(helper, "IncompleteCursor");
    });

    it("complete succeeds after the prime run is consumed", async () => {
      const source = concat(encodeBalanceBlock(asset, meta, 1n), encodeBalanceBlock(asset, meta, 2n));
      expect(await helper.testCursorCompleteConsumed(source, 1n)).to.equal(true);
    });

    it("end reverts IncompleteCursor when bytes remain in the cursor region", async () => {
      const source = concat(encodeBalanceBlock(asset, meta, 1n), encodeBalanceBlock(asset, meta, 2n));
      await expect(helper.testCursorEndPartial(source))
        .to.be.revertedWithCustomError(helper, "IncompleteCursor");
    });

    it("end succeeds after the full cursor region is consumed", async () => {
      const source = concat(encodeBalanceBlock(asset, meta, 1n), encodeBalanceBlock(asset, meta, 2n));
      expect(await helper.testCursorEndConsumed(source)).to.equal(true);
    });

    it("recipientAfter returns the tail recipient or backup", async () => {
      const backup = encodeUserAccount("0x99");
      const recipient = encodeUserAccount("0x12");
      const source = concat(
        encodeAmountBlock(asset, meta, amount),
        encodeRecipientBlock(recipient)
      );
      expect(await helper.testRecipientAfter(source, 1n, backup)).to.equal(recipient);
      expect(await helper.testRecipientAfter(encodeAmountBlock(asset, meta, amount), 1n, backup)).to.equal(backup);
    });

    it("nodeAfter returns the tail node or backup", async () => {
      const source = concat(
        encodeAmountBlock(asset, meta, amount),
        encodeNodeBlock(42n)
      );
      expect(await helper.testNodeAfter(source, 1n, 7n)).to.equal(42n);
      expect(await helper.testNodeAfter(encodeAmountBlock(asset, meta, amount), 1n, 7n)).to.equal(7n);
    });

    it("authLast returns hash, deadline, and proof for a valid trailing auth", async () => {
      const cid = 77n;
      const deadline = 123456n;
      const proof = ethers.concat(["0x" + "11".repeat(20), "0x" + "22".repeat(65)]);
      const amountBlock = encodeAmountBlock(asset, meta, amount);
      const auth = encodeAuthBlock(cid, deadline, proof);
      const source = concat(amountBlock, auth);

      const [hash, outDeadline, outProof] = await helper.testAuthLast(source, 1n, cid);
      expect(outDeadline).to.equal(deadline);
      expect(outProof).to.equal(proof);

      const sourceBytes = ethers.getBytes(source);
      const expectedHash = ethers.keccak256(sourceBytes.slice(0, sourceBytes.length - 85));
      expect(hash).to.equal(expectedHash);
    });

    it("authLast reverts UnexpectedValue when cid mismatches", async () => {
      const proof = ethers.concat(["0x" + "11".repeat(20), "0x" + "22".repeat(65)]);
      const source = concat(encodeAmountBlock(asset, meta, amount), encodeAuthBlock(77n, 123456n, proof));
      await expect(helper.testAuthLast(source, 1n, 88n))
        .to.be.revertedWithCustomError(helper, "UnexpectedValue");
    });

    it("authLast reverts MalformedBlocks when trailing auth is missing", async () => {
      await expect(helper.testAuthLast(encodeAmountBlock(asset, meta, amount), 1n, 77n))
        .to.be.revertedWithCustomError(helper, "MalformedBlocks");
    });

    it("accepts matching 2:1 ratio between state and request prime runs", async () => {
      const state = concat(
        encodeBalanceBlock(asset, meta, 1n),
        encodeBalanceBlock(asset, meta, 2n),
      );
      const request = encodeAmountBlock(asset, meta, 3n);

      expect(await operation.testCheckCursorRatio(state, 2n, request, 1n)).to.equal(true);
    });

    it("reverts BadRatio when state and request prime runs break the expected ratio", async () => {
      const state = concat(
        encodeBalanceBlock(asset, meta, 1n),
        encodeBalanceBlock(asset, meta, 2n),
        encodeBalanceBlock(asset, meta, 3n),
      );
      const request = encodeAmountBlock(asset, meta, 4n);

      await expect(operation.testCheckCursorRatio(state, 2n, request, 1n))
        .to.be.revertedWithCustomError(operation, "BadRatio");
    });
  });

});
