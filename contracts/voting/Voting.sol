// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {StringSet} from "@solarity/solidity-lib/libs/data-structures/StringSet.sol";
import {SetHelper} from "@solarity/solidity-lib/libs/arrays/SetHelper.sol";
import {VerifierHelper} from "@solarity/solidity-lib/libs/zkp/snarkjs/VerifierHelper.sol";

contract Voting is Initializable {
    using VerifierHelper for address;
    using StringSet for StringSet.Set;
    using SetHelper for *;

    enum VotingStatus {
        None,
        NotStarted,
        InProgress,
        Finished
    }

    struct VotingParams {
        uint256 startTimestamp;
        uint256 duration;
        string[] candidates;
    }

    struct VotingConfig {
        uint256 startTimestamp;
        uint256 endTimestamp;
        StringSet.Set candidates;
    }

    struct VotingPublicConfig {
        uint256 startTimestamp;
        uint256 endTimestamp;
        VotingStatus status;
        string[] candidates;
        uint256[] votesPerCandidates;
    }

    VotingConfig internal _votingConfig;

    bytes32 public registrationMerkleRoot;
    uint256 public registrationTimestamp;

    address public verifier;

    mapping(string => uint256) public votesForCandidates;
    mapping(uint256 => bool) public blindedNullifiers;

    function __Voting_init(
        bytes32 registrationMerkleRoot_,
        address verifier_,
        VotingParams calldata config_
    ) external initializer {
        registrationMerkleRoot = registrationMerkleRoot_;
        registrationTimestamp = block.timestamp;

        verifier = verifier_;

        _votingConfig.startTimestamp = config_.startTimestamp;
        _votingConfig.endTimestamp = config_.startTimestamp + config_.duration;
        _votingConfig.candidates.strictAdd(config_.candidates);
    }

    function vote(
        string calldata candidate_,
        VerifierHelper.ProofPoints memory zkPoints_,
        uint256 nullifierHash_
    ) external {
        uint256[] memory pubSignals_ = new uint256[](2);

        pubSignals_[0] = uint256(registrationMerkleRoot);
        pubSignals_[1] = nullifierHash_;

        require(_votingStatus() == VotingStatus.InProgress, "Voting: voting is not in progress");
        require(_votingConfig.candidates.contains(candidate_), "Voting: candidate doesn't exist");
        require(!blindedNullifiers[nullifierHash_], "Voting: nullifier is already blinded");
        require(verifier.verifyProof(pubSignals_, zkPoints_), "Voting: invalid zk proof");

        blindedNullifiers[nullifierHash_] = true;

        votesForCandidates[candidate_]++;
    }

    function getVotingInfo() external view returns (VotingPublicConfig memory info_) {
        info_.startTimestamp = _votingConfig.startTimestamp;
        info_.endTimestamp = _votingConfig.endTimestamp;
        info_.status = _votingStatus();

        info_.candidates = _votingConfig.candidates.values();

        info_.votesPerCandidates = new uint256[](info_.candidates.length);

        for (uint256 i = 0; i < info_.candidates.length; i++) {
            info_.votesPerCandidates[i] = votesForCandidates[info_.candidates[i]];
        }
    }

    function _votingStatus() internal view returns (VotingStatus) {
        if (block.timestamp >= _votingConfig.endTimestamp) {
            return VotingStatus.Finished;
        }

        if (block.timestamp < _votingConfig.startTimestamp) {
            return VotingStatus.NotStarted;
        }

        return VotingStatus.InProgress;
    }
}
