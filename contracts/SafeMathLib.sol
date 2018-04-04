pragma solidity ^0.4.11;

library SafeMathLib {
  function mul(uint256 a, uint256 b) returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  
  function sub(uint256 a, uint256 b) returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) returns (uint256) {
    uint256 c = a + b;
    require(c>=a && c>=b);
    return c;
  }

}