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

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ERC20Interface {

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract BYSToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;
    address public tokenOwner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping (address => uint256) public frozenAccountByOwner;

    uint256 public freeCrawDeadline;
    event FrozenAccount(address target, uint256 deadline);
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "BYS";
        name = "Bayesin";
        decimals = 18;
        totalSupply = 2000000000 * 10 ** 18;  //10bil
        tokenOwner = 0x00944A8338D501DBE847C08cfcc655f70b22c13E;
        freeCrawDeadline = 1526313600; //05-10
        //now + 30 * 1 minutes;
        balances[tokenOwner] = totalSupply;
        emit Transfer(address(0), tokenOwner, totalSupply);
    }

    modifier isOwner
    {
        require(msg.sender == tokenOwner);
       _;
    }

    modifier afterFrozenDeadline() { if (now >= freeCrawDeadline) _; }

    function managerAccount(address target, uint256 deadline) public isOwner
    {
        frozenAccountByOwner[target] = deadline;
        emit FrozenAccount(target, deadline);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totalSupply;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenOwner) public constant returns (uint balance) {
        return balances[_tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _tokens) public afterFrozenDeadline returns (bool success) {

        require(now > frozenAccountByOwner[msg.sender]);
        balances[msg.sender] = safeSub(balances[msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address _spender, uint _tokens) public returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint _tokens) public afterFrozenDeadline returns (bool success) {

        require(_tokens > 0);
        require(now > frozenAccountByOwner[_from]);

        balances[_from] = safeSub(balances[_from], _tokens);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        emit Transfer(_from, _to, _tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address _tokenOwner, address _spender) public constant returns (uint remaining) {
        return allowed[_tokenOwner][_spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address _spender, uint _tokens, bytes _data) public returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        /* ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _tokens, this, _data); */
        return true;
    }

    function fundTransfer(address _to, uint256 _amount) internal {
        require(_amount > 0);
        require(balances[tokenOwner] - _amount > 0);
        balances[tokenOwner] = safeSub(balances[tokenOwner], _amount);
        balances[_to] = safeAdd(balances[_to], _amount);
        emit Transfer(tokenOwner, _to, _amount);
    }
}


contract CrowSale is BYSToken {

    address public beneficiary;// = 0x00944A8338D501DBE847C08cfcc655f70b22c13E; //metamask 01
    uint public minGoal = 0; // 0.5 * 1 ether; //ether
    uint public maxGoal = 0; //1 * 1 ether;
    /* uint public deadline = now + 30 * 1 minutes; */
    uint public price = 0;// 1000;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    uint256 public amountRaised = 0; //wei
    uint256 public tokenAmountRasied = 0;

    uint256 public bonus01 = 0; //50;
    uint public bonus01Start = 0; //safeMul(0 * 1 eth);
    uint public bonus01End = 0; //safeMul(2 * 1 eth);
    uint256 public bonus02 = 0; //100;
    uint public bonus02Start = 0; // safeMul(3 * 1 eth);
    uint public bonus02End = 0; //safeMul(5 * 1 eth);
    uint public bonus = 0;
    mapping(address => uint256) public fundBalance;

    /* address tokenOwner; */

    /* Token tokenReward; */

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
    constructor() public {
        beneficiary = 0x1905f5CC82288Ba5b4E39003515dC74357232c18; //metamask 01
        minGoal = 5 * 1 ether; //ether
        maxGoal = 20 * 1 ether;
        /* uint public deadline = now + 30 * 1 minutes; */
        price = 16000;
        fundingGoalReached = false;
        crowdsaleClosed = false;
        amountRaised = 0; //wei
        tokenAmountRasied = 0;

        bonus01 = 40;
        bonus01Start = safeMul(0, 1 ether);
        bonus01End = safeMul(1, 1 ether);
        bonus02 = 20;
        bonus02Start = safeMul(5, 1 ether);
        bonus02End = safeMul(15, 1 ether);

        bonus = 40;


    }

    function () public payable {
        require(!crowdsaleClosed);
        require(msg.sender != tokenOwner);

        if (now > freeCrawDeadline) {
            crowdsaleClosed = true;
            revert();
        }


        uint amount = msg.value;
        fundBalance[msg.sender] = safeAdd(fundBalance[msg.sender], amount);
        amountRaised = safeAdd(amountRaised, amount);
        uint256 returnTokenAmount = safeMul(amount, price);
        returnTokenAmount = safeAdd(returnTokenAmount,
            safeDiv(safeMul(returnTokenAmount, bonus), 100));
        tokenAmountRasied = safeAdd(tokenAmountRasied, returnTokenAmount); //wei

        fundTransfer(msg.sender, returnTokenAmount);
        emit FundTransfer(msg.sender, amount, true);

        if ((amountRaised >= bonus01Start) && (amountRaised < bonus01End)) {
            bonus = bonus01;
        }else if ((amountRaised >= bonus02Start) && (amountRaised < bonus02End)) {
            bonus = bonus02;
        }else {
            bonus = 0;
        }

        if (amountRaised >= minGoal) {
            fundingGoalReached = true;
        }

        if (amountRaised >= maxGoal) {
            fundingGoalReached = true;
            crowdsaleClosed = true;
        }
    }

    modifier afterDeadline() { if ((now >= freeCrawDeadline)  || (amountRaised >= maxGoal)) _; }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= minGoal) {
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = fundBalance[msg.sender];
            if (amount > 0) {
                msg.sender.transfer(amount);
                 emit FundTransfer(msg.sender, amount, false);
                fundBalance[msg.sender] = 0;
            }
        }
        if (fundingGoalReached && beneficiary == msg.sender) {
            beneficiary.transfer(amountRaised);
            emit FundTransfer(beneficiary, amount, false);
        }
    }
}
