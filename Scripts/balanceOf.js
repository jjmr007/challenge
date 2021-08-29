const Web3 = require('web3');

const url = 'https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161';
const web3 = new Web3(url);

var ABI = fs.readFileSync('./Deploy/ABIs/Logic.json', 'utf8');
ABI = JSON.parse(ABI);

var ETHPool = fs.readFileSync('./Deploy/addresses.json', 'utf8');
ETHPool = JSON.parse(ETHPool);
var Proxy = ETHPool.Proxy;

const ETHPoolProxy = new web3.eth.Contract(ABI, Proxy);

// check the url connection
var listen = web3.eth.net.isListening().then(
console.log
);

async function giveBalanceOf() { 
	
	var NetReward = await ETHPoolProxy.methods.Rwd.call().call();
	var NetStaked = await ETHPoolProxy.methods.balanceOf.call().call();
	var NetBalance = NetReward + NetStaked;
	NetReward = web3.utils.fromWei(NetReward, 'ether');
	NetStaked = web3.utils.fromWei(NetStaked, 'ether');
	NetBalance = web3.utils.fromWei(NetBalance, 'ether');
	console.log("\n", "The net balance in ETHPool is " + NetBalance + " ETH," + "\n",
	"The net value in rewards is " + NetReward + " ETH," + "\n",
	"And the total value staked by users is " + NetStaked + " ETH," + "\n",);
      
    });



}

giveBalanceOf();