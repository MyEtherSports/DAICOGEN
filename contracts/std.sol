pragma solidity ^0.4.11;

contract util {
  
  int256 constant INT256_MIN = int256((uint256(1) << 255));
  int256 constant INT256_MAX = int256(~((uint256(1) << 255)));
  uint256 constant UINT256_MIN = 0;
  uint256 constant UINT256_MAX = uint256(int256(-1));

  struct Division {
    uint numerator;
    uint denominator;
  }

  function max(uint a, uint b) internal constant returns (uint) {
      return (a>b)?a:b;
  }
  
  function min(uint a, uint b) internal constant returns (uint) {
      return !(a>b)?a:b;
  }
  
}
