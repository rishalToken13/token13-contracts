// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title MerchantStorage
* @notice Storage-only contract for merchant registry data.
*/
contract MerchantStorage is Ownable {
// -------------------------
// CONFIG
// -------------------------
uint256 public constant MAX_STRING_LENGTH = 128;


// -------------------------
// PAUSE
// -------------------------
bool public paused;


// -------------------------
// MERCHANTS
// -------------------------
// merchantId => payout address
mapping(uint256 => address) public merchantPayout;


// highest merchant id seen (bookkeeping only)
uint256 public maxMerchantId;


// -------------------------
// EVENTS 
// -------------------------
event MerchantRegistered(uint256 merchantId, address payout);
event MerchantPayoutUpdated(uint256 merchantId, address oldPayout, address newPayout);
event Paused(address by);
event Unpaused(address by);


// -------------------------
// STORAGE GAP for future variables
// -------------------------
uint256[50] private __gap;

constructor() Ownable(msg.sender) {}
}