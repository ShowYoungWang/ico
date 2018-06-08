pragma solidity 0.4.19;


contract BuyLottery {

    //存储购买彩票信息的结构体
    struct LotteryInfo {
        address buyerAddress;
        uint256[] lotteryNum;
        uint buyLotteryDate;
    }

    address public owner;//合约拥有者
    mapping (string => LotteryInfo) buyInfo;

    event BuySuccessful(string inquireKeyWord, address _buyerAddr, uint256[] _chosenLottery, uint buyLotteryDate);

    //构造函数
    function BuyLottery () {

        owner = msg.sender;
    }

    modifier onleOwner () {
        if (msg.sender != owner) revert();
        _;
    }

    function changeOwner (address _to) internal onleOwner {
        owner = _to;
    }
    //随机生成需要购买的彩票号码
    function randomBuyLotteryAction(address _buyerAddr) returns (string) {

        uint currentTmp = now;
        string memory addrStr;
        string memory buyerStr;
        uint256[] memory resultsArr = new uint256[](7);

        //调用方法toAsciiString()、appendUintToString()进行类型转换并拼接
        addrStr = toAsciiString(_buyerAddr);
        buyerStr = appendUintToString(addrStr, currentTmp);

        //生成随机号码
        for (uint256 i = 0; i < 7; i++) {

            resultsArr[i] = uint256(block.blockhash(block.number-1))%(33-i) + 1;

            if (i == 6) {
                resultsArr[i] = uint256(block.blockhash(block.number-1))%16 + 1;
            }
        }
        //赋值
        buyInfo[buyerStr].buyerAddress = _buyerAddr;
        buyInfo[buyerStr].lotteryNum = resultsArr;
        buyInfo[buyerStr].buyLotteryDate = currentTmp;

        BuySuccessful(buyerStr, _buyerAddr, resultsArr, currentTmp);

        return buyerStr;
    }
    //自主选择需要购买的彩票号码
    function chosenBuyLotteryAction(address _buyerAddr, uint256[] _chosenNum) returns (string){

        uint currentTmp = now;
        string memory addrStr;
        string memory buyerStr;

        //调用方法toAsciiString()、appendUintToString()进行类型转换并拼接
        addrStr = toAsciiString(_buyerAddr);
        buyerStr = appendUintToString(addrStr, currentTmp);

        //赋值
        buyInfo[buyerStr].buyerAddress = _buyerAddr;
        buyInfo[buyerStr].lotteryNum = _chosenNum;
        buyInfo[buyerStr].buyLotteryDate = currentTmp;

        BuySuccessful(buyerStr, _buyerAddr, _chosenNum, currentTmp);

        return buyerStr;
    }

    //查询购买的彩票信息
    function getLotterInfo(string _buyerStr) returns (address, uint256[], uint256){

        return (buyInfo[_buyerStr].buyerAddress, buyInfo[_buyerStr].lotteryNum, buyInfo[_buyerStr].buyLotteryDate);
    }

    //地址转换成字符串
    function toAsciiString(address x) internal returns (string) {

        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = toChar(hi);
            s[2*i+1] = toChar(lo);
        }
        return string(s);
    }
    function toChar(byte b) internal returns (byte c) {

        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    //地址字符串和时间戳的拼接
    function appendUintToString(string inStr, uint tmp) internal returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (tmp != 0) {
            uint remainder = tmp % 10;
            tmp = tmp / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i + 1);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }

        for (j = 0; j <= i; j++) {
            s[j + inStrb.length] = reversed[i - j];
        }
        str = string(s);
    }
}
