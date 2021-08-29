pragma solidity ^0.5.17;

/**
 * @title ETHPool Storage contact.
 * @notice Just the storage part of stacking contract, no functions,
 * only constant, variables and required structures (mappings).
 * */
contract ETHPoolStorage is Ownable {
	/// @notice 1 day in seconds.
	uint256 public constant ONE_DAY = 86400;

	/// @notice SIGMA_REFERENCE is one WEI staked by a week = 7 "WEI*weekS".
	/// @dev netSigUrwd * weight / SIGMA_REFERENCE is the amount of WEI paid as reward.
	uint256 public constant SIGMA_REFERENCE = 7 * ONE_DAY;

	/// @notice in which moment the Nth rewadr was paid.
	mapping(uint256 => uint256) public weeksTime;

	/// @notice the weight of a reward according the moment it was paid.
	mapping(uint256 => uint256) public weights;

	/// @notice The net Sigma value under reward.
	/// @dev netSigmaRwd is the net amount of WEIs staked each second, weighted by rewards.
	uint256 public netSigmaRwd;

	/// @notice The net Sigma value NOT under reward.
	/// @dev netSigmaUrwd is the net amount of WEIs staked each second BEFORE its reward payment.
	uint256 public netSigmaUrwd;	

	/// @notice Total funds in WEI deposited as reward in the contract.
	uint256 public Rwd;

	/// @notice Total funds in WEI deposited by users in the contract.
	uint256 public balanceOf;

	/// @notice The last global check-point as unix epoch format.
	// uint256 public chPnt = weeksTime[lastChkPointCount] (not needed)

	/// @notice The last week-number recorded in which a reward payment should have occur.
	uint256 public lastChkPointCount;

	/*************************** user's info *******************************/

	/// @notice structure of user's data.
	/// @dev parameters with the same meaning as for the main storage above.
	struct userInfo {
		uint256 netSigmaRwd;
		uint256 netSigmaUrwd;
		uint256 balanceOf;
		uint256 chPnt;
		uint256 balanceOfRwd;	// 		The user's funds that has already a reward associated to claim.			
	}

	/// @notice data recorded for each user.
	mapping(address => userInfo) public userInfoMap;
	
}