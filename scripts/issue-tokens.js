const TokenFarm = artifacts.require('TokenFarm');

module.exports = async function(callback) {

    // Deploy TokenFarm
    let _tokenFarm = await TokenFarm.deployed();
    await _tokenFarm.issueTokens();
    
    console.log("Tokens issued!");

    callback();
  };
  