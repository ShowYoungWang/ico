pragma solidity 0.4.23;


contract SafeMath {


    function safeAdd(uint a, uint b) public pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns(uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract Owner {

    address public owner;
    event OwnershipTransferred(address indexed _form, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {

        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}


contract LotteryTwo is Owner, SafeMath {

    bool public isActive;
    uint256 public lotteryPool;
    uint256 public minBet;
    uint256 public maxBet;
    uint256 public roundNO;
    uint256 public gameClass;
    uint256 public winNo;



    mapping (uint256 => address) public playerAddress;
    mapping (uint256 => uint) public playerBetValue;
    mapping (uint256 => uint8) public gameNumberOne;
    mapping (uint256 => uint256) public playerWinValue;
    mapping (uint256 => uint8) public playerBuyNo;
    /////////////////////////////////////////

    modifier isGameActive {
        require(isActive == true);
        _;
    }

    event LogLotteryEvent(uint256 _roundNo, uint8 _randomNo, uint8 _playerNo,
        address indexed _player, uint256 indexed _betValue, uint256 indexed _winValue);

    constructor() public {
        minBet = 0.01 * 1 ether;
        maxBet = 1 ether;
        lotteryPool = 0;
        isActive = true;
        owner = msg.sender;
        roundNO = 0;
        gameClass = 36;
        winNo = 0;
    }

    function () public payable {
        lotteryPool = safeAdd(msg.value, lotteryPool);
    }

    function buyLottery(uint8 buyNo) public payable isGameActive {
        require(msg.value >= minBet && msg.value <= maxBet);

        roundNO = safeAdd(roundNO, 1);
        uint256 tmpRandom = uint256(keccak256(roundNO, block.timestamp, msg.sender)) % gameClass;
        playerAddress[roundNO] = msg.sender;
        playerBetValue[roundNO] = msg.value;
        gameNumberOne[roundNO] = uint8(tmpRandom);
        playerBuyNo[roundNO] = buyNo;
        // check win
        uint256 lotteryWin = 0;
        lotteryPool = safeAdd(lotteryPool, msg.value);

        if (gameNumberOne[roundNO] == buyNo) {
            //win
            lotteryWin = safeMul(msg.value, 20);
            //playerWinValue[roundNO] = lotteryWin;
            require(lotteryPool >= lotteryWin);
            lotteryPool = safeSub(lotteryPool, lotteryWin);
            msg.sender.transfer(lotteryWin);
        }

        //log
        emit LogLotteryEvent(roundNO, gameNumberOne[roundNO],
            playerBuyNo[roundNO], msg.sender, playerBetValue[roundNO],
            lotteryWin);
    }

    function changeGameState(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function ownerWithdrawal() public onlyOwner {
        msg.sender.transfer(lotteryPool);
        lotteryPool = 0;
    }
}
