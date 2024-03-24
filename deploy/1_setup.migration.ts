import { ethers } from "hardhat";
import { Deployer } from "@solarity/hardhat-migrate";
import { Registration__factory, VotingFactory__factory, Voting__factory } from "@ethers-v6";

export = async (deployer: Deployer) => {
  const registration = await deployer.deploy(Registration__factory);
  const votingFactory = await deployer.deploy(VotingFactory__factory);
  const votingImpl = await deployer.deploy(Voting__factory);

  const registationVerifier = ethers.hexlify(ethers.randomBytes(20));
  const votingVerifier = ethers.hexlify(ethers.randomBytes(20));
  const icaoMasterTreeMerkleRoot = ethers.hexlify(ethers.randomBytes(32));

  await registration.__Registration_init(80, registationVerifier, icaoMasterTreeMerkleRoot);
  await votingFactory.__VotingFactory_init(
    await registration.getAddress(),
    await votingImpl.getAddress(),
    votingVerifier,
  );
};
