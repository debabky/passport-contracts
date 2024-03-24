import { ethers } from "hardhat";
import { BigNumberish } from "ethers";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { Reverter, deployPoseidons, getPoseidon, poseidonHash } from "@/test/helpers/";

import { Voting, VerifierMock } from "@ethers-v6";

import { Voting as VotingNS } from "@/generated-types/ethers/contracts/voting/Voting";
import { VerifierHelper } from "@/generated-types/ethers/contracts/voting/Voting";

const registrationMerkleRoot = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

describe("Voting", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let voting: Voting;
  let verifierMock: VerifierMock;

  let votingConfig: VotingNS.VotingParamsStruct;

  before("setup", async () => {
    [OWNER] = await ethers.getSigners();

    await deployPoseidons(OWNER, [2, 3, 5], false);

    const Voting = await ethers.getContractFactory("Voting", {
      libraries: {
        PoseidonUnit5L: await (await getPoseidon(5)).getAddress(),
      },
    });
    const VerifierMock = await ethers.getContractFactory("VerifierMock");

    voting = await Voting.deploy();
    verifierMock = await VerifierMock.deploy();

    votingConfig = {
      candidates: ["1", "2", "3", "4", "5"],
      startTimestamp: await time.latest(),
      duration: 1000,
    };

    await voting.__Voting_init(registrationMerkleRoot, await verifierMock.getAddress(), votingConfig);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#vote", () => {
    it("should vote", async () => {
      const candidates = <[BigNumberish, BigNumberish, BigNumberish, BigNumberish, BigNumberish]>[
        "5",
        "4",
        "3",
        "2",
        "1",
      ];
      const formattedProof: VerifierHelper.ProofPointsStruct = {
        a: [0, 0],
        b: [
          [0, 0],
          [0, 0],
        ],
        c: [0, 0],
      };
      const nullifierHash_ = ethers.hexlify(ethers.randomBytes(32));

      await voting.vote(candidates, formattedProof, nullifierHash_);

      const info = await voting.getVotingInfo();

      expect(info.votesPerCandidates).to.deep.equal(["0", "1", "2", "3", "4"]);
      expect(info.candidates).to.deep.equal(["1", "2", "3", "4", "5"]);
    });
  });
});
