# Solution to The Challenge
Let's suppose Alice deposited 1 ETH on Monday the 1st, at midday - for convenience, let's assume that everything happens at midday-.  
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
The net Sigma is now: 48 ETH\*Days  
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

But let suppose that we introduce a weight **w** linked to a standard of 100 base points = 1% - indeed we can define our base points with as many decimal positions as we like -.  
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

i.- The function will call the internal method `_updateUser()` which will update the `msg.sender` data. This data is stored in a mapping called `userinfoMap`: **mapping(address => userInfo)**, where **userInfo** is a struct.  

ii.- Then the function call the internal method `_globalUpdate(uint amnt, bool deposit)`, with `deposit` set as `true`. It will update the storage parameters of the contract:  
&nbsp;&nbsp;\* **NetSigmaRwd**: The net Sigma value under reward.  
&nbsp;&nbsp;\* **NetSigmaUrwd**: The net Sigma value NOT under reward.  
&nbsp;&nbsp;\* **Rwd**: Total funds deposited as reward in the contract.  
&nbsp;&nbsp;\* **balanceOf**: Total funds deposited by usres in the contract.  
&nbsp;&nbsp;\* **ChPnt**: The last global check-point as unix epoch format.    

iii.- The function calls the internal method `_deposit(uint amnt)` where the new state of the user will be applied. This step will change the new deposited values of the user.

### The User's Withdraw

A public function called `withdraw(uint amnt)` will unstake a corresponding proportion of funds deposited by the user, plus the correspondent rewards. This function will use a non-reentrancy safety device, using the proper modifier. 

i.- The function will call the internal method `_updateUser()` which will update the `msg.sender` data, as mentioned before.  

ii.- Then the function call the internal method `_globalUpdate(uint amnt, bool deposit)`, as mentioned before but with `deposit` set as `false`.  

iii.- The function will check if the withdraw is valid using the internal method `_checkLess`. This method will include all the logics to verify that the amount to be withdrawn is below the available funds of the user.  

iv.- Finnally the function calls the internal method `_withdraw(uint amnt, uint _rwd, uint _less)` with parameters of the amount to be withdrawn (amnt), the total reward belonging to the user (_rwd) and the amount of reward to be withdrawn (_less) - not to be confused with the amount of user's net deposit to be withdrawn.  

### The Deposit of Rewards

A payable public function called `award(uint amnt)` can only be executed by the Team of the ETHPool using the proper modifier. This function will set the rewards for the last week, and will set a new check-pont and weight in the corresponding maps.  

i.- The function will calls the internal method `_globalUpdate(uint amnt, bool deposit)`, as mentioned before but with the parameter `amnt` set to zero.  

ii.- Then the function will call the internal method `_award(uint rwd)` which will set the storage parameters in a special way.  

