pragma solidity ^0.4.11;


import './Interfaces.sol';
import './SafeMathLib.sol';
import './RemoteWalletLib.sol';


library BaseWalletLib {
  using SafeMathLib for uint256;
  
  struct ParentState {
    uint256 amount;
    uint256 daily_amount;
    uint256 withdrawn_amount;
    
    uint256 unlocked_amount;
    uint256 burned_amount;
  }
  
  enum StorageType { Ether, Tokens }
  
  struct BaseWalletData {
    mapping(address => ParentState) parent_context;
    uint256 time_created;
    StorageType storage_type;
  }
  
  function APIUnlock(BaseWalletData storage self, RemoteWalletLib.RemoteWalletData storage data, uint256 _amount) returns(uint256) {
    require(_amount > 0);
    
    uint256 _tmp_time_shift = data.master_contract._TMP_get_time_shift();
    uint256 time_now = block.timestamp + _tmp_time_shift;
    uint256 time_passed = time_now - self.time_created;
    uint256 days_passed = time_passed / RemoteWalletLib.GetSecondsInADay();
    
    if (days_passed * self.parent_context[data.parent].daily_amount <= self.parent_context[data.parent].withdrawn_amount) {
      return 0;
    }
    
    uint256 max_allowed_withdrawal = days_passed * self.parent_context[data.parent].daily_amount - self.parent_context[data.parent].withdrawn_amount;
    uint256 current_balance = APIGetBalance(self, data);
    
    
    uint256 allowed_withdrawal = min(max_allowed_withdrawal, current_balance);
    uint256 unlocked = min(allowed_withdrawal, _amount);
    
    
    
    self.parent_context[data.parent].unlocked_amount = self.parent_context[data.parent].unlocked_amount.add(unlocked);
    
    return unlocked;
  }
  
  function APIGetBalance(BaseWalletData storage self, RemoteWalletLib.RemoteWalletData storage data) returns(uint256) {
    if(self.storage_type == StorageType.Tokens) return data.master_contract.balanceOf(address(this));
    if(self.storage_type == StorageType.Ether) return this.balance;
    return 0;
  }
  
  function APIWithdraw(BaseWalletData storage self, RemoteWalletLib.RemoteWalletData storage data, uint256 _amount) returns(uint256) {
    return APIWithdrawTo(self, data, _amount, data.owner);
  }
  
  //Allows to send ether/tokens to someone else directly.
  function APIWithdrawTo(BaseWalletData storage self, RemoteWalletLib.RemoteWalletData storage data, uint256 _amount, address _to) returns(uint256) {
    require(APIGetBalance(self, data) >= _amount);
    
    if (self.parent_context[data.parent].daily_amount > 0) { //Daily limit set
      uint256 unlocked = APIUnlock(self, data, _amount - self.parent_context[data.parent].unlocked_amount);
      require(self.parent_context[data.parent].unlocked_amount >= _amount);
      require(unlocked == _amount);
    }
    
    address destination = _to;
    if (_to == address(0x0)) _to = data.owner; //If anyone wants to burn the tokens, they can do it from their own wallet
    
    
    if (self.storage_type == StorageType.Tokens) {
        require(data.master_contract.transfer(_to, _amount));
        self.parent_context[data.parent].withdrawn_amount = self.parent_context[data.parent].withdrawn_amount.add(_amount);
        self.parent_context[data.parent].amount = self.parent_context[data.parent].amount.sub(_amount);
        
        if (self.parent_context[data.parent].daily_amount > 0) {
          self.parent_context[data.parent].unlocked_amount = self.parent_context[data.parent].unlocked_amount.sub(_amount);
        }
        
        data.master_contract.WalletWithdrewCallback(address(this), _to, _amount);
        return _amount;
    }
    
    if (self.storage_type == StorageType.Ether) {
        require(_to.call.value(_amount)());
        self.parent_context[data.parent].withdrawn_amount = self.parent_context[data.parent].withdrawn_amount.add(_amount);
        self.parent_context[data.parent].amount = self.parent_context[data.parent].amount.sub(_amount);
        
        if (self.parent_context[data.parent].daily_amount > 0) {
          self.parent_context[data.parent].unlocked_amount = self.parent_context[data.parent].unlocked_amount.sub(_amount);
        }
        
        data.master_contract.WalletWithdrewCallback(address(this), _to, _amount);
        return _amount;
    }

    return 0;
  }
  
  function APILowerDailyAmount(BaseWalletData storage self, RemoteWalletLib.RemoteWalletData storage data, uint256 _new_daily_amount) {
    require(_new_daily_amount > 0 && _new_daily_amount < self.parent_context[data.parent].daily_amount);
    self.parent_context[data.parent].daily_amount = _new_daily_amount;
  }
  
  function max(uint256 a, uint256 b) constant returns (uint256) {
      return (a>b)?a:b;
  }
  
  function min(uint256 a, uint256 b) constant returns (uint256) {
      return !(a>b)?a:b;
  }
}
