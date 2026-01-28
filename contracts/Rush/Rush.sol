// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Executor, Ownable} from "./Executor.sol";
import {Node} from "../Lib/Node.sol";
import {Discovery} from "../Lib/Snippets/Discovery.sol";
import {ADMIN, SETUP} from "../Lib/Commands/Core/Base.sol";
import {addrOr, toAccountId, msgValue} from "../Lib/Utils.sol";

contract Rush is Executor, Discovery {
    constructor(address owner) Node(address(0), address(0), "admin") Ownable(addrOr(owner, msg.sender)) {}

    function getBalance(uint account, uint id) internal view override returns (uint) {
        return balances[account][id];
    }

    function validate(bytes[] calldata steps, bytes calldata signed) internal view returns (address) {
        if (signed.length == 0) {
            return msg.sender;
        }
        uint64 deadline;
        bytes memory data = abi.encode(steps, executeId, deadline);
        return validateRecover(data, signed);
    }

    function inject(bytes[] calldata steps) external payable override onlyOwner returns (uint) {
        return pipe(ADMIN, abi.encode(admin, ""), steps, msgValue());
    }

    function pipe(bytes[] calldata steps, bytes calldata signed) external payable override returns (uint) {
        uint account = toAccountId(validate(steps, signed));
        return pipe(SETUP, abi.encode(account, ""), steps, msgValue());
    }

    function resume(
        bytes4 head,
        bytes memory args,
        bytes[] calldata steps
    ) external payable override onlyAuthorized returns (uint) {
        return pipe(head, args, steps, msgValue());
    }
}
