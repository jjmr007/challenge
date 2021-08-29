const Web3 = require('web3');

const url = 'https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161';
const web3 = new Web3(url);

var ABI = fs.readFileSync('./Deploy/ABIs/Logic.json', 'utf8');
ABI = JSON.parse(ABI);
var USER = fs.readFileSync('./user.json', 'utf8');
USER = JSON.parse(USER);
var user = USER.addrs;

var ETHPool = fs.readFileSync('./Deploy/addresses.json', 'utf8');
ETHPool = JSON.parse(ETHPool);
var Proxy = ETHPool.Proxy;

const ETHPoolProxy = new web3.eth.Contract(ABI, Proxy);

// check the url connection
var listen = web3.eth.net.isListening().then(
console.log
);

async function userState() { 
	
	var values[5] = await ETHPoolProxy.methods.getUserState(user).call();
    var available = await ETHPoolProxy.methods.getUserAvailable(user).call();
    var reward = await ETHPoolProxy.methods.getUserReward(user).call();
	console.log("\n", "The state parameters for the user " + user + " are:" + "\n",
	"Rewardable WEIs*seconds: " + values[0] + "\n",
	"Not Rewardable WEIs*seconds: " + values[1] + "\n",
    "Total staked in WEIs: " + values[2] + "\n",
    "Rewardable stake in WEIs: " + values[4] + "\n",
    "Total available in WEIs: " + available + "\n",
    "Rewardable WEIs*seconds: " + reward + "\n",
    "Last check point of time in unix epoc: " + values[3] + " ETH," + "\n",);
      
    });



}

userState();