// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import "hardhat/console.sol";

import {Executor, Value, Ownable} from "./Executor.sol";
import {Node} from "../Lib/Node.sol";
import {Id} from "../Lib/Utils/Id.sol";
import {Addr} from "../Lib/Utils/Addr.sol";
import {Bytes} from "../Lib/Utils/Bytes.sol";

contract Rush is Executor {
    mapping(uint => bool) internal initial; /////

    constructor(
        address owner,
        address discovery
    )
        Node(address(0), discovery, "admin")
        Ownable(Addr.or(owner, msg.sender))
    {}

    /*     function toId(address addr) public view returns (uint) {
        return Id.create(addr); /////
    } */

    function initValue() internal view returns (Value memory) {
        return Value(msg.value);
    }

    function settle(
        uint from,
        uint to,
        uint id,
        uint amount
    ) internal override returns (bool) {
        // return if out == in ??
        return debitFrom(from, id, amount) == creditTo(to, id, amount);
    }

    function inject(
        bytes32 head, // remove ??
        bytes memory body,
        bytes[] calldata steps
    ) external payable override onlyOwner returns (uint) {
        return pipe(Id.account(admin), head, body, steps, initValue());
    }

    function resume(
        bytes32 head, // ensure not zero ??
        bytes memory body,
        bytes calldata signed,
        bytes[] calldata steps
    ) external payable override onlyAuthorized returns (uint) {
        return pipe(validate(signed, steps), head, body, steps, initValue()); // If not signed, from becomes calling node!!
    }

    function execute(
        bytes calldata signed,
        bytes[] calldata steps
    ) external payable override returns (uint) {
        return pipe(validate(signed, steps), 0, "", steps, initValue());
    }

    function getBalances(
        uint account,
        uint[] calldata ids
    ) external view override returns (uint[] memory) {
        uint[] memory result = new uint[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            result[i] = balances[account][ids[i]];
        }
        return result;
    }

    function foo() external pure {
        address to = address(0);
        uint id = 50;
        uint amount = 2000;
        bytes4 x = 0xFF00FF00;
        bytes32 c = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        bytes32 a = 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00;
        bytes32 b = 0xF0000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF0000000000;

        //bytes memory data = hex"00FF";
        bytes memory step = bytes.concat(a, b);
        bytes32 out;

        assembly {
            mstore(add(add(step, 32), sub(mload(step), 32)), c)
        }

        assembly {
            out := mload(add(add(step, 32), sub(mload(step), 32)))
        }

        console.log("OUT: %s", uint(out));

        //console.log("BOOL: %s", uint8(true));

        /*         bytes8 size = 0x0000000000000020;
        bytes4 selector = this.bar.selector;
        console.log("Selector: %s", uint32(selector));
        bytes memory data = abi.encode(size | selector);
        console.log("Selector: %s", uint32(bytes4(data)));
        console.log("Size: %s", uint32(uint64(bytes8(data)))); */
        /*         bytes memory data = abi.encode(
            0,
            abi.encode(address(0), 50, 99999, "", ""),
            ""
        );
        (, bytes memory x, ) = abi.decode(data, (bytes4, bytes, bytes));
        (uint to, uint id, uint amount, , ) = abi.decode(
            x,
            (address, uint, uint, bytes, bytes)
        );
        console.log("Decode %s %s %s", id, amount, to); */
    }

    /*     function xx(uint head) internal {
        if (head == 0) toId(address(0));
    } */

    function bar(address svc) external pure {
        bytes memory x = bytes.concat(
            bytes32(uint(11)),
            bytes32(uint(22)),
            bytes32(uint(33))
        );
        uint ch = uint(bytes32(x));
        uint num;
        uint128 s = 0x04000006030000070200000901000005;
        bytes memory gg = hex"04000006030000070200000908000005";

        //(uint64(uint32(len))) |= uint64(99) << 32;
        //console.log("REQ BLOCK %", Context.STEP | uint24(800));
        console.log(
            "COOL %",
            uint(1) | (uint(1) << 16) | (uint(1) << 32) | (uint(1) << 64)
        );
        console.log("BYTES LIB %", uint8(Bytes.to1no(gg, 1)));
        console.log("TEST %", (3 | 1) ^ 3);
        //console.log("OFFSET %", Context.find(3, uint(s) << 64));
        console.log("HELLO CTX HEADER %", ch);
        console.log("HELLO LEN %", x.length);
        console.log("HELLO WORLD %", uint(bytes32(x)));
        assembly {
            let a := add(x, 32)
            let b := add(x, 96)
            num := mload(a)
            mstore(a, mload(b))
            mstore(b, num)
        }

        /*             E.num
            let h := num << 36 */
        console.log("NUM %s", num);

        (uint a, uint b, uint c) = abi.decode(x, (uint, uint, uint));
        console.log("HELLO WORLD %s %s %s", a, b, c);
    }
}
