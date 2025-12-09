// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import { Context } from "../GovernanaceController/Context/Context.sol";
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
    * @param oldReceiver Old fund receiver address.
    * @param newReceiver New fund receiver address.
  */
  event MerchantReceiverAddressUpdated(
    bytes32 indexed merchantId,
    address oldReceiver,
    address newReceiver
  );
    


  // initialised for upgradation usage
  uint256[50] private __gap;

  /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    } 

  /**
    * @dev Initializes the Merchant Registry Contract.
    * @param _rootAdmin is the address of Admin to have Admin privilege.
  */
  function initialize(
    address _rootAdmin
    ) external initializer {
      __Governance_init_unchained(_rootAdmin);
    }


 /**
  * @notice Onboard a new merchant
  * @param _merchantId merchant ID
  * @param _fundReceiver fund receiving address
 */
function onboardMerchant(
    bytes32 _merchantId,
    address _fundReceiver
) external {
    _checkAndRevertMessage(_merchantId != bytes32(0), "Invalid merchantId");
    _checkAndRevertMessage(_fundReceiver != address(0), "Invalid receiver");
    _checkAndRevertMessage(
        !merchants_[_merchantId].registered,
        "Merchant already registered"
    );

    MerchantConfig storage merchant = merchants_[_merchantId];

    merchant.fundReceiver = _fundReceiver;
    merchant.registered = true;
    merchant.active = true;
    // supportedTokens mapping is implicitly empty (all false)

    emit MerchantOnboarded(
        _merchantId,
        _fundReceiver,
        true
    );
  }

      

  /**
    * @notice Update merchant Live Status
    * @param _merchantId merchant ID
    * @param _active new status
  */

  function updateMerchantStatus(
    bytes32 _merchantId,
    bool _active
  ) external {

    _checkAndRevertMessage(merchants_[_merchantId].registered, "Merchant not registered");
    _checkAndRevertMessage(merchants_[_merchantId].active != _active, "Same status exists");
    
    merchants_[_merchantId].active = _active;
    emit MerchantStatusUpdated(_merchantId, _active);
  }


  /**
    * @notice Update whether token is supported for merchant
    * @param _merchantId merchant ID
    * @param _token token address
    * @param _status true/false support
  */

  function updateMerchantTokenStatus(
    bytes32 _merchantId,
    address _token,
    bool _status
) external {
    MerchantConfig storage merchant = merchants_[_merchantId];

    _checkAndRevertMessage(merchant.registered, "Merchant not registered");
    _checkAndRevertMessage(merchant.active, "Merchant not active");
    _checkAndRevertMessage(
        merchant.supportedTokens[_token] != _status,
        "Same status exists"
    );

    _validateTokenOnEnable(_token, _status);

    merchant.supportedTokens[_token] = _status;

    emit MerchantTokenUpdated(_merchantId, _token, _status);
}

  /**
    * @notice Update merchant fund receiving wallet
    * @param _merchantId merchant ID
    * @param _newReceiver new fund receiver address
  */ 
    
  function updateMerchantReceiverAddress(
    bytes32 _merchantId,
    address _newReceiver
  ) external {

    _checkAndRevertMessage(merchants_[_merchantId].active, "Merchant not active");
    _checkAndRevertMessage(_newReceiver != address(0), "Invalid receiver");

    address oldReceiver = merchants_[_merchantId].fundReceiver;
    _checkAndRevertMessage(oldReceiver != _newReceiver, "Receiver unchanged");
    
    merchants_[_merchantId].fundReceiver = _newReceiver;

    emit MerchantReceiverAddressUpdated(
      _merchantId,
      oldReceiver,
      _newReceiver
    );
  }

  /**
    * @notice Validates token when enabling support
    * @param _token token address
    * @param _status true/false support
  */
  function _validateTokenOnEnable(address _token, bool _status) private view {
    if (!_status) return;            // only when enabling
    if (_token == address(0)) return; // TRX, no TRC20 check

    _checkAndRevertMessage(_token.code.length > 0, "Token not contract");

    (bool ok1, ) = _token.staticcall(
        abi.encodeWithSelector(0x70a08231, address(this)) // balanceOf(address)
    );
    _checkAndRevertMessage(ok1, "Invalid TRC20 token");
  }



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

  /**
  * @notice Helper To Generate Merchant Id from Name
  */
  function nameToId(string memory name) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(name));
  }

}