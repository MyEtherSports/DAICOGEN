pragma solidity ^0.4.11;


import './Interfaces.sol';
import './SafeMathLib.sol';
import './RemoteWalletLib.sol';


library ColdStorageLib {
  using SafeMathLib for uint256;
  
  
  struct ParentState {
    uint256 tokens_holdings;
    uint256 funds_deposited; //How much ether was deposited by the owner
    uint256 refunded_amount;
  }
  
  struct ColdStorageData {
    uint256 time_created;
    mapping(address => ParentState) parent_context;
  }
  
  
  //Tokens are first send to cold storage, then burned.
  function APIGetRefund(ColdStorageData storage self, RemoteWalletLib.RemoteWalletData storage data) returns(uint256) {
    uint256 return_value = self.parent_context[data.parent].funds_deposited;
    
    require(this.balance >= self.parent_context[data.parent].funds_deposited); //Should always be true
    require(data.master_contract.balanceOf(address(this)) >= self.parent_context[data.parent].tokens_holdings);
    
    require(_APIBurnTokens(self, data, self.parent_context[data.parent].tokens_holdings));
    require(data.owner.call.value(self.parent_context[data.parent].funds_deposited)());
    
    data.master_contract.RefundedNotification(data.owner, self.parent_context[data.parent].tokens_holdings, self.parent_context[data.parent].funds_deposited);
    
    self.parent_context[data.parent].refunded_amount = self.parent_context[data.parent].refunded_amount.add(self.parent_context[data.parent].funds_deposited);
    self.parent_context[data.parent].funds_deposited = 0;
    self.parent_context[data.parent].tokens_holdings = 0;
    
    return return_value;
  }
  
  //This function will allow authorized called to transfer any amount anywhere. Should be disabled by default.
  function APIAuthorizedTransfer(ColdStorageData storage self, uint256 _amount, address _to) returns(uint256) {
    if (_amount == 0 || this.balance < _amount) return 0;
    
    require(_to.call.value(_amount)());
    return _amount;
  }
  
  function _APIBurnTokens(ColdStorageData storage self, RemoteWalletLib.RemoteWalletData storage data, uint256 _amount) returns(bool) {
    if (!data.master_contract.RequireBurn()) {
      data.master_contract.transfer(data.owner, _amount); //Send back tokens to owner.
      return true; //No need to burn;
    }
    return data.master_contract.transfer(address(0x0), _amount);
  }
  
}

