pragma solidity 0.4.24;


contract SafeMath {


    function safeAdd(uint a, uint b) public pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns(uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns(uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns(uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract Owner {

    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {

        owner = msg.sender;
        emit OwnershipTransferred( address(0), owner);
    }

    modifier onlyOwner {
        require( msg.sender == owner );
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {

        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}


contract LotteryThree is Owner, SafeMath {

    bool public bIsActive;
    uint256 public lotteryPools;
    uint256 public minBet;
    uint256 public maxBet;
    uint256 public roundNO;
    uint256 public winValue;
    uint256 public lastBlockNumber;
    uint256 public curBlockNumber;

    struct LotteryInfo {
        uint value;
        uint32 lotteryHash;     //select numbers
        uint blockNum;        //blocknumber when buy lottery
    }

    mapping (address => LotteryInfo) public lotteryPlayer;

    // contract state
    struct Wallet {
        uint balance; // current balance of user
        uint lastDividendPeriod; // last processed dividend period of user's tokens
        uint nextWithdrawTime; // next withdrawal possible after this timestamp
    }

    uint public walletBalance = 0;

    mapping (address => Wallet) public wallets;

    event LogBet(address indexed player, uint24 bethash, uint24 hash, uint roundNO, uint betsize, uint indexed prize);
    //event LogLoss(address indexed player, uint24 bethash, uint24 hash);
    //event LogWin(address indexed player, uint24 bethash, uint24 hash, uint prize);

    constructor() public {
        minBet = 0.01 * 1 ether;
        maxBet = 1 * 1 ether;
        roundNO = 0;
        lastBlockNumber = 0;
        bIsActive = true;
    }

    function BuyLottery(uint24 _playerhash) public payable {
        require(_playerhash <= 16777215);   //0xFFFFFF
        require(msg.value >= minBet && msg.value <= maxBet);

        uint256 curHash = uint256(keccak256(msg.sender, roundNO));
        roundNO = safeAdd(roundNO, 1);


        lotteryPlayer[msg.sender] = LotteryInfo({value: msg.value, lotteryHash: uint24(_playerhash), blockNum: roundNO});

        uint winPrize = 0;
        winPrize = betPrize(lotteryPlayer[msg.sender], uint24(curHash));

        lastBlockNumber = curBlockNumber;
        emit LogBet(msg.sender, _playerhash, uint24(curHash), roundNO, msg.value, winPrize);
    }

    function pay(uint _amount) private {
            uint maxpay = safeDiv(address(this).balance, 2);
            if (maxpay >= _amount) {
                msg.sender.transfer(_amount);
        }
        else {
            uint keepbalance = safeAdd(_amount, maxpay);
            walletBalance = safeAdd(walletBalance, keepbalance);
            wallets[msg.sender].balance = safeAdd(wallets[msg.sender].balance,
                keepbalance);
            wallets[msg.sender].nextWithdrawTime = block.timestamp + 60 * 60 * 24 * 30; // wait 1 month for more funds
            msg.sender.transfer(maxpay);
        }
    }

    function payWallet() public {
        if (wallets[msg.sender].balance > 0 && wallets[msg.sender].nextWithdrawTime <= block.timestamp){
            uint balance = wallets[msg.sender].balance;
            wallets[msg.sender].balance = 0;
            walletBalance -= balance;
            pay(balance);
        }
    }

    /* lottery functions */
    function betPrize(LotteryInfo _player, uint24 _hash)   private  pure returns (uint) { // house fee 13.85%
        uint24 bethash = uint24(_player.lotteryHash);
        uint24 hit = bethash ^ _hash;
        uint24 matches =
            ((hit & 0xF) == 0 ? 1 : 0 ) +
            ((hit & 0xF0) == 0 ? 1 : 0 ) +
            ((hit & 0xF00) == 0 ? 1 : 0 ) +
            ((hit & 0xF000) == 0 ? 1 : 0 ) +
            ((hit & 0xF0000) == 0 ? 1 : 0 ) +
            ((hit & 0xF00000) == 0 ? 1 : 0 );
        if (matches == 6) {
            return(safeMul(uint(_player.value), 7000000));
        }
        if (matches == 5) {
            return(safeMul(uint(_player.value), 20000));
        }
        if (matches == 4) {
            return(safeMul(uint(_player.value), 500));
        }
        if (matches == 3) {
            return(safeMul(uint(_player.value), 25));
        }
        if (matches == 2) {
            return(safeMul(uint(_player.value), 3));
        }
        return(0);
    }

    function changeGameState(bool _isActive) public onlyOwner {
        bIsActive = _isActive;
    }

    function ownerWithdrawal() public onlyOwner {
        require(address(this).balance > 0);
        msg.sender.transfer(address(this).balance);
    }
}
