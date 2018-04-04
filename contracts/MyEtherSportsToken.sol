pragma solidity ^0.4.11;


import './ERC20Lib.sol';

/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

 contract MyEtherSportsToken {
   using ERC20Lib for ERC20Lib.TokenData;

   ERC20Lib.TokenData token;

    string public name = "MyEtherSports";
    string public symbol = "GEN";
    uint256 public decimals = 8;
    uint256 public INITIAL_SUPPLY = 100000000e8;  //100,000,000 tokens, with 8 decimal precision

   function MyEtherSportsToken(address _owner) {
     token.init(INITIAL_SUPPLY, _owner);
   }

   function totalSupply() constant returns (uint256) {
     return token.totalSupply;
   }

   function balanceOf(address who) constant returns (uint256) {
     return token.balanceOf(who);
   }

   function allowance(address owner, address spender) constant returns (uint256) {
     return token.allowance(owner, spender);
   }

   function transfer(address to, uint256 value) returns (bool ok) {
     return token.transfer(to, value);
   }

   function transferFrom(address from, address to, uint256 value) returns (bool ok) {
     return token.transferFrom(from, to, value);
   }

   function approve(address spender, uint256 value) returns (bool ok) {
     return token.approve(spender, value);
   }

   
   
   event Transfer(address indexed from, address indexed to, uint256 value);
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }