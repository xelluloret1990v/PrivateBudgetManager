// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    FHE,
    ebool,
    euint64,
    externalEuint64
} from "@fhevm/solidity/lib/FHE.sol";

import { ZamaEthereumConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract PrivateBudgetManager is ZamaEthereumConfig {
    /* -------- Ownable -------- */
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;

        // Initialize encrypted spending limit to 0
        euint64 zero = FHE.asEuint64(0);
        eSpendingLimit = zero;
        FHE.allowThis(zero);
        FHE.makePubliclyDecryptable(zero);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero owner");
        owner = newOwner;
    }

    /* -------- Reentrancy Guard -------- */
    uint256 private _locked = 1;
    modifier nonReentrant() {
        require(_locked == 1, "reentrancy");
        _locked = 2;
        _;
        _locked = 1;
    }

    /* -------- Encrypted Spending Limit -------- */
    euint64 private eSpendingLimit;

    event SpendingLimitUpdated(bytes32 limitHandle);
    event ExpensesChecked(address indexed user, bytes32 resultHandle);
    event ExpenseRecorded(address indexed user, bytes32 newTotalHandle);
    event ExpensesReset(address indexed user);

    function setSpendingLimit(
        externalEuint64 _spendingLimit,
        bytes calldata proof
    ) external onlyOwner {
        eSpendingLimit = FHE.fromExternal(_spendingLimit, proof);
        FHE.allowThis(eSpendingLimit);
        FHE.makePubliclyDecryptable(eSpendingLimit);

        emit SpendingLimitUpdated(FHE.toBytes32(eSpendingLimit));
    }

    /* -------- Encrypted Total User Spending -------- */
    mapping(address => euint64) private totalExpenses;

    function _getUserTotal(address user) internal returns (euint64) {
        // If user never recorded expenses → initialize encrypted 0
        if (!FHE.isInitialized(totalExpenses[user])) {
            euint64 zero = FHE.asEuint64(0);
            totalExpenses[user] = zero;
            FHE.allowThis(zero);
            FHE.makePubliclyDecryptable(zero);
        }
        return totalExpenses[user];
    }

    function recordExpense(
        externalEuint64 encAmount,
        bytes calldata proof
    ) external nonReentrant {
        euint64 eAmount = FHE.fromExternal(encAmount, proof);
        FHE.allowThis(eAmount);

        euint64 oldTotal = _getUserTotal(msg.sender);

        euint64 newTotal = FHE.add(oldTotal, eAmount);
        totalExpenses[msg.sender] = newTotal;

        FHE.allowThis(newTotal);
        FHE.makePubliclyDecryptable(newTotal);

        emit ExpenseRecorded(msg.sender, FHE.toBytes32(newTotal));
    }

    /* -------- Owner Reset Expenses -------- */
    function resetUserExpenses(address user) external onlyOwner nonReentrant {
        euint64 zero = FHE.asEuint64(0);
        totalExpenses[user] = zero;

        FHE.allowThis(zero);
        FHE.makePubliclyDecryptable(zero);

        emit ExpensesReset(user);
    }

    /* -------- Public Decryptable Getters -------- */

    function getTotalExpenses(address who) external returns (bytes32) {
        euint64 total = _getUserTotal(who);
        FHE.makePubliclyDecryptable(total);
        return FHE.toBytes32(total);
    }

    function getTotalExceedsLimit(address who) external returns (bytes32) {
        euint64 total = _getUserTotal(who);

        // Compare even when limit == 0
        ebool result = FHE.ge(total, eSpendingLimit);

        FHE.allowThis(result);
        FHE.makePubliclyDecryptable(result);

        bytes32 handle = FHE.toBytes32(result);
        emit ExpensesChecked(who, handle);
        return handle;
    }

    function getSpendingLimit() external returns (bytes32) {
        FHE.makePubliclyDecryptable(eSpendingLimit);
        return FHE.toBytes32(eSpendingLimit);
    }
}
