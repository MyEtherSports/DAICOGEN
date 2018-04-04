pragma solidity ^0.4.11;


import './Interfaces.sol';
import './RemoteWallet.sol';
import './BaseWalletLib.sol';

/*
Limited wallet type that acts as a base for VirtualWallet and TokenStorage classes. Has the ability to set maximum daily rate.
*/

contract BaseWallet is BaseWalletInterface, RemoteWallet {
  
  BaseWalletLib.BaseWalletData lw_data;
  
  function BaseWallet(address _parent, address _owner) RemoteWallet(_parent, _owner) {
    lw_data.time_created = block.timestamp;
    //data.wallet_type = 0; //default
  }
  
  function _InitOwnerPermissions() internal {
    super._InitOwnerPermissions();
    
    _SetPermissionBySig(bytes4(sha3("APIWithdraw(uint256)")), data.owner, true, true);
    _SetPermissionBySig(bytes4(sha3("APIWithdrawTo(uint256,address)")), data.owner, true, true);
    _SetPermissionBySig(bytes4(sha3("APIUnlock(uint256)")), data.owner, true, true);
    _SetPermissionBySig(bytes4(sha3("APILowerDailyAmount(uint256)")), data.owner, true, true);
    _SetPermissionBySig(bytes4(sha3("APISetDailyAmount(uint256)")), data.owner, true, true);
  }
  
  function _InitParentPermissions() internal {
    super._InitParentPermissions();
    
    _SetPermissionBySig(bytes4(sha3("APIWithdraw(uint256)")), data.parent, true, true);
    _SetPermissionBySig(bytes4(sha3("APIWithdrawTo(uint256,address)")), data.parent, true, true);
    _SetPermissionBySig(bytes4(sha3("APIUnlock(uint256)")), data.parent, true, true);
    _SetPermissionBySig(bytes4(sha3("APILowerDailyAmount(uint256)")), data.parent, true, true);
    _SetPermissionBySig(bytes4(sha3("APISetDailyAmount(uint256)")), data.parent, true, true);
  }
  
  function APIGetUnlockedAmount() public constant returns(uint256) {
    return lw_data.parent_context[data.parent].unlocked_amount;
  }
  
  function APIGetAmount() public constant returns(uint256) {
    return lw_data.parent_context[data.parent].amount;
  }
  
  function APIGetDailyAmount() public constant returns(uint256) {
    return lw_data.parent_context[data.parent].daily_amount;
  }
  
  function APILowerDailyAmount(uint256 _new_daily_amount) external RestrictedCall() {
    BaseWalletLib.APILowerDailyAmount(lw_data, data, _new_daily_amount);
  }
  
  function APISetDailyAmount(uint256 _daily_amount) public RestrictedCall() returns(bool) {
    //require(lw_data.parent_context[data.parent].daily_amount == 0); //once
    if(lw_data.parent_context[data.parent].daily_amount == 0) lw_data.parent_context[data.parent].daily_amount = _daily_amount;
    else {
      //Can only lower
      BaseWalletLib.APILowerDailyAmount(lw_data, data, _daily_amount);
    }
  }
  
  function APIUnlock(uint256 _amount) RestrictedCall() public returns(uint256) {
    return BaseWalletLib.APIUnlock(lw_data, data, _amount);
  }
  
  function APIWithdraw(uint256 _amount) RestrictedCall() public returns(uint256) {
    return BaseWalletLib.APIWithdraw(lw_data, data, _amount);
  }
  
  function APIWithdrawTo(uint256 _amount, address _to) RestrictedCall() public returns(uint256) {
    return BaseWalletLib.APIWithdrawTo(lw_data, data, _amount, _to);
  }
  
  
}

