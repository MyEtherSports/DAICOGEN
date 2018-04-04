pragma solidity ^0.4.4;

import './SafeMathLib.sol';

library ERC20Lib {
  using SafeMathLib for uint256;

  struct TokenData {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 totalSupply;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function init(TokenData storage self, uint256 _initial_supply, address _owner) {
    self.totalSupply = _initial_supply;
    self.balances[_owner] = _initial_supply;
  }

  function transfer(TokenData storage self, address _to, uint256 _value) returns (bool success) {
    self.balances[msg.sender] = self.balances[msg.sender].sub(_value);
    self.balances[_to] = self.balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(TokenData storage self, address _from, address _to, uint256 _value) returns (bool success) {
    var _allowance = self.allowed[_from][msg.sender];

    self.balances[_to] = self.balances[_to].add(_value);
    self.balances[_from] = self.balances[_from].sub(_value);
    self.allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(TokenData storage self, address _owner) constant returns (uint256 balance) {
    return self.balances[_owner];
  }

  function approve(TokenData storage self, address _spender, uint256 _value) returns (bool success) {
    self.allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(TokenData storage self, address _owner, address _spender) constant returns (uint256 remaining) {
    return self.allowed[_owner][_spender];
  }
  
  //Used by the token contract library, since msg.sender will be preserved in the context.
  function _move_tokens(TokenData storage self, address _from, address _to, uint256 _amount) {
    require(self.balances[_from] >= _amount);
    self.balances[_from] = self.balances[_from].sub(_amount);
    self.balances[_to] = self.balances[_to].add(_amount);
  }
}