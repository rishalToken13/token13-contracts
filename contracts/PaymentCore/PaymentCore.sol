// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { Context } from "../GovernanceController/Context/Context.sol";
import { MathUtils } from "../Utils/MathUtils.sol";
import { PaymentV1Storage } from "./Storage.sol";

/**
 * @author  Platform, GmbH.
 * @title   Platform operator Contract.
 * @dev     This Contracts holds operator configuration functionality.
 */

contract PaymentCoreV1 is Context, PaymentV1Storage {


event PaymentCompleted(
    bytes32 indexed merchantId,
    uint256 indexed orderId,
    uint256 indexed invoiceId,
    IERC20Upgradeable paymentToken,
    uint256 amount,
    uint256 timestamp
);

 event CommissionConfigUpdated(
    address indexed receiver,
    uint256 percentage
  );


event CommissionWithdrawn(
    address indexed receiver,
    IERC20Upgradeable indexed token,
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

function withdrawFromCommissions(
    IERC20Upgradeable _token
    ) external nonReentrant onlyManager {
    
    uint256 _amount = commissionBalances_[_token].balance;
    address commissionReceiver_ = platformCommissionConfig_.receiver;
    
    _checkAndRevertMessage(_amount > 0, "No Balance to Withdraw");
    _checkAndRevertMessage(commissionReceiver_ != address(0), "Platform Receiver not set");

    commissionBalances_[_token].balance = 0;
    commissionBalances_[_token].claimed += _amount;
    

    TokenUtils.pushTokens(_token,commissionReceiver_,_amount);

    emit CommissionWithdrawn(
        commissionReceiver_,
        address(_token),
        _amount
    );
}


function payTx(
    bytes32 _merchantId,
    uint256 _orderId,
    uint256 _invoiceId,
    IERC20Upgradeable _paymentToken,
    uint256 _amount
  ) external nonReentrant payable { 
        
    _checkAndRevertMessage(_amount > 0,"Invalid Amount");
    _checkAndRevertMessage(_isMerchantActive(_merchantId),"Inactive Merchant");
    _checkAndRevertMessage(_isTokenSupported(_merchantId, _paymentToken),"Unsupported Payment Token");

    bool isTRX = _paymentToken == address(0);

    if (isTRX) {
        _checkAndRevertMessage(msg.value == _amount,"Invalid TRX amount");
        (uint256 commission, uint256 merchantShare) = _settlementCalculation(_amount);
        commissionBalances_[_paymentToken].balance += commission;
        _setInvoiceDetails(_merchantId, _orderId, _invoiceId, _paymentToken, _amount);
        fundReceived_[_merchantId][_paymentToken] += merchantShare;
        address receiver = _fetchMerchantFundReceiver(_merchantId); 
        (bool success, ) = payable(receiver).call{value: merchantShare}("");
        _checkAndRevertMessage(success,"TRX Transfer failed");

    } else {
        _checkAndRevertMessage(msg.value == 0,"Do not send TRX with token payment");
        (uint256 commission, uint256 merchantShare) = _settlementCalculation(_amount);
        commissionBalances_[_paymentToken].balance += commission;
        _setInvoiceDetails(_merchantId, _orderId, _invoiceId, _paymentToken, _amount);
        fundReceived_[_merchantId][_paymentToken] += merchantShare; 
        address fundReceiver = _fetchMerchantFundReceiver(_merchantId); 
        TokenUtils.pullTokens(_paymentToken, _msgSender(), _amount);
        TokenUtils.pushTokens(_paymentToken, fundReceiver, merchantShare);
    }

    emit PaymentCompleted(
        merchantId_,
        orderId_,
        invoiceId_,
        paymentToken_,
        amount_,
        block.timestamp
    );
  }

  function _setInvoiceDetails(bytes32 _merchantId, uint256 _orderId, uint256 _invoiceId, IERC20Upgradeable _paymentToken, uint256 _amount) private view returns (uint256 commission, uint256 merchantShare) {
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
        IERC20Upgradeable token_
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