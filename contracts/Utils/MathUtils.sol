// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title MathUtils Library
 * @notice A collection of functions to perform math operations
 */
library MathUtils {
    /**
     * @dev Calculates the weighted average of two values pondering each of these
     * values based on configured weights. The contribution of each value N is
     * weightN/(weightA + weightB).
     * @param valueA The amount for value A
     * @param weightA The weight to use for value A
     * @param valueB The amount for value B
     * @param weightB The weight to use for value B
     */
    function weightedAverage(
        uint256 valueA,
        uint256 weightA,
        uint256 valueB,
        uint256 weightB
    ) internal pure returns (uint256) {
        return (
            ((valueA * weightA )+ (valueB * weightB))/(weightA + weightB)
        );
    }

    /**
     * @dev Returns the minimum of two numbers.
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    /**
     * @dev Returns the difference between two numbers or zero if negative.
     */
    function diffOrZero(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? x-y : 0;
    }

    /**
     * @dev Returns the Percentage of the given inputs
     */
    function percentageOf(uint256 value, uint256 percent, uint256 multiplier) internal pure returns (uint256) {
        return ((value * percent) / multiplier);
    }

    function validPercentage(uint256 _val,uint256 _min,uint256 _max) internal pure returns (bool) {
        return (_val <= _max && _val >= _min);
    }
}
