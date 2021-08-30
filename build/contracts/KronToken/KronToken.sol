// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {KronFarm} from "../KronFarm/KronFarm.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract KronToken is ERC20, ERC20Burnable, AccessControl {

    address private owner;
    uint256 private _totalSupply        = 840000000000000000000000000000; // 840 BILLION Kron, 420 BILLION Kron to be minted to ShibaSwap contract by the dev wallet
    uint private _rewardsFactor;
    uint private _devRewardsFactor;
    address private _rewardsAddress;
    address private _devRewardsAddress1;
    address private _devRewardsAddress2;

    uint256 private _antiWhaleLimit     = 840000000000000000000000000;  // 840 MILLION KRON, Hard cap on transfer quantity (0.01% of Total Supply)

    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => uint256) private _blockNumberByAddress;

    constructor() ERC20("KRON Token", "KRON") {

        // Save deployer / owner address
        owner = msg.sender;

        // Specify rewards factor
        _rewardsFactor         = 40;    // Reward is 1/40th of X = 0.025 or 2.5%

        // Specify dev rewards factor, calculated as a small portion of total rewards, which the 2.5% transfer fee
        _devRewardsFactor      = 20;    // 5% of 2.5%

        // Specify rewards address
        _rewardsAddress = address(0xC38E4c8dF2B4A84D67A68Cdc67ACd451699aF9c9); // Third account in list

        // Specify developer rewards address 
        _devRewardsAddress1 = address(0x5fc26db945FE7f7Ae8B026a1dF3684358aa1c01B); // Fourth account in list
        _devRewardsAddress2 = address(0x3A0446C8300AE485ef9C4fF90E7d376197416518); // Fifth account in list

        // Mint total supply to contract owner
        _mint(owner, _totalSupply);

        // Grant the admin role to a specified account (contract deployer)
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
    }

    function rewardsFactor() public view returns (uint256)
    {
        return _rewardsFactor;
    }

    function ensureOneHuman(address _to, address _from) internal virtual returns (address) {
        require(!Address.isContract(_to) || !Address.isContract(_from), 'KRON Token: Atleast one human address is required!');
        if (Address.isContract(_to)) return _from;
        else return _to;
    }

    function ensureOneTxPerBlock(address addr) internal virtual {
        bool isNewBlock = _blockNumberByAddress[addr] == 0 ||
        _blockNumberByAddress[addr] < block.number;

        require(isNewBlock, 'KRON Token: Only one transaction per block is allowed!');
    }
    
    function transfer(address _to, uint256 _value) public virtual override returns (bool) {

        require(_value < _antiWhaleLimit, "KronToken: Transfer amount exeeds 0.01% of total supply!");

        address _from = msg.sender;
        address human = ensureOneHuman(_from, _to);
        ensureOneTxPerBlock(human);

        uint256 totalRewards = _value / _rewardsFactor;
        uint256 devTotalRewards = totalRewards / _devRewardsFactor;

        // Attempt transfer of X - Y rewards to specified address
        if (ERC20.transfer(_to, _value - totalRewards)) {
            
            // Attempt transfer of Y rewards to rewards wallet
            ERC20.transfer(_rewardsAddress, totalRewards - (devTotalRewards * 2));

            // Attempt transfer of DEV rewards to Dev Wallet 1
            ERC20.transfer(_devRewardsAddress1, devTotalRewards);

            // Attempt transfer of DEV rewards to Dev Wallet 2
            ERC20.transfer(_devRewardsAddress2, devTotalRewards);

            // Mark the block that this address 
            _blockNumberByAddress[human] = block.number;

            // Success
            return true;
        } 
        else
        {   
            // Failure
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {

        require(_value < _antiWhaleLimit, "KronToken: Transfer amount exeeds 0.01% of total supply!");
        
        address human = ensureOneHuman(_from, _to);
        ensureOneTxPerBlock(human);

        uint256 totalRewards = _value / _rewardsFactor;
        uint256 devTotalRewards = totalRewards / _devRewardsFactor;

        // Attempt transfer to designated address minus rewards fee
        if (ERC20.transferFrom(_from, _to, _value - totalRewards)) {
        
            // Transfer rewards to rewards wallet
            ERC20.transferFrom(_from, _rewardsAddress, totalRewards - (devTotalRewards * 2));
            
            // Attempt transfer of DEV rewards to Dev Wallet 1
            ERC20.transferFrom(_from, _devRewardsAddress1, devTotalRewards);

            // Attempt transfer of DEV rewards to Dev Wallet 2
            ERC20.transferFrom(_from, _devRewardsAddress2, devTotalRewards);

            // Mark block number at this address
            _blockNumberByAddress[human] = block.number;
            return true;
        } 
        else 
        {
            return false;
        }
    }

    function mint(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }
}
