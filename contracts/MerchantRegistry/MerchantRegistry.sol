// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MerchantStorage.sol";


/**
* @title MerchantRegistry
* @notice Logic contract that manages merchant registrations. Inherits storage from MerchantStorage.
*/
contract MerchantRegistry is MerchantStorage {


modifier notPaused() {
require(!paused, "Paused");
_;
}


constructor() {
paused = false;
}


function setPaused(bool _paused) external onlyOwner {
paused = _paused;
if (_paused) emit Paused(msg.sender);
else emit Unpaused(msg.sender);
}


function registerMerchant(uint256 merchantId, address payoutAddress)
external
onlyOwner
{
require(merchantId != 0, "merchantId zero");
require(payoutAddress != address(0), "Zero payout");


if (merchantPayout[merchantId] == address(0)) {
// New merchant
if (merchantId > maxMerchantId) {
maxMerchantId = merchantId;
}
merchantPayout[merchantId] = payoutAddress;
emit MerchantRegistered(merchantId, payoutAddress);
} else {
// Updating payout address
emit MerchantPayoutUpdated(merchantId, merchantPayout[merchantId], payoutAddress);
merchantPayout[merchantId] = payoutAddress;
}
}
}