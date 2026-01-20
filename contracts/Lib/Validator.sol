// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import "hardhat/console.sol";

import {Crypto} from "./Crypto.sol";
import {DateNonces} from "./Nonce.sol";
import {Data} from "./Utils/Data.sol";

abstract contract Validator is Crypto, DateNonces {
    using Data for bytes;

    uint private constant MINSIZE = 193;

    uint public immutable validator; // patched node id

    error BadDeadline(uint timestamp);
    error BadRunner();

    // change InvalidSignature to InvalidBytes

    function signer(bytes calldata data) private pure returns (address) {
        return address(bytes20(data[44:64]));
    }

    function check(
        uint from,
        uint head,
        uint meta
    ) private view returns (uint96) {
        /*         if (validator != head) {
            revert();
        } */
        // executor -> runner ???
        return uint96(meta >> 160);
    }

    function checkDeadline(uint ts) internal view returns (uint) {
        if (ts < block.timestamp) {
            revert BadDeadline(ts);
        }
        return ts;
    }

    /*     function validate(
        uint from,
        address exec,
        uint deadline,
        bytes32 hash,
        bytes memory sig
    ) internal {
        checkDeadline(deadline);
        Msg.executor(exec, from);
        if (hash == 0) return;
        verify(hash, from, sig);
        useNonce(from, uint192(deadline), 0);
    } */

    function verify(
        uint from,
        uint96 nonce,
        bytes32 hash,
        bytes calldata sig
    ) private {
        //verify(hash, from, sig); ///////
        useNonce(from, nonce, 0);
    }

    function unsigned(bytes calldata data) private view returns (bool) {
        if (data.signed()) return false;
        if (data.length > 0 && data.from() != msg.sender) {
            revert BadRunner();
        }
        return true;
    }

// signed data is now data:head:meta:sig

// remove signed runner ?? doesn't work cross chain.. 
    function validate(
        uint from,
        bytes calldata data
    ) internal returns (bytes calldata) {
        if (unsigned(data)) return data; /////////////
        uint96 nonce = check(from, data.head(), data.meta());
        uint end = data.length - 65;
        //
        //verify(toHash(data[:end]), from, data[end:]);
        useDeadlineNonce(from, nonce);
        return data[:end]; // return all?? no need to return anything??
    }

    // isValid returns bool... must be signed and valid
    // or function returns data if isValid otherwise ""
}
