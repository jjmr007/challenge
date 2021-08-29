pragma solidity ^0.5.17;

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

	// solhint- disable-previous-line no-empty-blocks

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
	uint256 public chPnt;

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
 * @title Base Proxy contract.
 * @notice The proxy performs delegated calls to the contract implementation
 * it is pointing to. This way upgradable contracts are possible on blockchain.
 *
 * Delegating proxy contracts are widely used for both upgradeability and gas
 * savings. These proxies rely on a logic contract (also known as implementation
 * contract or master copy) that is called using delegatecall. This allows
 * proxies to keep a persistent state (storage and balance) while the code is
 * delegated to the logic contract.
 *
 * Proxy contract is meant to be inherited and its internal functions
 * _setImplementation and _setProxyOwner to be called when upgrades become
 * neccessary.
 *
 * The loan token (iToken) contract as well as the protocol contract act as
 * proxies, delegating all calls to underlying contracts. Therefore, if you
 * want to interact with them using web3, you need to use the ABIs from the
 * contracts containing the actual logic or the interface contract.
 *   ABI for LoanToken contracts: LoanTokenLogicStandard
 *   ABI for Protocol contract: ISovryn
 *
 * @dev UpgradableProxy is the contract that inherits Proxy and wraps these
 * functions.
 * */
contract Proxy {
	bytes32 private constant KEY_IMPLEMENTATION = keccak256("key.implementation");
	bytes32 private constant KEY_OWNER = keccak256("key.proxy.owner");

	event OwnershipTransferred(address indexed _oldOwner, address indexed _newOwner);
	event ImplementationChanged(address indexed _oldImplementation, address indexed _newImplementation);

	/**
	 * @notice Set sender as an owner.
	 * */
	constructor() public {
		_setProxyOwner(msg.sender);
	}

	/**
	 * @notice Throw error if called not by an owner.
	 * */
	modifier onlyProxyOwner() {
		require(msg.sender == getProxyOwner(), "Proxy:: access denied");
		_;
	}

	/**
	 * @notice Set address of the implementation.
	 * @param _implementation Address of the implementation.
	 * */
	function _setImplementation(address _implementation) internal {
		require(_implementation != address(0), "Proxy::setImplementation: invalid address");
		emit ImplementationChanged(getImplementation(), _implementation);

		bytes32 key = KEY_IMPLEMENTATION;
		assembly {
			sstore(key, _implementation)
		}
	}

	/**
	 * @notice Return address of the implementation.
	 * @return Address of the implementation.
	 * */
	function getImplementation() public view returns (address _implementation) {
		bytes32 key = KEY_IMPLEMENTATION;
		assembly {
			_implementation := sload(key)
		}
	}

	/**
	 * @notice Set address of the owner.
	 * @param _owner Address of the owner.
	 * */
	function _setProxyOwner(address _owner) internal {
		require(_owner != address(0), "Proxy::setProxyOwner: invalid address");
		emit OwnershipTransferred(getProxyOwner(), _owner);

		bytes32 key = KEY_OWNER;
		assembly {
			sstore(key, _owner)
		}
	}

	/**
	 * @notice Return address of the owner.
	 * @return Address of the owner.
	 * */
	function getProxyOwner() public view returns (address _owner) {
		bytes32 key = KEY_OWNER;
		assembly {
			_owner := sload(key)
		}
	}

	/**
	 * @notice Fallback function performs a delegate call
	 * to the actual implementation address is pointing this proxy.
	 * Returns whatever the implementation call returns.
	 * */
	function() external payable {
		address implementation = getImplementation();
		require(implementation != address(0), "Proxy::(): implementation not found");

		assembly {
			let pointer := mload(0x40)
			calldatacopy(pointer, 0, calldatasize)
			let result := delegatecall(gas, implementation, pointer, calldatasize, 0, 0)
			let size := returndatasize
			returndatacopy(pointer, 0, size)

			switch result
			case 0 {
				revert(pointer, size)
			}
			default {
				return(pointer, size)
			}
		}
	}
}

/**
 * @title Upgradable Proxy contract.
 * @notice A disadvantage of the immutable ledger is that nobody can change the
 * source code of a smart contract after it’s been deployed. In order to fix
 * bugs or introduce new features, smart contracts need to be upgradable somehow.
 *
 * Although it is not possible to upgrade the code of an already deployed smart
 * contract, it is possible to set-up a proxy contract architecture that will
 * allow to use new deployed contracts as if the main logic had been upgraded.
 *
 * A proxy architecture pattern is such that all message calls go through a
 * Proxy contract that will redirect them to the latest deployed contract logic.
 * To upgrade, a new version of the contract is deployed, and the Proxy is
 * updated to reference the new contract address.
 * */
contract UpgradableProxy is Proxy {
	/**
	 * @notice Set address of the implementation.
	 * @dev Wrapper for _setImplementation that exposes the function
	 * as public for owner to be able to set a new version of the
	 * contract as current pointing implementation.
	 * @param _implementation Address of the implementation.
	 * */
	function setImplementation(address _implementation) public onlyProxyOwner {
		_setImplementation(_implementation);
	}

	/**
	 * @notice Set address of the owner.
	 * @param _owner Address of the owner.
	 * */
	function setProxyOwner(address _owner) public onlyProxyOwner {
		_setProxyOwner(_owner);
	}
}

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