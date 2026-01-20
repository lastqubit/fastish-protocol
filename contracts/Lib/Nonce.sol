// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

// Event for used nonce ???

abstract contract Nonces {
    mapping(uint account => mapping(uint192 key => uint64)) private nonces;

    error BadNonce(uint account);

    function toKey(uint keyNonce) public pure returns (uint192) {
        return uint192(keyNonce >> 64);
    }

    function toKeyNonce(uint192 key, uint64 nonce) public pure returns (uint) {
        return (uint(key) << 64) | nonce;
    }

    function getNonce(uint account, uint192 key) public view returns (uint) {
        return nonces[account][key];
    }

    function useNonce(uint account, uint192 key) internal returns (uint64) {
        return nonces[account][key]++;
    }

    function useNonce(uint account, uint192 key, uint64 nonce) internal {
        if (nonce != nonces[account][key]++) {
            revert BadNonce(account);
        }
    }
}

abstract contract DateNonces is Nonces {
    function useDeadlineNonce(uint from, uint192 timestamp) internal {
        // check deadline...
        useNonce(from, timestamp, 0);
    }
}
