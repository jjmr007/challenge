# Solution to The Challenge
Let's suppose Alice deposited 1 ETH on Monday the 1st, at midday - for convenience, let's assume that everything happens at midday, UTC time-.  
Then, Bob deposits 3 ETH on Thursday the 4th, at midday. Later, the Team deposit a 2% of weekly dividends on Sunday the 7th at midday. How much the Team should have deposited?  
**One key assumption** here is that the more time a user has staked her/his asset on this pool, the more the weight her/his funds have at the moment of the profit distribution.  

So Alice has staked 1 ETH by 6 days.  
Bob has staked 3 ETH by 3 days.  
If we weight the funds with the duration of staking, we can define a parameter "Sigma" of ETH\*Days: we have thus a net Sigma of 15 ETH*Days.  
So if the Team is going to pay a weekly 2%, then we pay 0.02 ETH for each ETH deposited during 7 days. So we pay 0.02 ETH for each 7 ETH\*Days = 0.01 ETH for each 3.5 ETH\*Days.  

On Sunday the 7th we have at midday 15 ETH\*Days, and thus the team must pay:  
(15 ÷ 3.5) x 0.01 ETH = 0.042857 ETH  
The team should be able to make this deposit and chill, trusting that the protocol will make the proper distribution of these funds.  

In particular, we can trust that the protocol will assign to Alice:  
(6 ÷ 3.5) x 0.01 ETH = 0.017143 ETH  
And to Bob:
(9 ÷ 3.5) x 0.01 ETH = 0.025714 ETH  

Now let's suppose Charles deposit 5 ETH on Wednesday the 10th, at midday. On Sunday the 14th, the Team has determine a 1% of weekly dividend for this week. So they pay 0.01 ETH for each ETH staked by 7 days = 0.01 ETH paid  for each 7 ETH\*Day.  
How much they should deposit now?  

If Alice hasn't move her funds: 1 ETH x 7 days = 7 ETH\*Days  
If Bob hasn't move his funds: 3 ETH x 7 days = 21 ETH\*Days  
And for Charles who has staked 5 ETH during 4 days: 20 ETH\*Days.  
The net Sigma to be rewarded is now: 48 ETH\*Days  
So the Team must pay:  
(48 ÷ 7) x 0.01 ETH = 0.068571 ETH  
How should the protocol distribute these funds?  

If we just weight the Sigma parameters and add them linearly without taking in count the variation of interest rates paid each week we may incur into errors in the rewards assigned to each user.  

To illustrate this we may choose to set the net Sigma parameter at the Sunday the 14th at midday, as:  
**netSigma** = (15 + 48) ETH\*Day = 63 ETH\*Day  
And we have a net reward accumulated of:  
**netRwd** = 0.111428 ETH  

While if we set with the same criteria the Alice's netSigma:  
**Alice.netSigma** = (6 + 7) ETH\*Day = 13 ETH\*Day  
So under this criteria Alice holds:  
**P** = (13 ÷ 63) * 100% = 20.635% of all the accumulated Sigma.  
Let:  
**Alice.netRwd** = **P**x**netRwd** = 0.022993 ETH  
But the actual reward corresponding to Alice is:  
((6÷3.5)+(7÷7))x0.01 ETH = 0.027143 ETH > **Alice.netRwd**  

But let's suppose that we introduce a weight **w** linked to a standard of 100 base points = 1% - indeed we can define our base points with as many decimal positions as we like -.  
So, the week of a 2% of reward, the weight was: **w** = 2  
And the week of a 1% of reward, the weight was: **w** = 1  
So we may redefine the **netSigma** as follows:  
**netSigma** = (15x2 + 48x1) ETH\*Day = 78 ETH\*Day  
And the **Alice.netSigma** as:  
(6x2 + 7x1) ETH\*Day = 19 ETH\*Day  

Now the portion of the netSigma that Alice has is:  
**P** = (19 ÷ 78) * 100% = 24.359%  
And now:  
**Alice.netRwd** = **P**x**netRwd** = 0.027143 ETH  
Which is the expected value. So we can assume this as a fair criteria for profit distribution. 

## The Need of Check-Points

