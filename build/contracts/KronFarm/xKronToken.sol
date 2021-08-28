// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {KronFarm} from "./KronFarm.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract XKronToken is ERC20, ERC20Burnable, AccessControl {
    
    address private owner;
    uint256 private _totalSupply        = 840000000000000000000000000000;

    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => uint256) private _blockNumberByAddress;

    constructor() ERC20("xKRON Token", "xKRON") {

        // Save deployer / owner address
        owner = msg.sender;

        // Mint total supply to contract owner
        _mint(owner, _totalSupply);

        // Grant the admin role to a specified account (contract deployer)
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
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

        address _from = _msgSender();
        address human = ensureOneHuman(_from, _to);
        ensureOneTxPerBlock(human);

        // Attempt transfer of X - Y rewards to specified address
        if (ERC20.transfer(_to, _value)) {
            
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

        address human = ensureOneHuman(_from, _to);
        ensureOneTxPerBlock(human);

        // Attempt transfer to designated address minus rewards fee
        if (ERC20.transferFrom(_from, _to, _value)) {
        
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
