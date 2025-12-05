// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./MerchantStorage.sol";


/**
* @title MerchantRegistry
* @notice Logic contract that manages merchant registrations. Inherits storage from MerchantStorage (Upgradeable).
*/
contract MerchantRegistry is Initializable, MerchantStorage {


    modifier notPaused() {
        require(!paused_, "Paused");
        _;
    }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) public override initializer {
        MerchantStorage.initialize(_owner);
    }


    function setPaused(bool _paused) external onlyOwner {
        paused_ = _paused;
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