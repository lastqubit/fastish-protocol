// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Utilize, ABI} from "./Core/Utilize.sol";

string constant REQ = "dispatch(uint use)";

struct DispatchReq {
    uint use;
    bytes config;
}

abstract contract Dispatch is Utilize(REQ) {
    function toDispatchReq(
        bytes calldata step
    ) public view returns (DispatchReq memory) {
        return abi.decode(step, (DispatchReq));
    }
}
