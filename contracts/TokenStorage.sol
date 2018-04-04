pragma solidity ^0.4.11;


import './Interfaces.sol';
import './VirtualWallet.sol';
import './RemoteWallet.sol';

/*
This is a limited type wallet that stores ETS tokens and allows for a maximum daily withdraw limit can be set.
The lower the daily rate the higher is the voting weight. This prevents bad actors from abusing the voting system and separates true supporters from someone who purchased by mistake.
*/

contract TokenStorage is TokenStorageInterface, BaseWallet {
  
  function TokenStorage(address _parent, address _owner, uint256 _daily_amount) BaseWallet(_parent, _owner) {
    data.wallet_type = 3;
    lw_data.storage_type = BaseWalletLib.StorageType.Tokens;
    
    if (_daily_amount > 0) APISetDailyAmount(_daily_amount);
  }
  
  function _InitOwnerPermissions() internal {
    super._InitOwnerPermissions();
    
     _SetPermissionBySig(bytes4(sha3("APIUpdateTokenAmount()")), address(0x0), true, true);
    
    _SetPermissionBySig(bytes4(sha3("APIDeposit()")), address(0x0), false, false);
    _SetPermissionBySig(bytes4(sha3("APIDeposit()")), data.owner, false, false);
    
  }
  
  function _InitParentPermissions() internal {
    super._InitParentPermissions();
    
     _SetPermissionBySig(bytes4(sha3("APIUpdateTokenAmount()")), address(0x0), true, true);
    
    _SetPermissionBySig(bytes4(sha3("APIDeposit()")), address(0x0), false, false);
    _SetPermissionBySig(bytes4(sha3("APIDeposit()")), data.parent, false, false);
    
    _SetPermissionBySig(bytes4(sha3("APISetTokenAmount(uint256)")), data.parent, true, true);
  }
  
  //Sets the initial token amount, only master contract should be able to do that.
  function APISetTokenAmount(uint256 _amount) public RestrictedCall() returns(bool) {
    require(lw_data.parent_context[data.parent].amount == 0);
    require(_amount > 0); //Only once
    lw_data.parent_context[data.parent].amount = _amount;
  }
  
  function APIUpdateTokenAmount() public RestrictedCall() returns(bool) {
    lw_data.parent_context[data.parent].amount = data.master_contract.balanceOf(address(this));
  }
}
