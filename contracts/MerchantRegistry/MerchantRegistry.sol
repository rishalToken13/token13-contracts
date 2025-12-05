// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./MerchantStorage.sol";

/**
 * @title MerchantRegistry
 * @notice Logic contract that manages merchant registrations.
 * @dev Uses upgradeable storage inherited from MerchantStorage.
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

        if (_paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }

    function registerMerchant(uint256 _merchantId, address _payoutAddress)
        external
        onlyOwner
    {
        require(_merchantId != 0, "merchantId zero");
        require(_payoutAddress != address(0), "Zero payout");

        address _existingPayout = merchantPayout_[_merchantId];

        if (_existingPayout == address(0)) {
            // New merchant
            if (_merchantId > maxMerchantId_) {
                maxMerchantId_ = _merchantId;
            }

            merchantPayout_[_merchantId] = _payoutAddress;
            emit MerchantRegistered(_merchantId, _payoutAddress);

        } else {
            // Updating payout address
            emit MerchantPayoutUpdated(_merchantId, _existingPayout, _payoutAddress);
            merchantPayout_[_merchantId] = _payoutAddress;
        }
    }
}
