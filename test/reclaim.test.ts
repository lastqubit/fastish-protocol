import { expect } from "chai";
import { ethers } from "ethers";
import { deploy, getSigner } from "./helpers/setup.js";
import { concat, encodeBalanceBlock, encodeCustodyBlock } from "./helpers/blocks.js";
import "./helpers/matchers.js";

describe("Reclaim", () => {
  let host: Awaited<ReturnType<typeof deploy>>;
  let userAccount: string;
  const reclaimMethod = "reclaim((uint256,bytes32,bytes,bytes))";

  before(async () => {
    const signer = await getSigner(0);
    const commander = await signer.getAddress();
    host = await deploy("TestReclaimHost", commander);

    const USER_PREFIX = 0x20010202n;
    userAccount = ethers.zeroPadValue(
      ethers.toBeHex((USER_PREFIX << 224n) | (BigInt(commander) << 32n)),
      32
    );
  });

  function ctx(overrides: Partial<{ target: bigint; account: string; state: string; request: string }> = {}) {
    return {
      target:  overrides.target  ?? 0n,
      account: overrides.account ?? userAccount,
      state:   overrides.state   ?? "0x",
      request: overrides.request ?? "0x",
    };
  }

  async function callAs(signerIndex: number, ...args: unknown[]) {
    const signer = await getSigner(signerIndex);
    return (host.connect(signer) as any)[reclaimMethod](...args);
  }

  // ── Happy path ─────────────────────────────────────────────────────────────

  it("emits ReclaimCalled for a single CUSTODY block in state", async () => {
    const remoteHost = 999n;
    const asset = ethers.zeroPadValue("0xa1", 32);
    const meta  = ethers.ZeroHash;
    const state = encodeCustodyBlock(remoteHost, asset, meta, 100n);
    const tx = await callAs(0, ctx({ state }));
    await expect(tx).to.emit(host, "ReclaimCalled")
      .withArgs(remoteHost, userAccount, asset, meta, 100n);
  });

  it("returns one BALANCE block for a single CUSTODY block", async () => {
    const asset = ethers.zeroPadValue("0xb1", 32);
    const meta  = ethers.ZeroHash;
    const state = encodeCustodyBlock(42n, asset, meta, 200n);
    const result: string = await (host as any)[reclaimMethod].staticCall(ctx({ state }));
    expect(result).to.equal(encodeBalanceBlock(asset, meta, 200n));
  });

  it("emits ReclaimCalled for each CUSTODY block when multiple are present", async () => {
    const asset1 = ethers.zeroPadValue("0xc1", 32);
    const asset2 = ethers.zeroPadValue("0xc2", 32);
    const meta   = ethers.ZeroHash;
    const state  = concat(
      encodeCustodyBlock(1n, asset1, meta, 10n),
      encodeCustodyBlock(2n, asset2, meta, 20n)
    );
    const tx = await callAs(0, ctx({ state }));
    await expect(tx).to.emit(host, "ReclaimCalled").withArgs(1n, userAccount, asset1, meta, 10n);
    await expect(tx).to.emit(host, "ReclaimCalled").withArgs(2n, userAccount, asset2, meta, 20n);
  });

  it("returns one BALANCE block per CUSTODY block", async () => {
    const asset1 = ethers.zeroPadValue("0xd1", 32);
    const asset2 = ethers.zeroPadValue("0xd2", 32);
    const meta   = ethers.ZeroHash;
    const state  = concat(
      encodeCustodyBlock(1n, asset1, meta, 10n),
      encodeCustodyBlock(2n, asset2, meta, 20n)
    );
    const result: string = await (host as any)[reclaimMethod].staticCall(ctx({ state }));
    expect(result).to.equal(concat(
      encodeBalanceBlock(asset1, meta, 10n),
      encodeBalanceBlock(asset2, meta, 20n)
    ));
  });

  // ── Target / access guards ─────────────────────────────────────────────────

  it("accepts the explicit reclaim command id as the target", async () => {
    const target = await host.getReclaimId();
    const state  = encodeCustodyBlock(1n, ethers.zeroPadValue("0xe1", 32), ethers.ZeroHash, 1n);
    const tx = await callAs(0, ctx({ target, state }));
    await expect(tx).to.emit(host, "ReclaimCalled");
  });

  it("reverts UnexpectedEndpoint for a wrong non-zero target", async () => {
    const state = encodeCustodyBlock(1n, ethers.zeroPadValue("0xf1", 32), ethers.ZeroHash, 1n);
    await expect(callAs(0, ctx({ target: 999n, state })))
      .to.be.revertedWithCustomError(host, "UnexpectedEndpoint");
  });

  it("reverts UnauthorizedCaller for an untrusted caller", async () => {
    const state = encodeCustodyBlock(1n, ethers.zeroPadValue("0xf2", 32), ethers.ZeroHash, 1n);
    await expect(callAs(1, ctx({ state })))
      .to.be.revertedWithCustomError(host, "UnauthorizedCaller");
  });

  // ── Error cases ────────────────────────────────────────────────────────────

  it("reverts InvalidBlock when state has no CUSTODY blocks", async () => {
    await expect(callAs(0, ctx()))
      .to.be.revertedWithCustomError(host, "InvalidBlock");
  });
});
