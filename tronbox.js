require("dotenv").config();

const {
  PRIVATE_KEY,
  SHASTA_FULLNODE,
  SHASTA_SOLIDITYNODE,
  SHASTA_EVENTSERVER,
  MAINNET_FULLNODE,
  MAINNET_SOLIDITYNODE,
  MAINNET_EVENTSERVER,
} = process.env;

module.exports = {
  networks: {
    // Shasta Testnet
    shasta: {
      privateKey: PRIVATE_KEY,
      consume_user_resource_percent: 30,
      fee_limit: 100000000, // in SUN (100 TRX)
      fullHost: SHASTA_FULLNODE || "https://api.shasta.trongrid.io",
      network_id: "2"
    },

    // Tron Mainnet
    mainnet: {
      privateKey: PRIVATE_KEY,
      consume_user_resource_percent: 30,
      fee_limit: 100000000, // in SUN (100 TRX)
      fullHost: MAINNET_FULLNODE || "https://api.trongrid.io",
      network_id: "1"
    }
  },

  // Compiler settings
  solc: {
    version: "0.8.20",     // You can change this
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};
