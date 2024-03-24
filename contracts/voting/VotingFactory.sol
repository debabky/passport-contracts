// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {Paginator} from "@solarity/solidity-lib/libs/arrays/Paginator.sol";

import {Registration} from "../registration/Registration.sol";
import {Voting} from "./Voting.sol";

contract VotingFactory is Initializable {
    using Paginator for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant CANDIDATES_NUM = 5;

    address public registration;

    address public votingImplementation;
    address public votingVerifier;

    EnumerableSet.AddressSet internal _votings;

    function __VotingFactory_init(
        address registration_,
        address votingImplementation_,
        address votingVerifier_
    ) external initializer {
        registration = registration_;

        votingImplementation = votingImplementation_;
        votingVerifier = votingVerifier_;
    }

    function createVoting(Voting.VotingParams calldata params_) external {
        require(params_.candidates.length == CANDIDATES_NUM, "Voting: overcandidated");

        Voting voting_ = Voting(_deployVoting());

        voting_.__Voting_init(Registration(registration).getRoot(), votingVerifier, params_);

        _votings.add(address(voting_));
    }

    function getVotings(uint256 offset_, uint256 limit_) external view returns (address[] memory) {
        return _votings.part(offset_, limit_);
    }

    function _deployVoting() private returns (address) {
        return address(new ERC1967Proxy(votingImplementation, ""));
    }
}
