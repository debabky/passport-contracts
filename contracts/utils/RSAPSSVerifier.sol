// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {SHA1} from "./SHA1.sol";

library RSAPSSVerifier {
    using SHA1 for bytes;

    error MaskTooLengthy();

    uint256 constant HASH_LEN = 20;
    uint256 constant SALT_LEN = 20;
    uint256 constant MS_BITS = 2047 & 0x7;
    uint256 constant MS_BYTES = 256;

    function mgf(
        bytes memory message_,
        uint256 maskLen_
    ) internal pure returns (bytes memory res_) {
        bytes memory cnt_ = new bytes(4);

        if (maskLen_ > (2 ** 32) * HASH_LEN) {
            revert MaskTooLengthy();
        }

        for (uint256 i = 0; i < (maskLen_ + HASH_LEN - 1) / HASH_LEN; ++i) {
            cnt_[0] = bytes1(uint8((i >> 24) & 255));
            cnt_[1] = bytes1(uint8((i >> 16) & 255));
            cnt_[2] = bytes1(uint8((i >> 8) & 255));
            cnt_[3] = bytes1(uint8(i & 255));

            bytes20 hashedResInter_ = abi.encodePacked(message_, cnt_).sha1();

            res_ = abi.encodePacked(res_, hashedResInter_);
        }

        assembly {
            mstore(res_, maskLen_)
        }
    }

    function pss(bytes memory message_, bytes memory signature_) internal pure returns (bool) {
        if (message_.length > 2 ** 61 - 1) {
            return false;
        }

        bytes20 messageHash_ = message_.sha1();

        if (MS_BYTES < HASH_LEN + SALT_LEN + 2) {
            return false;
        }

        if (signature_[MS_BYTES - 1] != hex"BC") {
            return false;
        }

        bytes memory db_ = new bytes(MS_BYTES - HASH_LEN - 1);
        bytes memory h_ = new bytes(HASH_LEN);

        for (uint256 i = 0; i < db_.length; ++i) {
            db_[i] = signature_[i];
        }

        for (uint256 i = 0; i < HASH_LEN; ++i) {
            h_[i] = signature_[i + db_.length];
        }

        if (uint8(db_[0] & bytes1(uint8(((0xFF << (MS_BITS)))))) == 1) {
            return false;
        }

        bytes memory dbMask_ = mgf(h_, db_.length);

        for (uint256 i = 0; i < db_.length; ++i) {
            db_[i] ^= dbMask_[i];
        }

        if (MS_BITS > 0) {
            db_[0] &= bytes1(uint8(0xFF >> (8 - MS_BITS)));
        }

        uint256 zeroBytes_;

        for (
            zeroBytes_ = 0;
            db_[zeroBytes_] == 0 && zeroBytes_ < (db_.length - 1);
            ++zeroBytes_
        ) {}

        if (db_[zeroBytes_++] != hex"01") {
            return false;
        }

        bytes memory salt_ = new bytes(SALT_LEN);

        for (uint256 i = 0; i < salt_.length; ++i) {
            salt_[i] = db_[db_.length - salt_.length + i];
        }

        bytes20 hh_ = abi.encodePacked(hex"0000000000000000", messageHash_, salt_).sha1();

        if (bytes20(h_) != hh_) {
            return false;
        }

        return true;
    }

    function decrypt(
        bytes memory s_,
        bytes memory e_,
        bytes memory n_
    ) internal view returns (bytes memory decipher_) {
        bytes memory input_ = abi.encodePacked(
            bytes32(s_.length),
            bytes32(e_.length),
            bytes32(n_.length),
            s_,
            e_,
            n_
        );
        uint256 inputLength_ = input_.length;

        uint256 decipherLength_ = n_.length;
        decipher_ = new bytes(decipherLength_);

        assembly {
            pop(
                staticcall(
                    sub(gas(), 2000),
                    5,
                    add(input_, 0x20),
                    inputLength_,
                    add(decipher_, 0x20),
                    decipherLength_
                )
            )
        }
    }

    function verify(
        bytes memory message_,
        bytes memory s_,
        bytes memory e_,
        bytes memory n_
    ) internal view returns (bool) {
        if (s_.length == 0 || e_.length == 0 || n_.length == 0) {
            return false;
        }

        bytes memory decipher_ = decrypt(s_, e_, n_);

        return pss(message_, decipher_);
    }

    function verifyPassport(
        bytes memory challenge_,
        bytes memory s_,
        bytes memory e_,
        bytes memory n_
    ) internal view returns (bool) {
        if (s_.length == 0 || e_.length == 0 || n_.length == 0) {
            return false;
        }

        bytes memory decipher_ = decrypt(s_, e_, n_);

        assembly {
            mstore(decipher_, sub(mload(decipher_), 1))
        }

        bytes memory prepared_ = new bytes(decipher_.length - HASH_LEN - 1);
        bytes memory digest_ = new bytes(HASH_LEN);

        for (uint256 i = 0; i < prepared_.length; ++i) {
            prepared_[i] = decipher_[i + 1];
        }

        for (uint256 i = 0; i < digest_.length; ++i) {
            digest_[i] = decipher_[decipher_.length - HASH_LEN + i];
        }

        return bytes20(digest_) == abi.encodePacked(prepared_, challenge_).sha1();
    }
}
