pragma solidity ^0.4.11;


import './Interfaces.sol';
import './RemoteWallet.sol';
import './ColdStorageLib.sol';


contract ColdStorage is ColdStorageInterface, RemoteWallet {
  
  ColdStorageLib.ColdStorageData cs_data;
  
  function ColdStorage(address _parent, address _owner) RemoteWallet(_parent, _owner) {
    cs_data.time_created = block.timestamp;
    data.wallet_type = 2;
  }
  
  function _InitOwnerPermissions() internal {
    super._InitOwnerPermissions();

    _SetPermissionBySig(bytes4(sha3("_APIAddRefundableTokenAmount(uint256)")), data.owner, false, false);
    _SetPermissionBySig(bytes4(sha3("APIGetRefund()")), data.owner, true, true);
    _SetPermissionBySig(bytes4(sha3("APIDeposit()")), data.owner, false, false); //Only parent can deposit
    _SetPermissionBySig(0, data.owner, false, false); //Only parent can deposit
  }
  
  function _InitParentPermissions() internal {
    super._InitParentPermissions();

    _SetPermissionBySig(bytes4(sha3("_APIAddRefundableTokenAmount(uint256)")), data.parent, true, true);
    _SetPermissionBySig(bytes4(sha3("APIGetRefund()")), data.parent, true, false); //parent can force refund, but can't turn it off
    _SetPermissionBySig(bytes4(sha3("APIDeposit()")), data.parent, true, false);
    _SetPermissionBySig(0, data.parent, true, false);
  }
  
  //Amount that needs to be burned in order to receive full refund.
  function _APIAddRefundableTokenAmount(uint256 _amount) external RestrictedCall() {
    cs_data.parent_context[data.parent].tokens_holdings = cs_data.parent_context[data.parent].tokens_holdings.add(_amount);
  }
  
  function APIGetTimeCreated() public constant returns(uint256) {
    return cs_data.time_created;
  }
  
  function APIGetTokensBought() public constant returns(uint256) {
    return cs_data.parent_context[data.parent].tokens_holdings;
  }
  
  function APIGetEtherAmount() public constant returns(uint256) {
    return cs_data.parent_context[data.parent].funds_deposited;
  }
  
  function APIGetRefundedAmount() public constant returns(uint256) {
    return cs_data.parent_context[data.parent].refunded_amount;
  }
  
  //Tokens are first send to cold storage, then burned.
  function APIGetRefund() external RestrictedCall() returns(uint256) {
    return ColdStorageLib.APIGetRefund(cs_data, data);
  }
  
  function _APIBurnTokens(uint256 _amount) internal returns(bool) {
    return ColdStorageLib._APIBurnTokens(cs_data, data, _amount);
  }
  
  function() payable RestrictedCall() {
    cs_data.parent_context[data.parent].funds_deposited = cs_data.parent_context[data.parent].funds_deposited.add(msg.value);
  }
  
  function APIDeposit() payable external RestrictedCall() returns(bool) {
    cs_data.parent_context[data.parent].funds_deposited = cs_data.parent_context[data.parent].funds_deposited.add(msg.value);
  }
  
}

