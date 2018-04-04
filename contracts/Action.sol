pragma solidity ^0.4.11;

import "./RemoteWallet.sol";

/*
When creating a proposal for supermajority to vote for, an action address and procedure signature must be specified.
This is an example action contract for SuperMajority vote.
*/

contract Action is RemoteWallet {
  function Action() RemoteWallet(address(0x0), msg.sender) {
  }
  
  //This function will be called using delegatecall, preserving the context of contract it's called from.
  function LockDevFund() external {
      _SetPermissionBySig(bytes4(sha3("APIWithdraw(uint256)")), data.owner, false, false);
  }
  
  function UnlockDevFund() external {
      _SetPermissionBySig(bytes4(sha3("APIWithdraw(uint256)")), data.owner, true, true);
  }
}