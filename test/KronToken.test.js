const { assert } = require('chai');

require('chai').use(require('chai-as-promised')).should();
require('web3');

const KronToken = artifacts.require('KronToken');
const XKronToken = artifacts.require('xKronToken');
const KronFarm = artifacts.require('KronFarm');

function ToWei(x) {
    return web3.utils.toWei(x, 'ether');
}

contract('KronToken', (accounts) => {

    let _kronToken;

    let owner = accounts[0];
    let investor = accounts[1];

    before(async () => {

        _kronToken = await KronToken.new({from: owner});

        // Transfer 420 million KRON tokens to owner on deployment
        // Check owner balance before staking
        let result;

        result = await _kronToken.balanceOf(owner);
        assert.equal(result.toString(), ToWei('840000000000'), 'Owner KRON Token wallet ballance incorrect before transfer test.');
    });

    // Test the name of the KRON token deployment
    describe('KRON Token Deployment', async () => {
        it('has a name', async() => {
         
            const name = await _kronToken.name();
            assert.equal(name, 'KRON Token');
        });
    });

    // Test Token Transfer and Fee collection
    describe('Transferring Tokens', async () => {
        it('tests token transfer', async () => {

            let result;

            // Transfer 200 KRON to investor
            await _kronToken.transfer(investor, ToWei('200'));

            // Check owner balance after transfer
            result = await _kronToken.balanceOf(owner);
            assert.equal(result.toString(), ToWei('839999999800'), 'Owner KRON Balance incorrect after transfer.');

            // Check investor balance after transfer (200 - 2.5%)
            result = await _kronToken.balanceOf(investor);
            assert.equal(result.toString(), ToWei('195'), 'Investor KRON Balance incorrect after transfer.');

            // Check rewards wallet balance after transfer
            result = await _kronToken.balanceOf(accounts[3]);
            assert.equal(result.toString(), ToWei('4.5'), 'Rewards KRON Balance incorrect after transfer fee collection!')
        });
    });
});

contract('xKronToken', (accounts) => {

    let _xKronToken;

    let owner = accounts[0];
    let investor = accounts[1];

    before(async () => {

        _xKronToken = await XKronToken.new({from: owner});

        // Transfer 420 million KRON tokens to owner on deployment
        // Check owner balance before staking
        let result;

        result = await _xKronToken.balanceOf(owner);
        assert.equal(result.toString(), ToWei('840000000000'), 'Owner xKRON Token wallet ballance incorrect before test.');
    });

    // Test the name of the KRON token deployment
    describe('xKRON Token Deployment', async () => {
        it('has a name', async() => {
         
            const name = await _xKronToken.name();
            assert.equal(name, 'xKRON Token');
        });
    });
});

