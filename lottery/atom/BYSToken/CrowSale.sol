pragma solidity 0.4.19;


interface Token {
    function transfer(address _to, uint _value) public;
}

contract CrowSale{
    address public beneficiary = 0xd255781054fca52369a0018e34020b2f2c00bacf; //metamask 01
    uint public minGoal = 10; //ether
    uint public maxGoal = 5;
    uint public deadline = now + 30 * 1 minutes;
    uint public price = 1000;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    uint256 public amountRaised = 0; //wei
    uint256 public tokenAmountRasied = 0;

    uint256 public bonus01 = 50;
    uint public bonus01Start = 0;
    uint public bonus01End = 5;
    uint256 public bonus02 = 100;
    uint public bonus02Start = 5;
    uint public bonus02End = 10;
    uint private bonus = 0;
    mapping(address => uint256) public balance;

    address tokenOwner;

    Token tokenReward;

    event GoalReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);
    // *
    // * @param _minGoal
    // * @param _maxGoal
    // * @param _durationInMinutes
    // * @param _tokenName
    // * @param _tokenSymbol
    // * @param uint  _bonus01
    // * @param uint  _bonus01Start
    // * @param uint  _bonus01End
    // * @param uint  _bonus02;
    // * @param uint  _bonus02Start
    // * @param uint  _bonus02End
    // * @param uint256 _crawMount
    function CrowSale() public {
        tokenReward = Token(0x68d88B66bd644c54854A2e6caad75a760f53747B);
        tokenOwner = address(0x00944A8338D501DBE847C08cfcc655f70b22c13E);
        /* require(_price != 0);
        require(_bonus01 > 0);
        require(_bonus02 > 0);
        require(_bonus01Start <= _bonus01End);
        require(_bonus02Start <= _bonus02End);
        beneficiary = _beneficiary;
        minGoal = _minGoal * 1 ether;
        maxGoal = _maxGoal * 1 ether;
        deadline = now + _durationInMinutes * 1 minutes;
        price = _price;
        //(1000/_price) * 1 finney;
        bonus01 = _bonus01;
        bonus01Start = _bonus01Start;
        bonus01End = _bonus01End;

        bonus02 = _bonus02;
        bonus02Start = _bonus02Start;
        bonus02End = _bonus02End;
        bonus = 0; */

    }

    function () payable public {
        require(!crowdsaleClosed);
        if((amountRaised >= bonus01Start * 1 ether) && (amountRaised < bonus01End * 1 ether))
        {
            bonus = bonus01;
        }
        else if ((amountRaised >= bonus02Start * 1 ether) && (amountRaised < bonus02End * 1 ether))
        {
            bonus = bonus02;
        }
        else
        {
          bonus = 0;
        }
        uint amount = msg.value;
        balance[msg.sender] += amount;
        amountRaised += amount;
        uint256 returnTokenAmount = (amount * price);
        returnTokenAmount += returnTokenAmount * bonus / 100;
        tokenAmountRasied += returnTokenAmount; //wei

        tokenReward.transfer(msg.sender, returnTokenAmount);
        //issue(msg.sender, returnTokenAmount);
        FundTransfer(msg.sender, amount, true);
        if (amountRaised >= maxGoal) {
            fundingGoalReached = true;
            crowdsaleClosed = true;
        }
    }

    modifier afterDeadline() { if (now >= deadline  || amountRaised >= maxGoal) _; }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= minGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    function safeWithdrawal() afterDeadline public {
        if (!fundingGoalReached) {
            uint amount = balance[msg.sender];
            if (amount > 0) {
                msg.sender.transfer(amount);
                FundTransfer(msg.sender, amount, false);
                balance[msg.sender] = 0;
            }
        }
        if (fundingGoalReached && beneficiary == msg.sender) {
            beneficiary.transfer(amountRaised);
            FundTransfer(beneficiary, amount, false);
        }
    }
}
