// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

// @dev returns zero on out of bounds instead of revert.

bytes32 constant mask4 = 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000;

function compare4(
    bytes memory data,
    uint offset,
    bytes4 target
) pure returns (bool equal) {
    assembly {
        let word := mload(add(add(data, 32), offset))
        equal := eq(and(word, mask4), target)
    }
}

library Bytes {
    error OutOfBounds();

    function oob(
        uint size,
        uint o,
        bytes memory d
    ) private pure returns (bool) {
        return o + size > d.length;
    }

    function noob(
        uint size,
        uint no,
        bytes memory d
    ) private pure returns (bool) {
        return no < size || no > d.length;
    }

    function checkNo(uint size, uint no, bytes memory d) private pure {
        if (no < size || no > d.length) {
            revert OutOfBounds();
        }
    }

    function to1(bytes memory d, uint o) internal pure returns (bytes1 out) {
        if (oob(1, o, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), o))
        }
    }

    function to2(bytes memory d, uint o) internal pure returns (bytes2 out) {
        if (oob(2, o, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), o))
        }
    }

    function to4(bytes memory d, uint o) internal pure returns (bytes4 out) {
        if (oob(4, o, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), o))
        }
    }

    function to8(bytes memory d, uint o) internal pure returns (bytes8 out) {
        if (oob(8, o, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), o))
        }
    }

    function to20(bytes memory d, uint o) internal pure returns (bytes20 out) {
        if (oob(20, o, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), o))
        }
    }

    function to32(bytes memory d, uint o) internal pure returns (bytes32 out) {
        if (oob(32, o, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), o))
        }
    }

    function to1no(bytes memory d, uint no) internal pure returns (bytes1 out) {
        if (noob(1, no, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), sub(mload(d), no)))
        }
    }

    function to2no(bytes memory d, uint no) internal pure returns (bytes2 out) {
        if (noob(2, no, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), sub(mload(d), no)))
        }
    }

    function to4no(bytes memory d, uint no) internal pure returns (bytes4 out) {
        if (noob(4, no, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), sub(mload(d), no)))
        }
    }

    function to8no(bytes memory d, uint no) internal pure returns (bytes8 out) {
        if (noob(8, no, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), sub(mload(d), no)))
        }
    }

    function to20no(
        bytes memory d,
        uint no
    ) internal pure returns (bytes20 out) {
        if (noob(20, no, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), sub(mload(d), no)))
        }
    }

    function to32no(
        bytes memory d,
        uint no
    ) internal pure returns (bytes32 out) {
        if (noob(32, no, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), sub(mload(d), no)))
        }
    }

    function store32no(bytes memory d, uint no, uint value) internal pure {
        if (noob(32, no, d)) {
            revert OutOfBounds();
        }
        assembly {
            mstore(add(add(d, 32), sub(mload(d), no)), value)
        }
    }

    function last2(bytes memory d) internal pure returns (bytes2 out) {
        if (noob(2, 2, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), sub(mload(d), 2)))
        }
    }

    function last4(bytes memory d) internal pure returns (bytes4 out) {
        if (noob(4, 4, d)) return 0;
        assembly {
            out := mload(add(add(d, 32), sub(mload(d), 4)))
        }
    }
}

/*     function to1no(bytes memory d, uint no) internal pure returns (bytes1 out) {
        if (noob(1, no, d)) return 0;
        uint o = d.length - no + 32;
        uint mask = type(uint8).max;
        assembly {
            out := mload(add(d, o))
            //out := and(shr(248, mload(add(d, o))), mask)
        }
    } */

/*    function find(uint8 cat, uint head) internal pure returns (uint o) {
        assembly {
            for {
                let g := 0
                let i := 64
                let c := shl(24, cat)
            } lt(i, 193) {
                i := add(i, 32)
            } {
                g := and(shr(i, head), 0xff000000)


                if iszero(g) {
                    o := 0
                    break
                }
                if eq(g, c) {
                    o := and(shr(i, head), 0x00ffffff)
                    break
                }
            }
        }
    } */
