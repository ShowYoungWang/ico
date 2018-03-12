pragma solidity ^0.4.18;

/**
 * 一个简单的代币合约。
 */
 contract token {

     string public standard = 'https://mshk.top';
     string public name; //代币名称
     string public symbol; //代币符号比如'$'
     uint8 public decimals = 2;  //代币单位，展示的小数点后面多少个0,和以太币一样后面是是18个0
     uint256 public totalSupply; //代币总量
     /* This creates an array with all balances */
     mapping (address => uint256) public balanceOf;

     event Transfer(address indexed from, address indexed to, uint256 value);  //转帐通知事件


     /* 初始化合约，并且把初始的所有代币都给这合约的创建者
      * @param _owned 合约的管理者
      * @param tokenName 代币名称
      * @param tokenSymbol 代币符号
      * @param initSupply
      */
     function token(address _owned, string tokenName, string tokenSymbol, uint256 initSupply) public{
         totalSupply = initSupply * 10 ** uint256(decimals);
         //合约的管理者获得的代币总量
         balanceOf[_owned] = totalSupply;

         name = tokenName;
         symbol = tokenSymbol;

     }

     /**
      * 转帐，具体可以根据自己的需求来实现
      * @param  _to address 接受代币的地址
      * @param  _value uint256 接受代币的数量
      */
     function transfer(address _to, uint256 _value) public{
       //从发送者减掉发送额
       balanceOf[msg.sender] -= _value;

       //给接收者加上相同的量
       balanceOf[_to] += _value;

       //通知任何监听该交易的客户端
       Transfer(msg.sender, _to, _value);
     }

     /**
      * 增加代币，并将代币发送给捐赠新用户
      * @param  _to address 接受代币的地址
      * @param  _amount uint256 接受代币的数量
      */
     function issue(address _to, uint256 _amount) public{
         totalSupply = totalSupply + _amount;
         balanceOf[_to] += _amount;

         //通知任何监听该交易的客户端
         Transfer(this, _to, _amount);
     }
  }

/**
 * 众筹合约
 */
contract Crowdsale is token {
    address public beneficiary; //受益人地址 //测试时为合约创建者 = msg.sender
    uint public minGoal; //最小众筹目标，单位是ether
    uint public maxGoal; //最大众筹目标
    uint public amountRaised; //已筹集金额数量， 单位是wei
    uint public deadline; //截止时间
    uint public price;  //代币价格
    bool public fundingGoalReached = false;  //达成众筹目标
    bool public crowdsaleClosed = false; //众筹关闭

    uint256 public bouns01;
    uint public bouns01Start;
    uint public bouns01End;
    uint256 public bouns02;
    uint public bouns02Start;
    uint public bouns02End;

    enum EnumBounsType {bounsType0, bounsType01, bounsType02}
    EnumBounsType bounstype = EnumBounsType.bounsType0;

    mapping(address => uint256) public balance; //保存众筹地址

    //记录已接收的ether通知
    event GoalReached(address _beneficiary, uint _amountRaised);

    //转帐通知
    event FundTransfer(address _backer, uint _amount, bool _isContribution);


    // * 初始化构造函数
    // * @param _minGoal 众筹以太币最小数量
    // * @param _maxGoal 众筹以太币最大数量
    // * @param _durationInMinutes 众筹截止,单位是分钟
    // * @param _tokenName 代币名称
    // * @param _tokenSymbol 代币符号
    // * @param uint  _bouns01; 额外收益
    // * @param uint  _bouns01Start;额外收益开始数量
    // * @param uint  _bouns01End;额外收益结束数量
    // * @param uint  _bouns02; 额外收益
    // * @param uint  _bouns02Start;额外收益开始数量
    // * @param uint  _bouns02End;额外收益结束数量
    function Crowdsale(
        address _beneficiary,
        uint _minGoal,
        uint _maxGoal,
        uint _durationInMinutes,
        uint _price,
        string _tokenName,
        string _tokenSymbol,
        uint  _bouns01,
        uint  _bouns01Start,
        uint  _bouns01End,
        uint  _bouns02,
        uint  _bouns02Start,
        uint  _bouns02End,
        uint256 _initSupply
    ) public token(this, _tokenName, _tokenSymbol, _initSupply){

        require(_price != 0);
        require(_bouns01 > 0);
        require(_bouns02 > 0);
        beneficiary = _beneficiary;
        minGoal = _minGoal * 1 ether;
        maxGoal = _maxGoal * 1 ether;
        deadline = now + _durationInMinutes * 1 minutes;
        price = (1000/_price) * 1 finney;
        bouns01 = _bouns01;
        bouns01Start = _bouns01Start;
        bouns01End = _bouns01End;
        
        bouns02 = _bouns02;
        bouns02Start = _bouns02Start;
        bouns02End = _bouns02End;
    }


    /**
     * 默认函数
     *
     * 默认函数，可以向合约直接打款
     */
    function () payable public {

        //判断是否关闭众筹
        require(!crowdsaleClosed);

        if(amountRaised >= bouns01Start && amountRaised < bouns01End)
        {
            bounstype = EnumBounsType.bounsType01;
        }
        else if (amountRaised >= bouns02Start && amountRaised < bouns02End)
        {
            bounstype = EnumBounsType.bounsType02;
        }
        else
        {
            bounstype = EnumBounsType.bounsType0;
        }

        uint amount = msg.value;

        //捐款人的金额累加
        balance[msg.sender] += amount;

        //捐款总额累加
        amountRaised += amount;

        uint256 returnTokenAmount = getRetTokenMount( uint256 (amount), bounstype);
        //转帐操作，转多少代币给捐款人
        issue(msg.sender, returnTokenAmount);
        FundTransfer(msg.sender, amount, true);
        
        if(amountRaised >= maxGoal){
            fundingGoalReached = true;
            crowdsaleClosed = true;
        }
    }


    /*
     *获取返还代币数量
     */
    function getRetTokenMount(uint256 _ethamount, EnumBounsType _bounsType) internal returns (uint256){
        require(_ethamount > 0);
        uint256 bouns = 0;
        if(_bounsType == EnumBounsType.bounsType01){
            bouns = bouns01;
        }
        else if(_bounsType == EnumBounsType.bounsType02){
            bouns = bouns02;
        }
        return ((_ethamount / price * 10 ** uint256(decimals)) * (1 + bouns / 100));
    }

    /**
     * 判断是否已经过了众筹截止限期
     */
    modifier afterDeadline() { if (now >= deadline  || amountRaised >= maxGoal) _; }

    /**
     * 检测众筹目标是否已经达到
     */
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= minGoal){
            //达成众筹目标
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }

        //关闭众筹
        crowdsaleClosed = true;
    }


    /**
     * 收回资金
     *
     * 检查是否达到了目标或时间限制，如果有，并且达到了资金目标，
     * 将全部金额发送给受益人。如果没有达到目标，每个贡献者都可以退出
     * 他们贡献的金额
     */
    function safeWithdrawal() afterDeadline public {

        //如果没有达成众筹目标
        if (!fundingGoalReached) {
            //获取合约调用者已捐款余额
            uint amount = balance[msg.sender];

            if (amount > 0) {
                //返回合约发起者所有余额
                msg.sender.transfer(amount);
                FundTransfer(msg.sender, amount, false);
                balance[msg.sender] = 0;
            }
        }

        //如果达成众筹目标，并且合约调用者是受益人
        if (fundingGoalReached && beneficiary == msg.sender) {

            //将所有捐款从合约中给受益人
            beneficiary.transfer(amountRaised);

            FundTransfer(beneficiary, amount, false);
        }
    }
}
