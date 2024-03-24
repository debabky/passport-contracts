// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {Registration} from "../registration/Registration.sol";
import {Voting} from "./Voting.sol";

contract VotingFactory is Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;

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
        Voting voting_ = Voting(_deployVoting());

        voting_.__Voting_init(Registration(registration).getRoot(), votingVerifier, params_);
    }

    function _deployVoting() private returns (address) {
        return address(new ERC1967Proxy(votingImplementation, "0x"));
    }
}