contract('KronFarm', (accounts) => {

    let _kronToken, _xKronToken, _kronFarm;

    let owner = accounts[0];
    let investor = accounts[1];
    let ethRewardWallet = accounts[2];

    // Test Setup
    before(async () => {

        _kronToken = await KronToken.new({from: owner});
        _xKronToken = await XKronToken.new({from: owner});
        _kronFarm = await KronFarm.new(_kronToken.address, _xKronToken.address, {from: owner});

        // Check owner balance before staking
        let result;

        result = await _kronToken.balanceOf(owner);
        assert.equal(result.toString(), ToWei('840000000000'), 'Owner KRON Token wallet ballance incorrect before staking test.');

        // Send 200 KRON to the investor for use in this test
        await _kronToken.transfer(investor, ToWei('200'));

        // Account for 2.5% fee = 200 - 5 = 195
        result = await _kronToken.balanceOf(investor);
        assert.equal(result.toString(), ToWei('195'), 'Investor KRON Token wallet balance incorrect before staking test.');

        // Give 1 ETH to the KRON Farm contract for distribution from 7th account in list
        let txHash = await web3.eth.sendTransaction({from: accounts[6], to: _kronFarm.address, value: 1000000000000000000});
    });

    // Test Minter roles
    describe('KRON Farm Minter Roles', async() => {
        it('tests minter roles, sends minter role for KRON & xKRON to KRON Farm.', async() => {

            // Grant minter role to KronFarm for KRON
            await _kronToken.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', _kronFarm.address, {from: owner});

            // Grant minter role to KronFarm for xKRON
            await _xKronToken.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', _kronFarm.address, {from: owner});
        });
    });

    // Test KRON Farm Deployment
    describe('KRON Farm Deployment', async() => {
        it('has a name', async() => {
         
            const name = await _kronFarm.name();
            assert.equal(name, 'KRON Farm');
        });
    });

    // STAKING
    describe('KRON Farm Staking', async() => {
        it('tests token staking', async() => {

            let result;

            // Approve 195 KRON for transfer from Investor -> KRON Farm Contract
            await _kronToken.approve(_kronFarm.address, ToWei('200'), {from: investor});

            // STAKE - Transfer 195 KRON from Investor -> KRON Farm Contract
            await _kronFarm.stakeTokens(ToWei('195'), {from: investor});

            // Check Balance (contract should have 190.125 KRON after fees)
            result = await _kronToken.balanceOf(_kronFarm.address);
            //assert.equal(result.toString(), ToWei('190.125'), "KronFarm Token Balance is incorrect after staking!");
            assert.equal(result.toString(), ToWei('0'), "KronFarm Token Balance is incorrect after staking!");

            // Check Balance of Investor (they should have 0 KRON)
            result = await _kronToken.balanceOf(investor);
            assert.equal(result.toString(), ToWei('0'), "KronFarm Token Balance is incorrect after unstaking!");
        });
    });

    // REWARD DISTRIBUTION
    describe('KRON Farm Reward Distribution', async() => {
        it('tests KRON Farm reward distribution from ETH Node Profits', async() => {

            let result;

            // REWARD DISTRIBUTION - Reward stakers
            await _kronFarm.issueRewards({ from: owner });

            // Check KRON Farm ETH Balance
            result = await web3.eth.getBalance(_kronFarm.address);
            //assert.equal(parseInt(result), parseInt(ToWei('0')), "KRON Farm contract ETH Balance is not 0, rewards were misallocated!");
        });
    });

    // GOOD SAMARITAN REWARD 1% TOTAL PROFITS
    describe('KRON FARM 1% Reward Processing Bounty', async() => {
        it('Rewards good samaritans for processing community rewards', async() => {

        });
    });

    // BURN to SHIBA TOKEN Contract
    describe('KRON FARM 33% Reward BURN TO SHIBARMY', async() => {
        it ('Rewards SHIBARMY for allowing us to list on their swap', async() => {

        });
    });

    // 33% DEV TEAM REWARD, MARKETING, DEV, RESEARCH, EXPANSION
    describe('KRON FARM 33% Reward BURN to Marketing, Research, Expansion', async() => {
        it ('Provides funding for further growth on the KRON ecosystem', async() => {

        });
    });

    // UNSTAKING
    describe('KRON Farm Unstaking', async() => {
        it('tests token unstaking', async() => {

            let result;

            // Approve KRON Farm to move xKRON on behalf of investor
            result = await _xKronToken.balanceOf(investor);
            await _xKronToken.approve(_kronFarm.address, ToWei('195'), {from: investor});

            // UNSTAKE - Transfer KRON from KRON Farm Contract to Investor
            await _kronFarm.unstakeTokens(ToWei('195'), {from: investor});
        
            // Check Balance of KRON Farm (contract should have 0 KRON)
            result = await _kronToken.balanceOf(_kronFarm.address);
            assert.equal(result.toString(), ToWei('0'), "KronFarm Token Balance is incorrect after unstaking! KronFarm should never hold any KRON balance!");

            // Check Balance of Investor (they should have 190.125 KRON after all 2.5% transfer fees are considered)
            result = await _kronToken.balanceOf(investor);
            assert.equal(result.toString(), ToWei('190.125'), "Investor Token Balance is incorrect after unstaking!");
            
            // Check total KRON fees collected
            result = await _kronToken.balanceOf(accounts[2]);
            console.log('Total KRON Fees Collected: ' + web3.utils.fromWei(result).toString());
        });
    });
});