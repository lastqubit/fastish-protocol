// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

abstract contract EventEmitter {
    event EventDefinition(
        bool once,
        address host,
        uint genesis,
        string category,
        string abi
    );
}
