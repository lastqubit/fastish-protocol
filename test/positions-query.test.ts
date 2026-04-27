import { expect } from "chai";
import { deploy } from "./helpers/setup.js";
import {
  concat,
  encodeLookupBlock,
  encodeResponseBlock,
  pad32,
} from "./helpers/blocks.js";

describe("GetPosition", () => {
  it("returns one response block for one asset query", async () => {
    const query = await deploy("TestGetPositionQuery");
    const asset = await query.firstAsset();
    const meta = await query.firstMeta();
    const account = pad32(0n);
    const host = await query.host();

    const result: string = await query.getPosition.staticCall(
      encodeLookupBlock(host, account, asset, meta),
    );

    expect(result).to.equal(encodeResponseBlock(pad32(11n)));
  });

  it("maps multiple asset blocks into matching response blocks in order", async () => {
    const query = await deploy("TestGetPositionQuery");
    const firstAsset = await query.firstAsset();
    const firstMeta = await query.firstMeta();
    const secondAsset = await query.secondAsset();
    const secondMeta = await query.secondMeta();
    const account = pad32(0n);
    const host = await query.host();

    const request = concat(
      encodeLookupBlock(host, account, firstAsset, firstMeta),
      encodeLookupBlock(host, account, secondAsset, secondMeta),
    );

    const result: string = await query.getPosition.staticCall(request);

    expect(result).to.equal(concat(
      encodeResponseBlock(pad32(11n)),
      encodeResponseBlock(pad32(22n)),
    ));
  });
});
