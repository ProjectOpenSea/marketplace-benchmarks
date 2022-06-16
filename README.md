# Marketplace Benchmarks

Marketplace Benchmarks is a repository which runs a variety of generaized tests on NFT marketplaces to benchmark them for gas efficiency.

### Setup

```sh
git clone https://github.com/transmissions11/foundry-template.git
cd foundry-template
```

#### Install Foundry
To install Foundry (assuming a Linux or macOS system):

```bash
curl -L https://foundry.paradigm.xyz | bash
```

This will download foundryup. To start Foundry, run:

```bash
foundryup
```

To install dependencies:

```bash
forge install
```

### Run Tests
Tests are all run against mainnet deployments of active marketplaces, as such, a Mainnet Ethereum RPC is required.
```bash
forge test --fork-url <ETH_MAINNET_RPC>
```