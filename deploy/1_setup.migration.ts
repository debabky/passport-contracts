import { ethers } from "hardhat";
import { Deployer, Reporter } from "@solarity/hardhat-migrate";
import { Registration__factory, VotingFactory__factory, Voting__factory, VerifierMock__factory } from "@ethers-v6";

export = async (deployer: Deployer) => {
  const registration = await deployer.deploy(Registration__factory);
  const votingFactory = await deployer.deploy(VotingFactory__factory);
  const votingImpl = await deployer.deploy(Voting__factory);

  const verifierMock = await deployer.deploy(VerifierMock__factory);

  const icaoMasterTreeMerkleRoot = ethers.hexlify(ethers.randomBytes(32));

  await registration.__Registration_init(80, await verifierMock.getAddress(), icaoMasterTreeMerkleRoot);
  await votingFactory.__VotingFactory_init(
    await registration.getAddress(),
    await votingImpl.getAddress(),
    await verifierMock.getAddress(),
  );

  Reporter.reportContracts(
    ["VotingFactory", `${await votingFactory.getAddress()}`],
    ["Registration", `${await registration.getAddress()}`],
  );
};
