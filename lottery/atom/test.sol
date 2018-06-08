pragma solidity ^0.4.18;

contract MetaCoin {
    mapping (address => uint) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function MetaCoin() public  {
        balances[tx.origin] = 10000;
    }
    function AddBalance(address _addr, uint _amount) public returns (bool result){
      require(_amount > 0);
      balances[_addr] += _amount;

      return true;
    }

    function sendCoin(address receiver, uint amount) public  returns(bool sufficient) {
        if (balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function getBalance(address addr) public view returns(uint) {
        return balances[addr];
    }
}
