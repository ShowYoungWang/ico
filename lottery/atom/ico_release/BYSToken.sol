pragma solidity 0.4.17;


contract ERC20 {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns
    (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 contract BYSToken is ERC20{
     string public standard = 'http://www.bayesin.io';
     string public name = "Token SnailGame";
     string public symbol = "SGTT";
     uint8 public decimals = 18;
     uint256 public totalSupply = 10000000000 * 10 ** 18;
     address public tokenOwner;
     uint256 public freeCrawDeadline = now + 30 * 10 minutes;
     /* This creates an array with all balances */
     mapping (address => uint256) public balanceOf;
     mapping (address => uint256) public frozenAccountByOwner;
     mapping (address => mapping (address => uint256)) allowed;

     event FrozenAccount(address target, uint256 deadline);

     /*
      * @param _owned
      * @param tokenName
      * @param tokenSymbol
      * @param initSupply
      */
     function BYSToken(address _owned) public{
         tokenOwner = _owned;
         /* name = tokenName;
         symbol = tokenSymbol;
         freeCrawDeadline = now + _freeCrawDeadline * 1 minutes;
         totalSupply = initSupply * 10 ** 18; */
         balanceOf[tokenOwner] = totalSupply;
     }

     modifier afterFrozenDeadline() { if (now >= freeCrawDeadline) _; }

     modifier isOwner
     {
        require(msg.sender == tokenOwner);
        _;
     }

     function managerAccount(address target, uint256 deadline) isOwner public
     {
       frozenAccountByOwner[target] = now + deadline * 1 minutes;
       FrozenAccount(target, deadline);
     }

     /**
      * @param  _to address
      * @param  _value uint256
      */
     function transfer(address _to, uint256 _value) public returns (bool success)
     {
       require(now >= freeCrawDeadline);
       require(_value > 0);
       require(balanceOf[msg.sender] - _value >= 0);
       require(now >= frozenAccountByOwner[msg.sender]);
       balanceOf[msg.sender] -= _value;
       balanceOf[_to] += _value;
       Transfer(msg.sender, _to, _value);

       return true;
     }

     function transferFrom(address _from, address _to, uint256 _value) public returns
     (bool success) {
         require(balanceOf[_from] >= _value && allowed[_from][msg.sender] >= _value);
         balanceOf[_to] += _value;//接收账户增加token数量_value
         balanceOf[_from] -= _value; //支出账户_from减去token数量_value
         allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
         Transfer(_from, _to, _value);//触发转币交易事件
         return true;
     }
     function balanceOf(address _owner) public constant returns (uint256 balance) {
         return balanceOf[_owner];
     }


     function approve(address _spender, uint256 _value) public returns (bool success)
     {
         allowed[msg.sender][_spender] = _value;
         Approval(msg.sender, _spender, _value);
         return true;
     }

     function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
         return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
     }

     /**
      * @param  _to address
      * @param  _amount uint256
      */
     function issue(address _to, uint256 _amount) internal{
         require(_amount > 0);
         require(balanceOf[tokenOwner] - _amount > 0);
         balanceOf[tokenOwner] -= _amount;
         balanceOf[_to] += _amount;
         Transfer(tokenOwner, _to, _amount);
     }
  }

/**
 * 众筹合约
 */
contract CrowdSale is BYSToken {
    address public beneficiary;
    uint public minGoal; //ether
    uint public maxGoal;
    uint public deadline;
    uint public price;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    uint256 public amountRaised; //wei
    uint256 public tokenAmountRasied;

    uint256 public bonus01;
    uint public bonus01Start;
    uint public bonus01End;
    uint256 public bonus02;
    uint public bonus02Start;
    uint public bonus02End;
    uint private bonus = 0;
    mapping(address => uint256) public balance;

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
    /* function Crowdsale(
        address _beneficiary,
        address _tokenOwner,
        uint _minGoal,
        uint _maxGoal,
        uint _durationInMinutes,
        uint _price,
        string _tokenName,
        string _tokenSymbol,
        uint  _bonus01,
        uint  _bonus01Start,
        uint  _bonus01End,
        uint  _bonus02,
        uint  _bonus02Start,
        uint  _bonus02End,
        uint256 _initMount,
        uint256 _freeCrawDeadline
    ) public BYSToken(_tokenOwner, _tokenName, _tokenSymbol, _initMount, _freeCrawDeadline){ */

    function CrowSale(address _owner, address _beneficiary) public BYSToken(_owner){

        /* require(_price != 0);
        require(_bonus01 > 0);
        require(_bonus02 > 0);
        require(_bonus01Start <= _bonus01End);
        require(_bonus02Start <= _bonus02End); */
        beneficiary = _beneficiary;
        /* minGoal = _minGoal * 1 ether;
        maxGoal = _maxGoal * 1 ether;
        deadline = now + _durationInMinutes * 1 minutes;
        price = _price; */
        //(1000/_price) * 1 finney;
        /* bonus01 = _bonus01;
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

        issue(msg.sender, returnTokenAmount);
        FundTransfer(msg.sender, amount, true);
        if(amountRaised >= maxGoal){
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
