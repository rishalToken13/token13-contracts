// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { Context } from "../GovernanceController/Context/Context.sol";
import { MathUtils } from "../Utils/MathUtils.sol";
import { MerchantV1Storage } from "./Storage.sol";

/**
 * @author  token13 Platform
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
    bytes32 merchantId,
    address fundReceiver,
    bool active
  )external {

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
    address token,
    bool status
  ) external {

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

     merchants_[merchantId].fundReceiver = newReceiver;

    emit MerchantReceiverAddressUpdated(
      merchantId,
      newReceiver
    );
  }



}