If a user stop visiting the platform of ETHPool, she/he may face the need to update the netSigma increment for several weeks.  
To solve this need, we need a mapping:  
**mapping(uint => uint)** where we assign unix-time epoch numbers to weights;  
So **w[t]** is the weight corresponding to the reward deposited at the time **t**.  
And to find every point in time in which a reward was paid, we need another mapping:  
**mapping(uint => uint)** where we assign integers N to unix-time epochs.  
So **t[N]** is the time epoch corresponding to the week number **N**.  
We define this way a Check-Point.  

## The Functions For The Main Logic

### The User's Deposit

A payable public function called `deposit()` will stake `msg.value` ETH on ETHPool.  
The procedure of this function will be:  

i.- The function calls the internal method `_globalUpdate(uint256 _amnt, uint256 _time, bool _pay)`, with `_pay` set as `true`. It will update the storage parameters of the contract:  
&nbsp;&nbsp;\* **netSigmaRwd**: The net Sigma value under reward.  
&nbsp;&nbsp;\* **netSigmaUrwd**: The net Sigma value NOT under reward.  
&nbsp;&nbsp;\* **Rwd**: Total funds deposited as reward in the contract.  
&nbsp;&nbsp;\* **balanceOf**: Total funds deposited by users in the contract.  
&nbsp;&nbsp;\* **lastChkPointCount**: The last week-number recorded in which a reward payment should have occur.  

ii.- Then the function will call the internal method `_updateUser(address _user, uint _time)` which will update the `msg.sender` data. This data is stored in a mapping called `userInfoMap`: **mapping(address => userInfo)**, where **userInfo** is a struct.  

iii.- The function calls the internal method `_deposit(address _user, uint256 _amnt)` where the new state of the user will be applied. This step will change the new deposited values of the user.

### The User's Withdraw

A public function called `withdraw(uint256 amnt)` will unstake a corresponding proportion of funds deposited by the user, plus the correspondent rewards. This function will use a non-reentrancy safety device, using the proper modifier. 

i.- The function call the internal method `_globalUpdate(uint _amnt, unit _time, bool _pay)`, as mentioned before but with `_pay` set as `false`, and `_amnt` set as zero.   

ii.- Then the function will call the internal method `_updateUser(address _user, uint _time)` which will update the data of the `_user`, as mentioned before.  

iii.- The function will check if the withdraw is valid using the internal method `_checkLess(address _user, uint256 _amnt)`. This method will include all the logics to verify that the amount to be withdrawn is below the available funds of the user. The method returns a uint256 parameter indicating the amount of reward to be removed (_less), another uint256 parameter indicating how much reward has the userand (_rwd) ans a bool parameter as result of the verification (_enough).  

iv.- Finnally the function calls the internal method `_withdraw(address receiver, address _user, uint amnt, uint _rwd, uint _less)` with parameters of the amount to be withdrawn (amnt), the total reward belonging to the user (_rwd) and the amount of reward to be withdrawn (_less).  

### The Deposit of Rewards

A payable public function called `award()` can only be executed by the Team of the ETHPool using the proper modifier. This function will set the rewards for the last week, and will set a new check-point and weight in the corresponding maps.  

i.- The function will calls the internal method `_globalUpdate(uint _amnt, bool _pay)`, as mentioned before but with the parameter `_amnt` set to zero.  

ii.- Then the function will call the internal method `_award(uint rwd)` which will set the storage parameters in a special way.  

## The **userInfo** Struct

The mapping **`userInfoMap`** will assign `(address => userInfo)`, where `userInfo` is a struct with the following parameters:  

&nbsp;&nbsp;\* **netSigmaRwd**: The user's net Sigma value under reward.  
&nbsp;&nbsp;\* **netSigmaUrwd**: The user's net Sigma value NOT under reward.  
&nbsp;&nbsp;\* **balanceOf**: Total funds deposited by the user in the ETHPool.  
&nbsp;&nbsp;\* **chPnt**: The last user's check-point as unix epoch format.  
&nbsp;&nbsp;\* **balanceOfRwd**: The user's funds that has already a reward associated to claim.  

## Special Internal Functions

ETHPool logic will need the following internal processes:

### **_globalUpdate(uint256 _amnt, bool _pay)**

In any transaction in which funds are added or removed, the main storage variables must be updated.  

