module.exports = {
    networks: {
      development: {
        host: "127.0.0.1",
        port: 7545,
        network_id: "*" // Match any network id
      }
    },
    contracts_directory: './build/contracts/',
    contracts_build_directory: './build/abis/',
    compilers: {
      solc: {
        version: "^0.8.0"
      }
    }
};