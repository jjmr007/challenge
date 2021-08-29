pragma solidity ^0.5.17;

import "./Inherited/ETHPoolStorage.sol";
import "./Inherited/UpgradableProxy.sol";

/**
 * @title ETHPool Proxy contract.
 * @dev ETHPool contract should be upgradable, use UpgradableProxy.
 * ETHPoolStorage is deployed with the upgradable functionality
 * by using this contract instead, that inherits from UpgradableProxy
 * the possibility of being enhanced and re-deployed.
 * */
contract ETHPoolProxy is ETHPoolStorage, UpgradableProxy {
	/**
	 * @notice Construct a new ETHPool contract.
	 * @dev we assume that the deployment occurs on the beginning of the week.
	 */
	constructor() public {
		weeksTime[0] = block.timestamp;
	}
}