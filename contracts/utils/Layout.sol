// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

library Layout {
    uint16 constant Ref32 = 0x2000;
    uint16 constant Evm32 = 0x2001;
    uint16 constant Evm64 = 0x4001;

    uint8 constant Account = 0x01;
    uint8 constant Node = 0x02;
    uint8 constant Asset = 0x03;

    uint8 constant Admin = 0x01;
    uint8 constant User = 0x02;
    uint8 constant Pointer = 0x03;

    uint8 constant Host = 0x01;
    uint8 constant Command = 0x02;
    uint8 constant Peer = 0x03;

    uint8 constant Value = 0x01;
    uint8 constant Erc20 = 0x02;
    uint8 constant Erc721 = 0x03;
}
