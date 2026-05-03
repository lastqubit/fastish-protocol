import { expect } from "chai";
import { deploy, getProvider, getSigner } from "./helpers/setup.js";
import {
  concat,
  encodeAmountBlock,
  encodeNodeBlock,
  encodeTxBlock,
  encodeUserAccount,
} from "./helpers/blocks.js";
import { ethers } from "ethers";
import "./helpers/matchers.js";

describe("Remote Entrypoints", () => {
  let host: Awaited<ReturnType<typeof deploy>>;

  before(async () => {
    const signer = await getSigner(0);
    const commander = await signer.getAddress();
    host = await deploy("TestRemoteHost", commander);
    const trustedRemote = await callerHost(1);
    const adminAccount: string = await host.getAdminAccount();
    await host.authorize({ account: adminAccount, meta: ethers.ZeroHash, state: "0x", request: encodeNodeBlock(trustedRemote) });
  });

  it("emits Remote discovery events with id as the second argument", async () => {
    const tx = host.deploymentTransaction();
    expect(tx).to.not.equal(null);

    await expect(tx!)
      .to.emit(host, "Remote")
      .withArgs(
        await host.host(),
        await host.getRemoteAllowanceId(),
        "remoteAllowance",
        "amount(bytes32 asset, bytes32 meta, uint amount)",
        false,
      );
  });

  async function callAs(
    signerIndex: number,
    method: "remoteAllowance(bytes)" | "remoteAssetPull(bytes)" | "remoteSettle(bytes)",
    request = "0x"
  ) {
    const signer = await getSigner(signerIndex);
    return (host.connect(signer) as any)[method](request);
  }

  async function callerHost(signerIndex: number) {
    const signer = await getSigner(signerIndex);
    const addr = await signer.getAddress();
    const provider = await getProvider();
    const network = await provider.getNetwork();
    const HOST_PREFIX = 0x20010201n;
    return (HOST_PREFIX << 224n) | (network.chainId << 192n) | BigInt(addr);
  }

  describe("remoteAllowance", () => {
    const method = "remoteAllowance(bytes)";
    const asset = ethers.zeroPadValue("0xa0", 32);
    const meta = ethers.zeroPadValue("0xb0", 32);

    it("emits RemoteAllowanceCalled for a single AMOUNT block scoped to the caller host", async () => {
      const remote = await callerHost(1);
      const tx = await callAs(1, method, encodeAmountBlock(asset, meta, 123n));
      await expect(tx).to.emit(host, "RemoteAllowanceCalled").withArgs(remote, asset, meta, 123n);
    });

    it("emits RemoteAllowanceCalled for each AMOUNT block when multiple are present", async () => {
      const remote = await callerHost(1);
      const asset2 = ethers.zeroPadValue("0xc0", 32);
      const tx = await callAs(
        1,
        method,
        concat(
          encodeAmountBlock(asset, meta, 123n),
          encodeAmountBlock(asset2, meta, 456n),
        )
      );
      await expect(tx).to.emit(host, "RemoteAllowanceCalled").withArgs(remote, asset, meta, 123n);
      await expect(tx).to.emit(host, "RemoteAllowanceCalled").withArgs(remote, asset2, meta, 456n);
    });

    it("returns empty bytes after processing amount blocks", async () => {
      const signer = await getSigner(1);
      const result: string = await (host.connect(signer) as any)[method].staticCall(encodeAmountBlock(asset, meta, 123n));
      expect(result).to.equal("0x");
    });

    it("reverts CommanderNotAllowed for the commander", async () => {
      await expect(callAs(0, method, encodeAmountBlock(asset, meta, 123n)))
        .to.be.revertedWithCustomError(host, "CommanderNotAllowed");
    });

    it("reverts UnauthorizedCaller for an untrusted caller", async () => {
      await expect(callAs(2, method, encodeAmountBlock(asset, meta, 123n)))
        .to.be.revertedWithCustomError(host, "UnauthorizedCaller");
    });

    it("reverts ZeroCursor when request is empty", async () => {
      await expect(callAs(1, method))
        .to.be.revertedWithCustomError(host, "ZeroCursor");
    });
  });

  describe("remoteAssetPull", () => {
    const method = "remoteAssetPull(bytes)";
    const asset = ethers.zeroPadValue("0xaa", 32);
    const meta = ethers.zeroPadValue("0xbb", 32);

    it("emits RemoteAssetPullCalled for a single AMOUNT block", async () => {
      const remote = await callerHost(1);
      const tx = await callAs(1, method, encodeAmountBlock(asset, meta, 123n));
      await expect(tx).to.emit(host, "RemoteAssetPullCalled").withArgs(remote, asset, meta, 123n);
    });

    it("emits RemoteAssetPullCalled for each AMOUNT block when multiple are present", async () => {
      const remote = await callerHost(1);
      const asset2 = ethers.zeroPadValue("0xcc", 32);
      const tx = await callAs(
        1,
        method,
        concat(
          encodeAmountBlock(asset, meta, 123n),
          encodeAmountBlock(asset2, meta, 456n),
        )
      );
      await expect(tx).to.emit(host, "RemoteAssetPullCalled").withArgs(remote, asset, meta, 123n);
      await expect(tx).to.emit(host, "RemoteAssetPullCalled").withArgs(remote, asset2, meta, 456n);
    });

    it("returns empty bytes after processing amount blocks", async () => {
      const signer = await getSigner(1);
      const result: string = await (host.connect(signer) as any)[method].staticCall(encodeAmountBlock(asset, meta, 123n));
      expect(result).to.equal("0x");
    });

    it("reverts CommanderNotAllowed for the commander", async () => {
      await expect(callAs(0, method, encodeAmountBlock(asset, meta, 123n)))
        .to.be.revertedWithCustomError(host, "CommanderNotAllowed");
    });

    it("reverts UnauthorizedCaller for an untrusted caller", async () => {
      await expect(callAs(2, method, encodeAmountBlock(asset, meta, 123n)))
        .to.be.revertedWithCustomError(host, "UnauthorizedCaller");
    });

    it("reverts ZeroCursor when request is empty", async () => {
      await expect(callAs(1, method))
        .to.be.revertedWithCustomError(host, "ZeroCursor");
    });
  });

  describe("remoteSettle", () => {
    const method = "remoteSettle(bytes)";
    const from_ = encodeUserAccount("0x11");
    const to_ = encodeUserAccount("0x22");
    const asset = ethers.zeroPadValue("0xaa", 32);
    const meta = ethers.zeroPadValue("0xbb", 32);

    it("emits RemoteSettleCalled for a single TX block", async () => {
      const tx = await callAs(1, method, encodeTxBlock(from_, to_, asset, meta, 123n));
      await expect(tx).to.emit(host, "RemoteSettleCalled").withArgs(from_, to_, asset, meta, 123n);
    });

    it("emits RemoteSettleCalled for each TX block when multiple are present", async () => {
      const from2 = encodeUserAccount("0x33");
      const tx = await callAs(
        1,
        method,
        concat(
          encodeTxBlock(from_, to_, asset, meta, 123n),
          encodeTxBlock(from2, to_, asset, meta, 456n),
        )
      );
      await expect(tx).to.emit(host, "RemoteSettleCalled").withArgs(from_, to_, asset, meta, 123n);
      await expect(tx).to.emit(host, "RemoteSettleCalled").withArgs(from2, to_, asset, meta, 456n);
    });

    it("returns empty bytes after processing tx blocks", async () => {
      const signer = await getSigner(1);
      const result: string = await (host.connect(signer) as any)[method].staticCall(encodeTxBlock(from_, to_, asset, meta, 123n));
      expect(result).to.equal("0x");
    });

    it("reverts UnauthorizedCaller for an untrusted caller", async () => {
      await expect(callAs(2, method, encodeTxBlock(from_, to_, asset, meta, 123n)))
        .to.be.revertedWithCustomError(host, "UnauthorizedCaller");
    });

    it("reverts ZeroCursor when request is empty", async () => {
      await expect(callAs(1, method))
        .to.be.revertedWithCustomError(host, "ZeroCursor");
    });
  });
});


