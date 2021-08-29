pragma solidity ^0.5.17;

import "./Inherited/ETHPoolData.sol";
import "./OpnZepp/ReentrancyGuard.sol";
import "./OpnZepp/SafeMath.sol";
import "./OpnZepp/Address.sol";

/**
 * @title ETHPool contract.
 * @notice Pay-in and pay-out function for ETHPool.
 * */
contract ETHPool is ETHPoolData, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address payable;

	/// @notice Constant used for computing the reward points.
	uint256 constant ONE_WEEK = 1 weeks;

    /// @notice modifier to only allow deposit rewards on Sunday
    modifier onAwardTime() {
    }

	/****************************** main functions ******************************/

	/**
	 * @notice deposit the amount given by msg.value for msg.sender.
	 * */
	function deposit() payable public returns (bool) {
		// we'll need the time, the user and the value
		uint256 _time           = block.timestamp;
        address payable _user   = _msgSender();
        uint256 _amount         = msg.value; 
		// first, update the storage parameters of the cotnract
		_globalUpdate(_amount, _time, true);
		// then, update the user's data
		_updateUser(_user, _time);
		// the new accountant state for the user
		_deposit(_user, _amount);
		emit Deposit(_user, _amount);
	}

	/**
	 * @notice Withdraw the given amount of ETH if _checkless is true.
	 * @param amount The number of ETH to withdraw.
	 * @param receiver The receiver of the tokens. If not specified, send to the msg.sender
	 * */
	function withdraw(
		uint256 amount,
		address receiver
	) public nonReentrant returns (bool) {
		// we'll need the time and the msg.sender
		uint256 _time           = block.timestamp;
        address payable _user   = _msgSender();
		/// @notice first, update the storage parameters of the cotnract
		/// @dev the amount can not be deducted yet, but afer the _checkless
		_globalUpdate(0, _time, false);		
		/// @dev Determine the receiver.
		if (receiver == address(0)) receiver = _user;
		// then, update the user's data
		_updateUser(_user, _time);
		// check if users has enough balance
		(_less, _rwd, _enough) = _checkLess(_user, amount);
		// and then, if there is enugh, withdraw
		if (_enough) return _withdraw(receiver, _user, amount, _rwd, _less);
	}

	/**
	 * @notice accredits the msg.value of ETH as reward for the last week.
	 * */
	function award() payable public onlyOwner onAwardTime returns(bool) {
		// we'll need the time and the reward amount
		uint256 _time   = block.timestamp;
        uint256 _rwd    = msg.value;
		// first, update the storage parameters of the cotnract
		_globalUpdate(0, _time, true);
		// next execute the state change
		_award(_rwd);
        emit RewardPaid(_time, _rwd);
	}

	/************************* main internal functions **************************/


	/**
	 * @notice Updates global parameters on storage.
	 * @param _amount The number of ETH to send/remove.
	 * @param _time The point of time to be recorded.
	 * @param _pay Boolean which discriminate if this is a deposit or withdraw.
	 * */
	function _globalUpdate(
		uint256	_amount,
		uint256 _time,
		bool	_pay,
	) internal {
		/// @dev Check if within the award time there was a payment; if not, padd with values weeksTime.
		_padding(_time);
		/// @dev Proceed with the actual update.
		_update(_amount, _pay);
	}

	/**
	 * @notice Updates user's parameters on userInfoMap.
	 * @param _user the address of the user.
	 * */
	function _updateUser(
		address	_user,
		uint256 _timeStamp
	) internal {
		/// @notice distance between `block.timestamp` and `userInfoMap[_user].lastChkPoint`
		/// @dev will record on _distance the number of weeks rounded down.
		userInfo _userData = userInfoMap[_user];
		uint256 _then = _userData.lastChkPoint;
		uint256 _distance = _compare(block.timestamp, _then);
		uint256 _weekNumber = _findPoint(_distance);
		if (lastChkPointCount > _weekNumber) {
			uint256 _farthestPoint = weeksTime[_weekNumber];
			_userData = _severalUpdates(_userData, _farthestPoint);
		} else {
			uint256 _checkPointTime = weeksTime[_weekNumber];
			if (_checkPointTime != 0) {
			require(_checkPointTime == weeksTime[lastChkPointCount], "wrong _findPoint");
			_userData = _singleUpdate(_userData, _checkPointTime);
			} 
		}
		_rollOver(_userData, _timeStamp);
	}
	
	/**
	 * @notice Register the new user's deposit in userInfoMap.
	 * @param _user the address of the user.
	 * @param _amount is the number of ETH sent by the user to the pool.
	 * _timeStamp is leaved as a spare parameter
	 * */
	function _deposit(
		address	_user,
		uint256	_amount,
	//	uint256	_timeStamp,		
	) internal {
		/// @notice increase the value of `userInfoMap[_user].balanceOf`
		/// @dev we'll use SafeMath.
		userInfoMap[_user].balanceOf = add(userInfoMap[_user].balanceOf, _amount);
	//	userInfoMap[_user].chPnt = _timeStamp;
	}	

	/**
	 * @notice Check if the amount to be withdrawn is >= the available amount of the user.
	 * @param _user user address.
	 * @param _amount The number of ETH to be withdarwn.
	 * */
	function _checkLess(
		address _user,
		uint256 _amount,
	) internal returns (uint256, uint256, bool) {
		uint256 _sigRwd		= userInfoMap[_user].netSigmaRwd;
		uint256 _depRwd		= userInfoMap[_user].balanceOfRwd;
		uint256 _rwd		= _sigRwd.mul(Rwd).div(netSigmaRwd);
		uint256 _deposited	= userInfoMap[_user].balanceOf;
		uint256 _less;
		require(_amount <= _rwd + _deposited, "ETHPool: user has not enough available");
		if (_amount < _rwd + _depRwd) {
				_less		=  _rwd.mul(_amount).div(_depRwd);
				Rwd			= Rwd.sub(_less);
				balanceOf	= add(balanceOf, _less).sub(amount);
				// time checkpoints and sigmas were updated via _globalUpdate
		} else { 
				_less		=  _rwd;
				Rwd			= Rwd.sub(_less);
				balanceOf	= add(balanceOf, _less).sub(amount);
				// time checkpoints and sigmas were updated via _globalUpdate
		 }
		return (_less, _rwd, true);
	}

	/**
	 * @notice Is the last step in the withdraw process.
	 * if _rdw == _less the whole reward is withdrawn along with all user's balanceOfRwd.
	 * and we set netSigmaRwd =  0.
	 * if _rdw > _less the proportion of the user's reward is withdrawn
	 * along with the correspondant proportion of balanceOfRwd; also the netSigmaRwd
	 * is reduced to the same proportion.
	 *
	 * @param receiver The beneficiary of the withdraw.
	 * @param _user The user as recorded in infoUserMap.
	 * @param amount The amount of ETH to be sent to receiver.
	 * @param _rwd total user's reward.
	 * @param _less portion of the reward to be withdrawn.
	 * _timeStamp is leaved as a spare parameter
	 * */
	function _withdraw(
		address payable receiver,
		address payable _user,		
		uint256 amount,
		uint256 _rwd,
		uint256 _less,		
	//	uint256	_timeStamp,				
	) internal returns (bool) {
		/// @notice first compare _rwd and _less
		bool takeAllRwd = _rwd == _less ? true : false;
		/// @dev check that _less is never above _rwd
		require(_rwd >= _less, "reward wrong estimation");
		userInfoMap[_user].balanceOf = add(userInfoMap[_user].balanceOf, _less).sub(amount);
		userInfo _userData = userInfoMap[_user];
		if (takeAllRwd) {
			// we must check always that  balanceOf >= balanceOfRw
			uint256 _relation	= (_userData.balanceOf).sub(_userData.balanceOfRw);
			uint256 _sum		= (_userData.balanceOf).add(_rwd).sub(amount);
			userInfoMap[_user].netSigmaRwd	= 0;
			userInfoMap[_user].balanceOfRwd	= 0;
			userInfoMap[_user].netSigmaUrwd = 
            sub(userInfoMap[_user].netSigmaUrwd, 
                _sum.mul(_userData.netSigmaUrwd).div(_relation));		
		} else {
			uint256 _ratio		= _rwd.sub(_less);
			userInfoMap[_user].netSigmaRwd	= _ratio.mul(_userData.netSigmaRwd).div(_rwd);
			userInfoMap[_user].balanceOfRwd	= _ratio.mul(_userData.balanceOfRwd).div(_rwd);;		
		}
		sendValue(receiver, amount);
	//	userInfoMap[_user].chPnt = _timeStamp;		
		emit ETHWithdrawn(_user, receiver, amount, _less);
		return true;
	}

	/**
	 * @notice Deposit the reward and update the storage parameters.
	 * @param _rwd The amount of reward to be paid by the Team.
	 * */
	function _award(
		uint256 _rwd,
		uint256 _time
	) internal {
    }

	/************************* basic internal functions **************************/


	/**
	 * @notice Populates with values the points of weeksTime map with missing reward payments.
	 * @param amount The number of tokens to withdraw.
	 * @param until The date until which the tokens were staked.
     * anybody can execute this.
	 * */
	function _padding(uint256 timePoint) internal {
	}

	/**
	 * @notice updates the global balance.
	 * @param _amount how much will change balanceOf.
	 * @param _pay is or not a withdraw.
	 * */
	function _update(uint256 _amount, bool _pay) internal returns (bool) {
	}    

	/**
	 * @notice how many weeks has passed from _then to _now.
	 * @param _now the most recent point on time.
	 * @param _then the oldes point in time.
     * @dev _now must be greater than _then.
	 * */
	function _compare(uint256 _now, uint256 _then) internal returns (uint256) {
	}

	/**
	 * @notice find the week-time number after the point in time _then.
	 * @param _distance the integer part of the numbers of weeks.
	 * */
	function _findPoint(uint256 _distance) internal returns (uint256) {
	}    

	/**
	 * @notice add weighted values to the user.netSigmaRwd when several weeks has passed.
	 * @param _userData struct with user's data.
	 * @param _initialPoint user's farthest point in time.
	 * */
	function _severalUpdates(userInfo _userData, uint256 _initialPoint) internal returns (userInfo) {
	}

	/**
	 * @notice add weighted values to the user.netSigmaRwd.
	 * @param _userData struct with user's data.
	 * @param _initialPoint user's farthest point in time.
	 * */
	function _singleUpdate(userInfo _userData, uint256 _initialPoint) internal returns (userInfo) {
	}    

	/**
	 * @notice updates the value of user.netSigmaUrwd, which do not depends on weights.
	 * @param _userData struct with user's data.
	 * @param _initialPoint user's farthest point in time.
	 * */
	function _rollOver(userInfo _userData, uint256 _now) internal {
	}

	/***************************** getter functions ******************************/    

	/**
	 * @notice Get the current reward balance of a user's account.
	 * */
	function getUserReward(address account) public view returns (uint256) {
		uint256 _sigRwd		= userInfoMap[account].netSigmaRwd;
		return _sigRwd.mul(Rwd).div(netSigmaRwd);
	}

	/**
	 * @notice Get the total amount of money available for a given user.
	 * */
	function getUserAvailable(address account) public view returns (uint256) {
		return add(getUserReward(account), userInfoMap[account].balanceOf);
		}
	}

    /**
	 * @notice Retrieve the user's struct data.
	 * */
	function getUserState(address user) public view returns (uint256[5]) {
		userInfo _user = userInfoMap[user];
		uint256[5] Usr;
		Usr[0] = _user.netSigmaRwd;
		Usr[1] = _user.netSigmaUrwd;
		Usr[2] = _user.balanceOf;
		Usr[3] = _user.chPnt;
		Usr[4] = _user.balanceOfRwd;
		return Usr;
	}

}