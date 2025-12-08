// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { Context } from "../GovernanceController/Context/Context.sol";
import { MathUtils } from "../Utils/MathUtils.sol";
import { MerchantV1Storage } from "./Storage.sol";

/**
 * @author  token13 Platform. 
 * @title   Merchant Registry Contract
 * @dev     Manages merchants: onboard, update status, receiver, token support.
 */

contract MerchantRegistry is Context, MerchantV1Storage {


  // -------------------------
  // EVENTS
  // -------------------------


  /**
    * @notice Emitted when a new merchant is onboarded.
    * @param merchantId Unique identifier for the merchant.
    * @param fundReceiver Address where the merchant receives funds.
    * @param active Whether the merchant is active or not.
  */
  event MerchantOnboarded(
    bytes32 indexed merchantId,
    address fundReceiver,
    bool active
  );


  /**
    * @notice Emitted when a merchant's supported token status is updated.
    * @param merchantId Unique identifier for the merchant.
    * @param token The token address being enabled/disabled.
    * @param status True if token is enabled, false if disabled.
  */ 
  event MerchantTokenUpdated(
    bytes32 indexed merchantId,
    address token,
    bool status  
  );


  /**
    * @notice Emitted when a merchant's active status is updated.
    * @param merchantId Unique identifier for the merchant.
    * @param active New active status of the merchant.
  */
  event MerchantStatusUpdated(
    bytes32 indexed merchantId,
    bool active
  );


  /**
    * @notice Emitted when a merchant's fund receiver address is updated.
    * @param merchantId Unique identifier for the merchant.
    * @param fundReceiver New fund receiver address.
  */
  event MerchantReceiverAddressUpdated(
    bytes32 indexed merchantId,
    address fundReceiver
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



  // -------------------------
  // MERCHANT FUNCTIONS
  // -------------------------

  /**
    * @notice Onboard a merchant
    * @param merchantId merchant unique bytes32 ID
    * @param fundReceiver address receiving funds
    * @param active initial active status
  */

  function MerchantOnboard(
    bytes32 merchantId_,
    address fundReceiver_,
  )external {

    _checkAndRevertMessage(merchantId_ != bytes32(0), "Invalid merchantId");
    _checkAndRevertMessage(fundReceiver_ != address(0), "Invalid receiver");
    _checkAndRevertMessage(!merchants_[merchantId_].registered, "Merchant already registered");

    merchants_[merchantId].fundReceiver = fundReceiver;
    merchants_[merchantId].active = active;

    emit MerchantOnboarded(
      merchantId,
      fundReceiver,
      active
    );
  }
      

  /**
    * @notice Update merchant active/inactive status
    * @param merchantId merchant ID
    * @param active new status
  */

  function updateMerchantStatus(
    bytes32 merchantId,
    bool active
  ) external {

    _checkAndRevertMessage(merchants_[merchantId].registered, "Merchant not registered");
    _checkAndRevertMessage(merchants_[merchantId].active != active, "Status unchanged");
    
    merchants_[merchantId].active = active;
    emit MerchantStatusUpdated(merchantId, active);
  }


  /**
    * @notice Update whether token is supported for merchant
    * @param merchantId merchant ID
    * @param token token address
    * @param status true/false support
  */

  function updateMerchanttokenStatus(
    bytes32 merchantId,
    IERC20Upgradeable token,
    bool status
  ) external {

    _checkAndRevertMessage(merchants_[merchantId].registered, "Merchant not registered");
    _checkAndRevertMessage(address(token) != address(0), "Invalid token");
    _checkAndRevertMessage(merchants_[merchantId].supportedTokens[address(token)] != status, "Status unchanged");


    merchants_[merchantId].supportedTokens[token] = status;

    emit MerchantTokenUpdated(
      merchantId,
      token,
      status
    );
  }

  /**
    * @notice Update merchant fund receiving wallet
    * @param merchantId merchant ID
    * @param newReceiver new fund receiver address
  */ 
    
  function updateMerchantReceiverAddress(
    bytes32 merchantId,
    address newReceiver
  ) external {

    _checkAndRevertMessage(merchants_[merchantId].registered, "Merchant not registered");
    _checkAndRevertMessage(newReceiver != address(0), "Invalid receiver");
    _checkAndRevertMessage(merchants_[merchantId].fundReceiver != newReceiver, "Receiver unchanged");
    

     merchants_[merchantId].fundReceiver = newReceiver;

    emit MerchantReceiverAddressUpdated(
      merchantId,
      newReceiver
    );
  }


  // -------------------------
  // VIEW FUNCTIONS
  // -------------------------

  /**
  * @notice Returns whether a specific token is supported for a merchant
  */
  function isMerchantTokenSupported(bytes32 merchantId, address token)
      external
      view
      returns (bool)
      {
          return merchants_[merchantId].supportedTokens[token];
      }

  /**
  * @notice Returns whether a merchant is active
  */
  function isMerchantActive(bytes32 merchantId)
      external
      view
      returns (bool)
      {
          return merchants_[merchantId].active;
      }

  /**
  * @notice Returns the merchant's fund receiver address
  */
  function getMerchantFundReceiver(bytes32 merchantId)
      external
      view
      returns (address)
      {
          return merchants_[merchantId].fundReceiver; 
      }

}