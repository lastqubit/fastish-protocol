// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

/// @title ILedger
/// @notice Minimal ledger interface for per-account, per-slot balances.
/// Exposes direct single-position reads and mutations, plus one block-native
/// batch posting entrypoint.
interface ILedger {
    /// @notice Return the current amount stored at one account position.
    /// @param account Account identifier.
    /// @param slot Ledger storage slot within the account namespace.
    /// @return amount Current amount stored at `(account, slot)`.
    function positionOf(bytes32 account, bytes32 slot) external view returns (uint amount);

    /// @notice Credit `amount` to one account position.
    /// @param account Account identifier.
    /// @param slot Ledger storage slot within the account namespace.
    /// @param amount Amount to add.
    function credit(bytes32 account, bytes32 slot, uint amount) external;

    /// @notice Debit `amount` from one account position.
    /// @param account Account identifier.
    /// @param slot Ledger storage slot within the account namespace.
    /// @param amount Amount to subtract.
    function debit(bytes32 account, bytes32 slot, uint amount) external;

    /// @notice Apply a batch of ledger postings encoded as request blocks.
    /// The exact accepted block shapes are implementation-defined.
    /// @param request Encoded posting request bytes.
    function post(bytes calldata request) external;
}
