pragma solidity ^0.4.11;


import './Interfaces.sol';
import './BaseWallet.sol';

/*
This is a limited type wallet that stores Ether and allows for a maximum daily withdraw limit can be set.
The lower the daily rate the higher is the voting weight. This prevents bad actors from abusing the voting system and separates true supporters from someone who purchased by mistake.
DO NOT send any tokens to these contracts!
*/

contract VirtualWallet is VirtualWalletInterface, BaseWallet {
  
  function VirtualWallet(address _parent, address _owner) BaseWallet(_parent, _owner) {
    data.wallet_type = 1;
    lw_data.storage_type = BaseWalletLib.StorageType.Ether;
  }
  
  function _InitOwnerPermissions() internal {
    super._InitOwnerPermissions();
    
    _SetPermissionBySig(0, data.owner, true, true); //Anyone can deposit
    
    _SetPermissionBySig(bytes4(sha3("APIDeposit()")), address(0x0), true, false); //Anyone can deposit
    _SetPermissionBySig(bytes4(sha3("APIDeposit()")), data.owner, true, true);
  }
  
  function _InitParentPermissions() internal {
    super._InitParentPermissions();
    
    _SetPermissionBySig(0, data.parent, true, false); //Anyone can deposit
    _SetPermissionBySig(bytes4(sha3("APIDeposit()")), data.parent, true, false);
  }
  
  function() payable RestrictedCall() {
    lw_data.parent_context[data.parent].amount += msg.value;
  }
  
  function APIDeposit() RestrictedCall() payable external returns(bool) {
    lw_data.parent_context[data.parent].amount += msg.value;
  }
}

