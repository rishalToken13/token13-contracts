// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { Context } from "../GovernanaceController/Context/Context.sol";
import { IMerchantRegistry } from "../MerchantRegistry/IMerchantRegistry.sol";
import { MathUtils } from "../Utils/MathUtils.sol";
import { TokenUtils } from "../Utils/TokenUtils.sol";
import { PaymentV1Storage } from "./Storage.sol";

/**
 * @author  Platform, GmbH.
 * @title   Platform operator Contract.
 * @dev     This Contracts holds operator configuration functionality.
 */

contract PaymentCoreV1 is Context, PaymentV1Storage {


event PaymentDetected(
    bytes32 indexed merchantId,
    uint256 indexed orderId,
    uint256 indexed invoiceId,
    address paymentToken,
    uint256 amount,
    uint256 timestamp
);

 event CommissionConfigUpdated(
    address indexed receiver,
    uint256 percentage
  );


event CommissionWithdrawn(
    address indexed receiver,
    address indexed token,
    uint256 amount 
);

    // initialised for upgradation usage
    uint256[50] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
        constructor() {
            _disableInitializers();
    } 

  
    function initialize(
        address _rootAdmin,
        IMerchantRegistry _merchantRegistry,
        address _platformCommissionReceiver,
        uint256 _platformCommissionPercentage
        ) external initializer {
            __Governance_init_unchained(_rootAdmin);
            __paymentCore_init(
                _merchantRegistry,
                _platformCommissionReceiver,
                _platformCommissionPercentage
            );
        }

    function __paymentCore_init(
        IMerchantRegistry _merchantRegistry,
        address _platformCommissionReceiver,
        uint256 _platformCommissionPercentage
        ) internal onlyInitializing {
            merchantRegistry_ = _merchantRegistry;
            _setCommissionPercentage(_platformCommissionPercentage);
            _setCommissionReceiver(_platformCommissionReceiver);
    }


  function setCommissionPercentage (uint256 _percentage) external onlyManager {
      _checkAndRevertMessage(MathUtils.validPercentage(_percentage, 0, percentageMultiplier_),"Invalid Percentage Input");
      _checkAndRevertMessage(_percentage != platformCommissionConfig_.percentage,"Same Percentage exists");

      _setCommissionPercentage(_percentage);

      emit CommissionConfigUpdated(platformCommissionConfig_.receiver, _percentage);
  }

  function setCommissionReceiver (address _receiver) external onlyManager {
      _checkAndRevertMessage(_receiver != address(0),"Receiver Cant be zero");
      _checkAndRevertMessage(_receiver != platformCommissionConfig_.receiver,"Same Receiver exists");

      _setCommissionReceiver(_receiver);

      emit CommissionConfigUpdated(_receiver, platformCommissionConfig_.percentage);
  }

  function _setCommissionPercentage (uint256 _percentage) internal {
      platformCommissionConfig_.percentage = _percentage;
  }

  function _setCommissionReceiver (address _receiver) internal {
      platformCommissionConfig_.receiver = _receiver;
  }


function withdrawFromCommissions(address _token)
    external
    nonReentrant
    onlyManager
{
    CommissionBalance storage cb = commissionBalances_[_token];
    uint256 amount = cb.balance;
    address commissionReceiver_ = platformCommissionConfig_.receiver;

    _checkAndRevertMessage(amount > 0, "No balance to withdraw");
    _checkAndRevertMessage(
        commissionReceiver_ != address(0),
        "Platform receiver not set"
    );

    // Effects: update state before external calls
    cb.balance = 0;
    cb.claimed += amount;

    // Interactions (native TRX or TRC20 decided inside TokenUtils)
    TokenUtils.pushTokens(_token, commissionReceiver_, amount);

    emit CommissionWithdrawn(
        commissionReceiver_,
        _token,
        amount
    );
}


function payTx(
    bytes32 _merchantId,
    uint256 _orderId,
    uint256 _invoiceId,
    address _paymentToken,  // address(0) = TRX, otherwise TRC20
    uint256 _amount
) external payable nonReentrant {
    _checkAndRevertMessage(_amount > 0, "Invalid amount");
    _checkAndRevertMessage(_isMerchantActive(_merchantId), "Inactive merchant");
    _checkAndRevertMessage(
        _isTokenSupported(_merchantId, _paymentToken),
        "Unsupported payment token"
    );

    bool isTRX = (_paymentToken == address(0));

    if (isTRX) {
        // Native TRX payment
        _checkAndRevertMessage(msg.value == _amount, "Invalid TRX amount");

        (uint256 commission, uint256 merchantShare) =
            _settlementCalculation(_amount);

        // Track platform commission in TRX bucket
        commissionBalances_[_paymentToken].balance += commission;

        // Record settlement for this invoice
        _setInvoiceDetails(
            _merchantId,
            _orderId,
            _invoiceId,
            _paymentToken,
            _amount
        );

        // Accounting for merchant funds (TRX)
        fundReceived_[_merchantId][_paymentToken] += merchantShare;

        // Payout merchant share
        address receiver = _fetchMerchantFundReceiver(_merchantId);
        TokenUtils.pushTokens(_paymentToken, receiver, merchantShare);
    } else {
        // TRC20 token payment
        _checkAndRevertMessage(
            msg.value == 0,
            "Do not send TRX with token payment"
        );

        (uint256 commission, uint256 merchantShare) =
            _settlementCalculation(_amount);

        // Track platform commission in this token
        commissionBalances_[_paymentToken].balance += commission;

        // Record settlement for this invoice
        _setInvoiceDetails(
            _merchantId,
            _orderId,
            _invoiceId,
            _paymentToken,
            _amount
        );

        // Accounting for merchant funds (token)
        fundReceived_[_merchantId][_paymentToken] += merchantShare;

        // Pull full amount from payer into this contract
        TokenUtils.pullTokens(_paymentToken, _msgSender(), _amount);

        // Send merchant share to merchant
        address fundReceiver = _fetchMerchantFundReceiver(_merchantId);
        TokenUtils.pushTokens(_paymentToken, fundReceiver, merchantShare);
        // Commission stays in contract; withdrawable via withdrawFromCommissions()
    }

        emit PaymentDetected(
            _merchantId,
            _orderId,
            _invoiceId,
            _paymentToken,
            _amount,
            block.timestamp
        );
    }


    function getPlatformCommissionConfig()
        external
        view
        returns (address receiver, uint256 percentage)
    {
        CommissionConfig memory config = platformCommissionConfig_;
        return (config.receiver, config.percentage);
    }

    function getCommissionBalance(address _token)
        external
        view
        returns (uint256 balance, uint256 claimed)
    {
        CommissionBalance memory cb = commissionBalances_[_token];
        return (cb.balance, cb.claimed);
    }

    function getSettlementDetails(bytes32 _merchantId, uint256 _invoiceId)
        external
        view
        returns (
            address paymentToken,
            uint256 orderId,
            uint256 amount,
            uint256 timestamp,
            bool active
        )
    {
        SettlementDetails memory sd = settlements_[_merchantId][_invoiceId];
        return (
            sd.paymentToken,
            sd.orderId,
            sd.amount,
            sd.timestamp,
            sd.active
        );
    }

    function getMerchantFundsReceived(bytes32 _merchantId, address _token)
        external
        view
        returns (uint256)
    {
        return fundReceived_[_merchantId][_token];
    }


    function _setInvoiceDetails(
        bytes32 _merchantId,
        uint256 _orderId,
        uint256 _invoiceId,
        address _paymentToken,
        uint256 _amount
    ) private {
        settlements_[_merchantId][_invoiceId] = SettlementDetails({
            paymentToken: _paymentToken,
            orderId: _orderId,
            amount: _amount,
            timestamp: block.timestamp,
            active: true
        });
    }


   function _settlementCalculation(uint256 _amount) private view returns (uint256 commission, uint256 merchantShare) {
        commission = _getShareAmount(_amount, platformCommissionConfig_.percentage, percentageMultiplier_);
        merchantShare = _amount - commission;
    }

    function _getShareAmount(uint256 _amount,uint256 _share, uint256 _percentage) private pure returns (uint256) {
        return MathUtils.percentageOf(_amount, _share, _percentage);
    }

    function _isTokenSupported(
            bytes32 merchantId_,
            address token_
        ) private view returns(bool) {
        return merchantRegistry_.isMerchantTokenSupported(merchantId_, token_);
    }

    function _isMerchantActive(
        bytes32 merchantId_
    ) private view returns(bool) {
        return merchantRegistry_.isMerchantActive(merchantId_);
    }

    function _fetchMerchantFundReceiver(
        bytes32 merchantId_
    ) private view returns(address) {
        return merchantRegistry_.getMerchantFundReceiver(merchantId_);
    }
}