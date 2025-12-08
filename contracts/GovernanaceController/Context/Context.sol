// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import { GovernanceController } from "../Governance/Controller.sol";

/**
 * @author  bitsCrunch, GmbH.
 * @title   BitsCrunch Context contract
 * @dev     This Contracts is to fetch the signer of the message
 */

contract Context is GovernanceController {

    /**
     * @dev function to return the signer of the message
     * @return signer of the message
     */

  function _msgSender() internal override view returns (address) {
    address signer_ = msg.sender;
    return signer_;
  }
}
