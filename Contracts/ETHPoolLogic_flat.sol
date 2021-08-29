pragma solidity ^0.5.17;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 * - Addition cannot overflow.
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 * - Subtraction cannot overflow.
	 *
	 * _Available since v2.4.0._
	 */
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 * - Multiplication cannot overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 *
	 * _Available since v2.4.0._
	 */
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b != 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	 * @dev Integer division of two numbers, rounding up and truncating the quotient
	 */
	function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
		return divCeil(a, b, "SafeMath: division by zero");
	}

	/**
	 * @dev Integer division of two numbers, rounding up and truncating the quotient
	 */
	function divCeil(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b != 0, errorMessage);

		if (a == 0) {
			return 0;
		}
		uint256 c = ((a - 1) / b) + 1;

		return c;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 */
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts with custom message when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 * - The divisor cannot be zero.
	 *
	 * _Available since v2.4.0._
	 */
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}

	function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return _a < _b ? _a : _b;
	}
}

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
	/// @dev Constant for unlocked guard state - non-zero to prevent extra gas costs.
	/// See: https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1056
	uint256 internal constant REENTRANCY_GUARD_FREE = 1;

	/// @dev Constant for locked guard state
	uint256 internal constant REENTRANCY_GUARD_LOCKED = 2;

	/**
	 * @dev We use a single lock for the whole contract.
	 */
	uint256 internal reentrancyLock = REENTRANCY_GUARD_FREE;

	/**
	 * @dev Prevents a contract from calling itself, directly or indirectly.
	 * If you mark a function `nonReentrant`, you should also
	 * mark it `external`. Calling one `nonReentrant` function from
	 * another is not supported. Instead, you can implement a
	 * `private` function doing the actual work, and an `external`
	 * wrapper marked as `nonReentrant`.
	 */
	modifier nonReentrant() {
		require(reentrancyLock == REENTRANCY_GUARD_FREE, "nonReentrant");
		reentrancyLock = REENTRANCY_GUARD_LOCKED;
		_;
		reentrancyLock = REENTRANCY_GUARD_FREE;
	}
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
	// Empty internal constructor, to prevent people from mistakenly deploying
	// an instance of this contract, which should be used via inheritance.
	constructor() internal {}

	// solhint-disable-previous-line no-empty-blocks

	function _msgSender() internal view returns (address payable) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() internal {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view returns (address) {
		return _owner;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(isOwner(), "unauthorized");
		_;
	}

	/**
	 * @dev Returns true if the caller is the current owner.
	 */
	function isOwner() public view returns (bool) {
		return _msgSender() == _owner;
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 */
	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

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

/**
 * @title Storage and List of events contract.
 * */
contract ETHPoolData is ETHPoolStorage {
	
	/// @notice An event emitted when a user stakes an amount of ETH.
	event Deposit(address indexed user, uint256 amount);

	/// @notice An event emitted when unstake funds along with certain reward.
	/// @dev the refund parameter is the total amount withdrawn, the claim is the reward claimed.
	event ETHWithdrawn(address indexed user, address receiver, uint256 refund, uint256 claim);

	/// @notice An event emitted when rewards are paid by the Team.
	event RewardPaid(uint256 _time, uint256 _rwd);
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
	/**
	 * @dev Returns true if `account` is a contract.
	 *
	 * [IMPORTANT]
	 * ====
	 * It is unsafe to assume that an address for which this function returns
	 * false is an externally-owned account (EOA) and not a contract.
	 *
	 * Among others, `isContract` will return false for the following
	 * types of addresses:
	 *
	 *  - an externally-owned account
	 *  - a contract in construction
	 *  - an address where a contract will be created
	 *  - an address where a contract lived, but was destroyed
	 * ====
	 */
	function isContract(address account) internal view returns (bool) {
		// According to EIP-1052, 0x0 is the value returned for not-yet created accounts
		// and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
		// for accounts without code, i.e. `keccak256('')`
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			codehash := extcodehash(account)
		}
		return (codehash != accountHash && codehash != 0x0);
	}

	/**
	 * @dev Converts an `address` into `address payable`. Note that this is
	 * simply a type cast: the actual underlying value is not changed.
	 *
	 * _Available since v2.4.0._
	 */
	function toPayable(address account) internal pure returns (address payable) {
		return address(uint160(account));
	}

	/**
	 * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
	 * `recipient`, forwarding all available gas and reverting on errors.
	 *
	 * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
	 * of certain opcodes, possibly making contracts go over the 2300 gas limit
	 * imposed by `transfer`, making them unable to receive funds via
	 * `transfer`. {sendValue} removes this limitation.
	 *
	 * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
	 *
	 * IMPORTANT: because control is transferred to `recipient`, care must be
	 * taken to not create reentrancy vulnerabilities. Consider using
	 * {ReentrancyGuard} or the
	 * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html
	 *   #use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
	 *
	 * _Available since v2.4.0._
	 */
	function sendValue(address recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");

		// solhint -disable-next-line avoid-call-value
		// value is expressed in wei by default
		(bool success, ) = recipient.call.value(amount)("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}
}

/**
 * @title ETHPool contract.
 * @notice Pay-in and pay-out function for ETHPool.
 * */
contract ETHPool is ETHPoolData, ReentrancyGuard {

}