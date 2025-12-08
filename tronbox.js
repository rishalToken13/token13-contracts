// tronbox.js
module.exports = {
  networks: {
    shasta: {
      privateKey: process.env.PRIVATE_KEY,
      consume_user_resource_percent: 30,
      fee_limit: 100000000,
      fullHost: process.env.SHASTA_FULLNODE || "https://api.shasta.trongrid.io",
      network_id: "2"
    },
    mainnet: {
      privateKey: process.env.PRIVATE_KEY,
      consume_user_resource_percent: 30,
      fee_limit: 100000000,
      fullHost: process.env.MAINNET_FULLNODE || "https://api.trongrid.io",
      network_id: "1"
    }
  },

  solc: {
    version: "0.8.18",
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};
