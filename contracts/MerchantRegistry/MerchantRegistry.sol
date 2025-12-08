// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { Context } from "../GovernanceController/Context/Context.sol";
import { MathUtils } from "../Utils/MathUtils.sol";
import { MerchantV1Storage } from "./Storage.sol";

/**
 * @author  Platform, GmbH.
 * @title   Platform operator Contract.
 * @dev     This Contracts holds operator configuration functionality.
 */

contract MerchantRegistry is Context, MerchantV1Storage {


  /**
   * @dev Event emitted new operator is onboarded.
   * @param operator is the address of the operator.
   * @param feeCut is the minimum fee that can operator hold.
   * @param rewardCut is the maximum earned reward that can operator hold.
   * @param fileHash is the IPFS hash representing the config metadata.
   */

   //Merchant Onboarded Event
  event OperatorOnboarded(
    address indexed operator,
    uint256 feeCut,
    uint256 rewardCut,
    string fileHash
  );


   //Merchant Token Updated Event
   //id, token, status
  event OperatorOnboarded(
    address indexed operator,
    uint256 feeCut,
    uint256 rewardCut,
    string fileHash
  );


   //Merchant status Updated Event
   //id, status
  event OperatorOnboarded(
    address indexed operator,
    uint256 feeCut,
    uint256 rewardCut,
    string fileHash
  );


   //Merchant receiver address Updated Event
   //id, receiver address
  event OperatorOnboarded(
    address indexed operator,
    uint256 feeCut,
    uint256 rewardCut,
    string fileHash
  );


  // initialised for upgradation usage
  uint256[50] private __gap;

  /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
  } 

  /**
  * @dev Initializes the Operator contract.
  * @param _rootAdmin is the address of Admin to have Admin privilege.
  */
  function initialize(
    address _rootAdmin,
    ) external initializer {
      __Governance_init_unchained(_rootAdmin);
    }


    //merchant onboard function
    //merchant status update 
    //updateMerchanttokenStatus (id, token, status)
    //updateMerchantReceiverAddress (id, token, status)


  /**
   * @dev Function to set maximum reward of all operators in chain.
   * @notice This function will be called by the admin.
   * @param _reward is the maximum reward that can operator hold.
   */
  function setMaximumReward (uint256 _reward) external onlyOwner {
      _checkAndRevert(MathUtils.validPercentage(_reward, 0, percentage_),"Invalid Percentage Input");
      _checkAndRevert(_reward != operatorFees_.maxReward,"Same Reward exists");

      _setMaxReward(_reward);

      emit FeeUpdated(epochManager_.currentEpoch(), operatorFees_.minFee, _reward);
  }


  /**
   * @dev Function to set min fee of all operators in chain.
   * @notice This function will be called by the admin.
   * @param _fee is the maximum reward that can operator hold.
   */
  function setMinFee (uint256 _fee) external onlyOwner {
      _checkAndRevert(MathUtils.validPercentage(_fee, 0, percentage_),"Invalid Percentage Input");
      _checkAndRevert(_fee != operatorFees_.minFee,"Same Reward exists");

      _setMinFee(_fee);

      emit FeeUpdated(epochManager_.currentEpoch(), _fee, operatorFees_.maxReward);
  }


  /**
   * @dev Function to onboard operators to on-chain.
   * @notice This function will be called by the admin.
   * @param _operatorAddress is the address of the operator.
   * @param _feeCut is the minimum fee that can operator hold.
   * @param _rewardCut is the maximum earned reward that can operator hold.
   * @param _fileHash is the IPFS hash representing the config metadata.
   */
  function onboardOperator(address _operatorAddress, uint256 _feeCut, uint256 _rewardCut,string memory _fileHash) 
    external onlyManager {
      _checkAndRevert(!_isEmptyString(_fileHash),"Filehash is required");
      _checkAndRevert(_isEmptyString(operators_[_operatorAddress].fileHash),"Operator already exists");
      _checkAndRevert(
            MathUtils.validPercentage(_feeCut, operatorFees_.minFee, percentage_) && 
            MathUtils.validPercentage(_rewardCut, 0, operatorFees_.maxReward),
            "Invalid Percentage Input"
        );
      operators_[_operatorAddress] = OperatorNode(_feeCut, _rewardCut, _fileHash, true);

      emit OperatorOnboarded(_operatorAddress, _feeCut, _rewardCut, _fileHash);
  }

  /**
   * @dev Function to activate/de-activate operators in chain.
   * @notice This function will be called by the admin.
   * @param _operatorAddress is the address of the operator.
   * @param _status is the new status of the operator.
   */
  function updateOperatorStatus(address _operatorAddress,bool _status) external onlyManager {
    if(_status){
      _checkAndRevert(!_isEmptyString(operators_[_operatorAddress].fileHash),"Operator does Not exists");
      _checkAndRevert(!operators_[_operatorAddress].active,"Operator is already active");
      operators_[_operatorAddress].active = true;
    }
    else {
      _checkAndRevert(operators_[_operatorAddress].active,"Operator is not active");
      operators_[_operatorAddress].active = false;
    }

    emit OperatorStatus(_operatorAddress, epochManager_.currentEpoch(), _status);
  }


  /**
   * @dev Function to update the rewardCut of operator in chain.
   * @notice This function only called by Onboarded Operators.
   * @param _rewardCut is the maximum earned reward that can operator hold.
   */
  function updateOperatorRewardCut(uint256 _rewardCut) external {
      address operator = _msgSender();
      _checkAndRevert(operators_[operator].active,"Operator is not active");
      _checkAndRevert((_rewardCut != operators_[operator].rewardCut),"Same Fees exists");
      _checkAndRevert(
          MathUtils.validPercentage(_rewardCut, 0, operatorFees_.maxReward),"Invalid Percentage Input"
      );
      operators_[operator].rewardCut = _rewardCut;
      emit OperatorFeesUpdated(operator, epochManager_.currentEpoch(), operators_[operator].feeCut, _rewardCut);
  }

  /**
   * @dev Function to update the feeCut of operator in chain.
   * @notice This function only called by Onboarded Operators.
   * @param _feeCut is the minimum fee that can operator hold.
   */
  function updateOperatorFeeCut(uint256 _feeCut) external {
      address operator = _msgSender();
      _checkAndRevert(operators_[operator].active,"Operator is not active");
      _checkAndRevert((_feeCut != operators_[operator].feeCut),"Same Fees exists");
      _checkAndRevert(
          MathUtils.validPercentage(_feeCut, operatorFees_.minFee, percentage_),"Invalid Percentage Input"
      );
      operators_[operator].feeCut = _feeCut;
      emit OperatorFeesUpdated(operator, epochManager_.currentEpoch(), _feeCut, operators_[operator].rewardCut);
  }

  /**
   * @dev Function to update wether to Claim Reward for operator or Delegate it.
   * @notice This function only called by Onboarded Operators.
   * @param _claimReward is the boolean mentioning wether to claim the rewards.
   */
  function setClaimRewardStatus(bool _claimReward) external nonReentrant {
      address operator = _msgSender();
      _checkAndRevert(operators_[operator].active,"Operator is not active");
      _checkAndRevert((claimRewards_[operator] != _claimReward),"Same Status Exists");
      
      claimRewards_[operator] = _claimReward;
      emit OperatorClaimStatusUpdated(operator, epochManager_.currentEpoch(), claimRewards_[operator]);
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