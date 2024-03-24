import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { RSAPSSVerifierMock } from "@ethers-v6";

describe("RSAPSS", () => {
  const reverter = new Reverter();

  let rsapssVerifier: RSAPSSVerifierMock;

  before("setup", async () => {
    const RSAPSSVerifierMock = await ethers.getContractFactory("RSAPSSVerifierMock");

    rsapssVerifier = await RSAPSSVerifierMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("mgf", () => {
    it("should correctly encode", async () => {
      const someBytes = ethers.hexlify(ethers.toUtf8Bytes("I like to swim."));
      const len = 20;

      expect(await rsapssVerifier.mgf(someBytes, len)).to.eq(
        ethers.hexlify(
          Uint8Array.from([
            170, 251, 101, 210, 23, 101, 10, 242, 193, 163, 174, 148, 104, 138, 228, 245, 52, 234, 0, 195,
          ]),
        ),
      );
    });
  });

  describe("verify", () => {
    it("should verify the RSA PSS signature", async () => {
      const msg = "abcdefghijklmnopqrstuvwxyz\n";

      const signature =
        "0x5f61322356c771dbdd52af5d1276c3e634b768f8d947dde7d0ef7778b962b12e342eb23404152c43759433a6c88c2e1247efd7afa3419e8846d0a73969ff3d4fb529d7fb2451be887530ce33a0ddc28daf0dde638fe609d1bcd4b2bcf23c5bb45a44e0aca49a64f86cb4f3f36c55c84cf23583ab5f00c590f1d860930c885eb82e0ee4095e3e96052fc0be380479246816399f37f1c2534551447e261b2af07410a2bad838e33abb8da91781eaa6307c3bc91d5f09c9e7a49fe204e711eb25bf13e570fbb546cac99039cd8342c16d3ced13550e630f0b7e64987c6d5256692f7ddc8417415c81ff16e66b6e0d9a19b35c7467dc81bfb47e18b9fc000c41b530";
      const exponent = "0x010001";
      const modulus =
        "0xbbb19fe79d2e4f99571be125d8baaa78d7cf65aa3ffc164eaaa5b10ab262ffa0346b432cc5ca1f6f6094cb07ce709cc4b4fec01a63082fd9696ffe88e517eaa69302061b72c1c8dab5018e90f8eaa94c71e5e831a49086a729a1e2c80c2e8d08c9fdbf003c5a32dcd5ca965596b0afe80542d59d3d8deaddd38dddca302dea7dfd0742f1dd5edf7b551b2935ed9b681145501d2948a2ab77be01159f63a17e9b02b4185fc24ec8b2c4acef62902c9dd23328d30ee74d5abd7efc0e3a6568c7a91c9f965e59ad1fe5a2014348044ba4c8527733935849fe6716234bf0c6191e3864a873eff23e57a2ed8f94de80ccbed6891c74a8b13daa318f5d82ed217c75cb";

      const hexMsg = ethers.hexlify(ethers.toUtf8Bytes(msg));

      expect(await rsapssVerifier.verify(hexMsg, signature, exponent, modulus)).to.be.true;
    });

    it("should verify passport signature", async () => {
      const challenge = "0x5119311531111100";

      const signature =
        "0xA997B163DC908BC84B3B804750B9F37268F75F2B716D3BF040398FCA7B7EF1FA12BF6A737D8714C682CB2FC8E0FC9E9149FA8DC811EF621F66BB25FE2A72751E7CCEB090B1D9B1AD77565D7F286AE5B9D17C55A3C950F550DD242EB141BEDEB9E5D4137C4828976D0F2B7AE9070FBB38D0F09D619E16CFD6E4E6203BE3A4E1BB";
      const exponent = "0x010001";
      const modulus =
        "0xd21f63969effab33383ab4f8a3955739ad8ae14879d17509b4f444284e52de3956ed40e5245ea8d9db9540c7ed21aa5ca17fb84f1651d218d183a19b017d80335dbcc2e8c5c2ba1705235ac897f942190d2a2ad60119178ef2b555ea5772c65a32bf42699ee512949235702c7b9d2176e498fef69be5651f8434686f7aa1adf7";

      expect(await rsapssVerifier.verifyPassport(challenge, signature, exponent, modulus)).to.be.true;
    });
  });
});
