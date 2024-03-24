// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {RSAPSSVerifier} from "../../utils/RSAPSSVerifier.sol";

contract RSAPSSVerifierMock {
    using RSAPSSVerifier for *;

    function mgf(bytes memory message_, uint256 maskLen_) external pure returns (bytes memory) {
        return message_.mgf(maskLen_);
    }

    function verify(
        bytes memory message_,
        bytes memory s_,
        bytes memory e_,
        bytes memory n_
    ) external view returns (bool) {
        return message_.verify(s_, e_, n_);
    }

    function verifyPassport(
        bytes memory message_,
        bytes memory s_,
        bytes memory e_,
        bytes memory n_
    ) external view returns (bool) {
        return message_.verifyPassport(s_, e_, n_);
    }
}
