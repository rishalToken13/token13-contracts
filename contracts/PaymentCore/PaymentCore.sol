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
    bytes32 merchantId_,
    uint256 orderId_,
    uint256 invoiceId_,
    IERC20Upgradeable paymentToken_,
    uint256 amount_
  ) external nonReentrant payable { 
    
    _checkAndRevertMessage(_isTokenSupported(merchantId_, paymentToken_),"Unsupported Payment Token");


    merchantRegistry_.validateMerchantToken(merchantId_, paymentToken_);

    // Transfer payment from payer to this contract
    TokenUtils.pullTokens(paymentToken_, _msgSender(), amount_);

    // Calculate platform commission
    uint256 commissionAmount = MathUtils.calculatePercentage(
        amount_,
        platformCommissionConfig_.percentage,
        percentageMultiplier_
    );

    // Update commission balance
    commissionBalances_[paymentToken_].balance += commissionAmount;

    // Calculate net amount to be sent to merchant
    uint256 netAmount = amount_ - commissionAmount;

    // Transfer net amount to merchant's fund receiver
    address fundReceiver = merchantRegistry_.getMerchantFundReceiver(merchantId_);
    TokenUtils.pushTokens(paymentToken_, fundReceiver, netAmount);

    // Record the settlement details
    settlements_[merchantId_][orderId_] = SettlementDetails({
        paymentToken: paymentToken_,
        orderId: orderId_,
        amount: amount_,
        timestamp: block.timestamp,
        active: true
    });

    emit PaymentCompleted(
        merchantId_,
        orderId_,
        invoiceId_,
        paymentToken_,
        amount_,
        block.timestamp
    );
  }



  /**
   * @dev Function to get minimum fees that all operators can hold which is set by admin.
   */
  function getMinFee() external view returns(uint256) {
    return operatorFees_.minFee;
  }

  /**
   * @dev Function to get maximum reward that all operators can hold which is set by admin.
   */
  function getMaxReward() external view returns(uint256) {
    return operatorFees_.maxReward;
  }

  /**
   * @dev Function to get minimum fee that specific operator willing to get.
   */
  function getOperatorFeeCut(address _operator) external view returns(uint256) {
    return (operatorFees_.minFee > operators_[_operator].feeCut) ? 
            operatorFees_.minFee : operators_[_operator].feeCut;
  }

  /**
   * @dev Function to get maximum reward that specific operator willing to get.
   */
  function getOperatorRewardCut(address _operator) external view returns(uint256) {
    return (operatorFees_.maxReward < operators_[_operator].rewardCut) ? 
            operatorFees_.maxReward : operators_[_operator].rewardCut;
  }

  /**
   * @dev Function to get filehash of specific operator.
   */
  function getOperatorConfig(address _operator) external view returns(string memory){
    return operators_[_operator].fileHash;
  }

  /**
   * @dev Function is to check the operator is active or not.
   */
  function isOperatorActive(address _operator) external view returns (bool) {
    return operators_[_operator].active;
  }

  /**
   * @dev Function is to check the operator is claiming or not.
   */
  function isOperatorClaimingRewards(address _operator) external view returns (bool) {
    return claimRewards_[_operator];
  }

  /**
   * @dev Function is to get the epoch manager instance.
   */
  function getEpochManager() external view returns(IEpochManager) {
    return epochManager_;
  }



  function _isTokenSupported(
    bytes32 merchantId_,
    IERC20Upgradeable token_
  ) internal view returns(bool) {
    return merchantRegistry_.isMerchantTokenSupported(merchantId_, token_);
  }


  /**
  * @dev Internal Function to set epoch Manager to Platform Contract.
  * @param _epochManager pass address of the epoch Manager to get epoch manager contract instance.
  */
  function _setEpoch(IEpochManager _epochManager) internal {
    epochManager_ = _epochManager;
  }

  /**
  * @dev Internal Function to set bcut address to Operator Contract.
  * @param _bcutToken pass address of the Bcut Token to get Bcut Token contract instance.
  */
  function _setBcut(IERC20Upgradeable _bcutToken) internal {
    bcutToken_ = _bcutToken;
  }

  /**
  * @dev Internal Function to set minimum fees for all operators by admin.
  * @param _fee is the minimum fee that must can operator hold.
  */
  function _setMinFee (uint256 _fee) internal {
    operatorFees_.minFee = _fee;
  }

  /**
  * @dev Internal Function to set maximum reward for all operators by admin.
  * @param _reward is the maximum reward that must can operator hold.
  */
  function _setMaxReward (uint256 _reward) internal {
    operatorFees_.maxReward = _reward;
  }


function _isEmptyString(string memory str) internal pure returns (bool) {
    bytes memory strBytes = bytes(str);
    return strBytes.length == 0;
}
}