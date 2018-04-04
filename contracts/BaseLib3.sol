pragma solidity ^0.4.11;

import './Interfaces.sol';
import './SafeMathLib.sol';

import './RemoteWalletLib.sol';
import './BaseLib.sol';
import './BaseLib2.sol';

import './CoreLib.sol';
import './ERC20Lib.sol';


library BaseLib3 {
  using SafeMathLib for uint256;
      
  event TokensBurned(uint256 amount);

  //event DebugAddress(address _address);
  //event DebugString(string _string);
  //event DebugUInt(uint _value);
      
  function PostInit(Types.DataContainer storage self, RemoteWalletLib.RemoteWalletData storage data, ERC20Lib.TokenData storage token, uint256 INITIAL_SUPPLY, uint256 foundation_amount, uint256 distribution_amount) returns(address) {
        uint256 distributed = 0;
        
        if (RemoteWalletLib.GetCallSequence(data, msg.sig) == 1) {
          self.lib_user = address(this);
          self.burn_during_refund = true;
        
          //Setup foundation virtual wallet
          self.foundation_virtual_wallet = CoreLib.CreateVirtualWallet(self, data.owner);

          VirtualWalletInterface virtual_wallet_object = VirtualWalletInterface(self.foundation_virtual_wallet);
          virtual_wallet_object.APISetDailyAmount(5 ether); //5 ether will be unlocked daily, for a stable revenue stream.
          
          RemoteWalletLib.NextCallSequence(data, msg.sig);
          return self.foundation_virtual_wallet;
        }
        
        if (RemoteWalletLib.GetCallSequence(data, msg.sig) == 2) {
          self.tokens_for_distribution = _CreateTokenStorage(self, token, address(this), distribution_amount, 0); //90% distribution storage
          //DebugUInt(foundation_amount);
          //DebugUInt(ERC20Lib.balanceOf(token, address(this)));
          
          RemoteWalletLib.NextCallSequence(data, msg.sig);
          return self.tokens_for_distribution;
        }
        
        if (RemoteWalletLib.GetCallSequence(data, msg.sig) == 3) {
          self.foundation_token_storage = _CreateTokenStorage(self, token, data.owner, foundation_amount, 180 * 4); //Full amount will be inlocked in 2 years.
          distributed += foundation_amount;
          
          RemoteWalletLib.NextCallSequence(data, msg.sig);
          return self.foundation_token_storage;
        }
        
        //uint256 leftover = 0;
        //_Burn(token, leftover);
  }
  
  function AddAngelInvestors(Types.DataContainer storage self, RemoteWalletLib.RemoteWalletData storage data, ERC20Lib.TokenData storage token, uint256 angel_investors_amount) returns(address) {
        //Add Angel Investors
        uint256 distributed = 0;
        
        if (RemoteWalletLib.GetCallSequence(data, msg.sig) == 1) {
          distributed += angel_investors_amount * 1 / 28;
          RemoteWalletLib.NextCallSequence(data, msg.sig);
          return _CreateTokenStorage(self, token, address(0x42916c70027B7294bE48F8524d6C70288d0Bdd5c), angel_investors_amount * 1 / 28, 180); //Valid mainnet address
        }
        
        if (RemoteWalletLib.GetCallSequence(data, msg.sig) == 2) {
          distributed += angel_investors_amount * 7 / 28;
          RemoteWalletLib.NextCallSequence(data, msg.sig);
          return _CreateTokenStorage(self, token, address(0xb874d41bFD4a3df3e3d3C77dF41374862b9C66C5), angel_investors_amount * 7 / 28, 180); //Valid mainnet address
        }
        
        if (RemoteWalletLib.GetCallSequence(data, msg.sig) == 3) {
          distributed += angel_investors_amount * 20 / 28;
          RemoteWalletLib.NextCallSequence(data, msg.sig);
          return _CreateTokenStorage(self, token, address(0x0910959a05c6270B7D5154cCa440f017E89625f3), angel_investors_amount * 20 / 28, 180); //Valid mainnet address
        }
        
  }
  
  function _CreateTokenStorage(Types.DataContainer storage self, ERC20Lib.TokenData storage token, address _address, uint256 _amount, uint256 _divider) private returns(address) {
    address _token_storage = BaseLib._CreateTokenStorage(self, _address, _amount, _divider);
    
    ERC20Lib._move_tokens(token, address(this), _token_storage, _amount );
    
    return _token_storage;
  }
  
  
  function _Burn(ERC20Lib.TokenData storage token, uint256 _amount) private {
    ERC20Lib._move_tokens(token, address(this), address(0x0), _amount );
    
    TokensBurned(_amount);
  }
  
  
}