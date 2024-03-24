// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {PoseidonUnit5L} from "@iden3/contracts/lib/Poseidon.sol";

import {SetHelper} from "@solarity/solidity-lib/libs/arrays/SetHelper.sol";
import {VerifierHelper} from "@solarity/solidity-lib/libs/zkp/snarkjs/VerifierHelper.sol";

contract Voting is Initializable {
    using VerifierHelper for address;
    using EnumerableSet for EnumerableSet.UintSet;
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
        uint256[] candidates;
    }

    struct VotingConfig {
        uint256 startTimestamp;
        uint256 endTimestamp;
        EnumerableSet.UintSet candidates;
    }

    struct VotingPublicConfig {
        uint256 startTimestamp;
        uint256 endTimestamp;
        VotingStatus status;
        uint256[] candidates;
        uint256[] votesPerCandidates;
    }

    VotingConfig internal _votingConfig;

    bytes32 public registrationMerkleRoot;
    uint256 public registrationTimestamp;

    address public verifier;

    mapping(uint256 => uint256) public votesForCandidates;
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

    // FIXME: fixed number of candidates
    function vote(
        uint256[5] memory candidates_,
        VerifierHelper.ProofPoints memory zkPoints_,
        uint256 nullifierHash_
    ) external {
        uint256[] memory pubSignals_ = new uint256[](3);

        pubSignals_[0] = uint256(registrationMerkleRoot);
        pubSignals_[1] = nullifierHash_;
        pubSignals_[2] = PoseidonUnit5L.poseidon(candidates_);

        require(_votingStatus() == VotingStatus.InProgress, "Voting: voting is not in progress");
        require(
            _votingConfig.candidates.length() == candidates_.length,
            "Voting: should pass all the candidates"
        );
        require(!blindedNullifiers[nullifierHash_], "Voting: nullifier is already blinded");
        require(verifier.verifyProof(pubSignals_, zkPoints_), "Voting: invalid zk proof");

        uint256[] memory cashedVotes_ = new uint256[](candidates_.length);

        for (uint256 i = 0; i < candidates_.length; i++) {
            uint256 candidate_ = candidates_[i];

            require(
                votesForCandidates[candidate_] != type(uint256).max,
                "Voting: duplicate candidate"
            );
            require(
                _votingConfig.candidates.contains(candidate_),
                "Voting: candidate doesn't exist"
            );

            cashedVotes_[i] = votesForCandidates[candidate_] + candidates_.length - i - 1;
            votesForCandidates[candidate_] = type(uint256).max;
        }

        for (uint256 i = 0; i < candidates_.length; i++) {
            votesForCandidates[candidates_[i]] = cashedVotes_[i];
        }

        blindedNullifiers[nullifierHash_] = true;
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
