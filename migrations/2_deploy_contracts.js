const KronToken = artifacts.require('KronToken');
const XKronToken = artifacts.require('xKronToken');
const KronFarm = artifacts.require('KronFarm'); 

module.exports = async function(deployer, network, accounts) {

  // Migrations
  // Deploy KRON Token
  await deployer.deploy(KronToken);
  const _kronToken = await KronToken.deployed(); // Await instance of KRON Token

  // Deploy XKRON Token
  await deployer.deploy(XKronToken);
  const _xkronToken = await XKronToken.deployed();

  await deployer.deploy(KronFarm, _kronToken.address, _xkronToken.address);
  const _kronFarm = await KronToken.deployed(); // Await instance of KRON Farm
};