Every week on Sunday - from 0:00:00 hours until 23:59:59 on Sunday - the Team is allowed to deposit rewards. This condition is checked by the **`onAwardTime()`** modifier.  

But if within the award time this reward is not paid, it will be nessesary to make the register in the `weeksTime` and `weights` mappings, creating a sequence of counts for `weeksTime` assigned to the noon of all the Sundays when payments weren't done, this automatically assigns uint256(0) - zero - to these values in the mapping `weight`:  
`weight[weeksTime[N]] = 0`, by default.  
This can be done by another internal method:  
**`_padding()`**  
Its logic will include the following:  
If there is more than 7 days from the value `weeksTime[lastChkPointCoun]` and `block.timestamp`, which can be verified by the internal method  
**`_compare()`**  
then a `for` loop will be executed padding with timestamp values the `weeksTime[N]` from `N = lastChkPointCount + 1` to the highest possible value of this last checkpoint count.  

Finally an internal method,  
**`_update(uint256 _a, bool _p)`**  
is done before any change is done in the amount of funds of the contract. This method will use several of the methods described in the next internal function.

### **_updateUser(address _user, uint256 _timeStamp)**

The first step is to execute the internal method  
**`_compare(uint256 _now, uint256 _then)`**  
which will obtain the distance between the `block.timestamp` and the `userInfoMap[msg.sender].lastChkPoint`. It will return the number of weeks rounded down.  
Another internal function  
**`_findPoint(uint weeks)`**  
will query the map `weeksTime` and the storage parameter: `lastChkPointCount` to find the week-number in which the last user update was made.  

**If the user hasn't made any move by more than a week**  

Then another internal function is called:  
**`_severalUpdates(address _user, uint256 _farthestPoint)`**  
which will execute a `for` loop to make updates from the point in time found to the present.  
Inside this `for` loop the internal method  
**`_singleUpdate(address _user, uint256 _checkPointTime)`**  
is executed for each step, from the `_farthestPoint` of the user to the `lastChkPointCount` recorded in the storage. Each one of these steps takes `userData.lastChkPoint` and compares with `weeksTime[_weekNumber]` to update the `userData.netSigmaRwd` value taking in count the value of `weights[weeksTime[_weekNumber]]`, then `userData.lastChkPoint` is updated with the value of `weeksTime[_weekNumber]`, then we go to the next step increasing: `_weekNumber + 1`.  

**If the number of weeks is less or equal to one**  
Under this condition we must check that `_checkPointTime == weeksTime[lastChkPointCount]`. Then this will be the unique execution of the internal method `_singleUpdate(_user, _checkPointTime)`.  
Then we can only have one last case:  
**_The value_** of `userInfoMap[_user].lastChkPoint` **_must_** now be greater than or equal to `weeksTime[lastChkPointCount]` and we execute a  
**`_rollOver(userInfo _userData, uint256 _timeStamp)`**  
internal method, in which a new portion of the sigma gathered is integrated within the NOT rewardable domain, and the user data is stored in the userInfoMap with the updated point in time.  

### **_deposit(address _user, uint256 _amnt)**

This function will register the new amount of ETH deposited by the user to the pool.

### **_checkLess(address _user, uint256 _amnt)**

The purpose of this function is verify that the amount to be withdrawn is equal or less than the total available for the user.  

### **_withdraw(address receiver, address _user, uint amnt, uint _rwd, uint _less)**  

This logic will apply the right distribution for removing the funds assigned or not for rewards and the rewards of the user, in their proportion, and depending the amount to be withdrawn.

If the amount to be withdrawn is lower than the net user's reward plus the user's balanceOfRwd, then a proper distribution is done according the ratio between rewards an deposit to be rewarded. If is larger, all this funds are withdrawn along with the non-yet-rewardable funds.

### **_award(uint256 _rwd, uint256 _time)**  

This function can only be done by the team. It will assign rewards to the contract and execute the changes in the storage to report this payments.

## Events

* **Deposit**: for each user's deposit.
* **ETHWithdrawn**: for each time funds are removed.
* **RewardPaid**: for each reward deposit.

## Getters

* **getUserReward**:    Get the current reward balance of a user's account.
* **getUserAvailable**: Get the total amount of money available for a given user.
* **getUserState**:     Retrieve the user's struct data.

