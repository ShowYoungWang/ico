pragma solidity 0.4.23;


contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
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


contract LotteryOne is Owner, SafeMath {

    bool public isActive;
    uint8 public gameClass;
    uint256 public lotteryPool;
    uint256 public minBet;
    uint256 public maxBet;
    uint256 public roundNO;



    mapping (uint256 => address) public playerAddress;
    mapping (uint256 => uint) public playerBetValue;
    mapping (uint256 => uint8) public gameNumberOne;
    mapping (uint256 => uint8) public gameNumberTwo;
    mapping (uint256 => uint8) public gameNumberThree;
    mapping (uint256 => uint256) public playerWinValue;
    mapping(uint8 => uint8) public winRate;
    /////////////////////////////////////////

    modifier isGameActive {
        require(isActive == true);
        _;
    }

    event LogLotteryEvent(uint256 indexed _roundNo, address indexed _player,
        bool indexed _isWin, uint256 _betValue,
        uint8 _one, uint8 _two, uint8 _three, uint256  _winValue);

    constructor() public {
        minBet = 0.01 * 1 ether;
        maxBet = 1 ether;
        lotteryPool = 0;
        isActive = true;
        owner = msg.sender;
        roundNO = 0;
        gameClass = 8;

        //init win rate
        winRate[0] = 3;
        winRate[1] = 4;
        winRate[2] = 5;
        winRate[3] = 6;
        winRate[4] = 10;
        winRate[5] = 20;
        winRate[6] = 30;
        winRate[7] = 100;
    }

    function () public payable {
        lotteryPool = safeAdd(lotteryPool, msg.value);
    }

    function buyLottery() public payable isGameActive {
        require(msg.value >= minBet && msg.value <= maxBet);

        roundNO = safeAdd(roundNO, 1);
        uint256 tmpRandom01 = uint256(keccak256(roundNO, block.timestamp, msg.sender)) % gameClass;
        uint256 tmpRandom02 = uint256(keccak256(safeAdd(roundNO, 100), block.timestamp, msg.sender)) % gameClass;
        uint256 tmpRandom03 = uint256(keccak256(safeAdd(roundNO, 200), block.timestamp, msg.sender)) % gameClass;

        playerAddress[roundNO] = msg.sender;
        playerBetValue[roundNO] = msg.value;
        gameNumberOne[roundNO] = uint8(tmpRandom01);
        gameNumberTwo[roundNO] = uint8(tmpRandom02);
        gameNumberThree[roundNO] = uint8(tmpRandom03);
        // check win
        bool bWinState = false;
        uint256 lotteryWin = 0;
        lotteryPool = safeAdd(lotteryPool, msg.value);

        if (gameNumberOne[roundNO] == gameNumberTwo[roundNO]
            && gameNumberOne[roundNO] == gameNumberThree[roundNO]) {
            //win
            uint8 priceRate = winRate[gameNumberOne[roundNO]];
            if (priceRate <= 1) {
                priceRate = 1;
            }

            lotteryWin = safeMul(msg.value, priceRate);
            playerWinValue[roundNO] = lotteryWin;
            require(lotteryPool >= lotteryWin);
            lotteryPool = safeSub(lotteryPool, lotteryWin);
            msg.sender.transfer(lotteryWin);

            bWinState = true;
        }

        //log
        emit LogLotteryEvent(roundNO, msg.sender, bWinState, msg.value,
            gameNumberOne[roundNO], gameNumberTwo[roundNO],
            gameNumberThree[roundNO], lotteryWin);
    }

    function changeGameState(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function ownerWithdrawal() public onlyOwner {
        msg.sender.transfer(lotteryPool);
        lotteryPool = 0;
    }
}
