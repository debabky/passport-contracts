import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { Reverter, deployPoseidons, getPoseidon, poseidonHash } from "@/test/helpers/";

import { VotingFactory, Voting, Registration, VerifierMock } from "@ethers-v6";

import { Voting as VotingNS } from "@/generated-types/ethers/contracts/voting/Voting";

const ICAO_MERKLE_ROOT = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

describe("Voting", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let voting: Voting;
  let votingFactory: VotingFactory;
  let registration: Registration;
  let verifierMock: VerifierMock;

  before("setup", async () => {
    [OWNER] = await ethers.getSigners();

    await deployPoseidons(OWNER, [2, 3, 5], false);

    const Registration = await ethers.getContractFactory("Registration", {
      libraries: {
        PoseidonUnit2L: await (await getPoseidon(2)).getAddress(),
        PoseidonUnit3L: await (await getPoseidon(3)).getAddress(),
        PoseidonUnit5L: await (await getPoseidon(5)).getAddress(),
      },
    });
    const Voting = await ethers.getContractFactory("Voting", {
      libraries: {
        PoseidonUnit5L: await (await getPoseidon(5)).getAddress(),
      },
    });
    const VotingFactory = await ethers.getContractFactory("VotingFactory");
    const VerifierMock = await ethers.getContractFactory("VerifierMock");

    registration = await Registration.deploy();
    votingFactory = await VotingFactory.deploy();
    voting = await Voting.deploy();
    verifierMock = await VerifierMock.deploy();

    await registration.__Registration_init(80, await verifierMock.getAddress(), ICAO_MERKLE_ROOT);
    await votingFactory.__VotingFactory_init(
      await registration.getAddress(),
      await voting.getAddress(),
      await verifierMock.getAddress(),
    );

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#createVoting", () => {
    it("should create new voting", async () => {
      let votingConfig: VotingNS.VotingParamsStruct = {
        candidates: ["1", "2", "3", "4", "5"],
        startTimestamp: await time.latest(),
        duration: 1000,
      };

      await votingFactory.createVoting(votingConfig);

      const voting = await ethers.getContractAt("Voting", (await votingFactory.getVotings(0, 5))[0]);

      expect(await voting.verifier()).to.eq(await verifierMock.getAddress());
    });
  });
});
