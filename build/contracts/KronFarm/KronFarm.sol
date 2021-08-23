// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Import KronToken
import {KronToken} from "../KronToken/KronToken.sol";
import {XKronToken} from "./XKronToken.sol";

// Import Address Utility
import "@openzeppelin/contracts/utils/Address.sol";

// Contact
contract KronFarm {

    // Owner
    address public owner;

    // Name of Contract
    string public name = "KRON Farm";

    // Store instance of Kron Token
    KronToken public kronToken;

    // Store instance xKron Token
    XKronToken public xkronToken;

    // Array of stakers
    address[] public stakers;
    uint256 public totalStakedTokens;

    // Last reward block
    uint256 private lastRewardBlockTimeStamp;

    // Reward Throttle 
    uint256 private _ethRewardThrottle;

    // ETH Node Rewards Rates
    uint256 private _ethNodeProfit;
    uint256 private _ethNodeProfitRewardProcessingGasBounty;
    uint256 private _ethNodeProfitDripRate;

    // Address of the SHIBA Token Contract, sending KRON token to this address will benefit SHIB (33% of ETH Node rewards)
    address private _shibaBurnAddress;

    // Staking balance mapping
    mapping(address => uint256) public stakingBalance;

    // Has Staked ? mapping
    mapping(address => bool) public hasStaked;

    // Is Staking ? mapping
    mapping(address => bool) public isStaking;

    // Block Number -> Address Map
    mapping(address => uint256) private _blockNumberByAddress;

    // Minter Role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Constructor
    constructor(KronToken _kronToken, XKronToken _xkronToken) {

        kronToken = _kronToken;
        xkronToken = _xkronToken;
        owner = msg.sender;

        totalStakedTokens           = 0;
        _ethNodeProfit              = 3;      // 33% of KRON Farm Contract's to xKRON holders, 33% to SHIB ARMY, 33% to DEV
        _ethNodeProfitRewardProcessingGasBounty = 100;  // 1% of KRON Farm Contract's ETH Balance
        _ethNodeProfitDripRate      = 10;               //  10% of total profit in this contract's ETH ledger will be processed

        _ethRewardThrottle          = 0 seconds;        // 0 second reward throttle
        lastRewardBlockTimeStamp    = block.timestamp;

        //_shibaBurnAddress = = address(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE); PRODUCTION MODE ONLY
        _shibaBurnAddress = address(0x20788d5F1A23e3f9Db2eBFc2be490D6567990921); // DEVELOPMENT / GANACHE MODE ONLY (4th address)
    }

    // Will receive any eth sent to the contract
    receive() external payable {}

    // Will be called when no other function matches, not even the receive function
    fallback() external payable {}

    // Ensures only one tx per block per address
    function ensureOneTxPerBlock(address addr) internal virtual {
        bool isNewBlock = _blockNumberByAddress[addr] == 0 ||
        _blockNumberByAddress[addr] < block.number;

        require(isNewBlock, 'KRON Farm: Only one transaction per block is allowed!');

        _blockNumberByAddress[addr] = block.number;
    }

    // 1. Stake Tokens, Allows investors to stake tokens to earn rewards
    function stakeTokens(uint256 _amount) public {

        address _from = msg.sender;
        require(Address.isContract(_from) == false, "KRON Farm: Contracts are not allowed to stake!");
        ensureOneTxPerBlock(_from);

        // Require _amount to be > 0
        require(_amount > 0, "Amount cannot be 0");
        
        // Transfer KRON Tokens to dev wallet for staking
        kronToken.burnFrom(msg.sender, _amount);

        // Transfer xKRON Tokens from dev wallet to investor for holding
        xkronToken.mint(msg.sender, _amount);

        // Update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;
        totalStakedTokens += _amount;

        // Add user to stakers array only if they haven't staked already
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status
        hasStaked[msg.sender] = true;
        isStaking[msg.sender] = true;
    }

    // 2. Unstaking Tokens, Allows investors to unstake their tokens
    function unstakeTokens(uint256 _amount) public {

        address _from = msg.sender;
        require(Address.isContract(_from) == false, "KRON Farm: Contracts are not allowed to unstake!");
        ensureOneTxPerBlock(_from);

        require(_amount > 0, "Amount cannot be 0");

        // Current balance
        uint256 balance = stakingBalance[msg.sender];

        // Require amount <= balance
        require(_amount <= balance, "Amount cannot be greater than staked balanced!");
                
        // Burn xKRON from investors wallet
        xkronToken.burnFrom(msg.sender, _amount);

        // Mint KRON to investors wallet
        kronToken.mint(address(this), _amount);
        kronToken.transfer(msg.sender, _amount);

        // Update the staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] - _amount;
        totalStakedTokens -= _amount;

        // Remove user from stakers array if their balance = 0
        if (hasStaked[msg.sender] && stakingBalance[msg.sender] == 0) {
            
            // Update staking status
            hasStaked[msg.sender] = false;
            isStaking[msg.sender] = false;
        }
    }

    // 3. Issuing Rewards, Allows investors to claim their interest rewards
    function issueRewards() public {
        
        address _from = msg.sender;
        require(Address.isContract(_from) == false, "KRON Farm: Contracts are not allowed to process rewards!");
        ensureOneTxPerBlock(_from);

        // Prevent contract calls to this function when the current block timestamp isn't greater than the last contract call + our throttle limitation
        require(block.timestamp > lastRewardBlockTimeStamp + _ethRewardThrottle, "KRON Farm contract rewards denied! Contract call occured too soon!");

        // Update our last reward block timestamp state variable
        lastRewardBlockTimeStamp = block.timestamp;

        uint256 totalProfits = address(this).balance / _ethNodeProfitDripRate; // ETH balance of contract

        uint256 bounty = totalProfits / _ethNodeProfitRewardProcessingGasBounty; // 1% of total profits
        totalProfits -= bounty; // correct the totalProfits variable for further processing

        uint256 thirdProfits = totalProfits / _ethNodeProfit;

        // The farm contract must have enough ETH to distribute rewards
        require(address(this).balance >= totalProfits, "KRON Farm contract does not have sufficient eth balance to distribute rewards!");

        // Issue tokens to stakers (xKRON Rewards)
        for (uint256 i=0; i < stakers.length; i++) {

            address recipient = stakers[i];
            uint256 balance = stakingBalance[recipient];

            if (balance > 0) {

                uint256 share = balance / totalStakedTokens;

                if (share > 0) {

                    // Pay the staker their fair share of ETH from the ETH node profits (33%)
                    payable(recipient).transfer(share * thirdProfits);
                }
            }
        }

        // Distribute to SHIBA Token Contract / SHIBATOKEN.com
        payable(_shibaBurnAddress).transfer(thirdProfits);

        // Distribute to Dev team (need array of dev wallet addresses to implement)
        payable(owner).transfer(thirdProfits);

        // Distribute bounty to contract caller (rewards processor / good samaritan)
        payable(msg.sender).transfer(bounty);
    }
}