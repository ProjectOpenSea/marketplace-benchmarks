# Marketplace Benchmarks
Marketplace Benchmarks is a repository which runs a variety of generalized tests on NFT marketplaces to benchmark them for gas efficiency. View benchmark results [here](../results/results.pdf).

### Setup

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
Tests are all run against mainnet deployments of active marketplaces, as such, a Mainnet Ethereum RPC is required. This will log gas snapshots for each individual test operation.
```bash
forge test --fork-url <ETH_MAINNET_RPC> -vv
```

### Adding A Marketplace
1. Create a marketplace config in `/src/marketplaces`
2. Integrate into [`GenericMarketplaceTest`](test/GenericMarketplaceTest.t.sol)
    - Import your marketplace config
    - Create a global variable for your marketpalce config
    - Deploy and set your marketplace config in the constructor
    - Create a new test named `test<YOUR_MARKETPLACE>` which calls `benchmarkMarket(BaseMarketConfig config)` with your marketplace config.

#### Marketplace Config
A marketplace config must inherits [`BaseMarketConfig`](src/BaseMarketConfig.sol#L53-L254). See [`SeaportConfig`](src/marketplaces/seaport/SeaportConfig.sol) for reference.

##### *Required Functions*
- `beforeAllPrepareMarketplace(address seller, address buyer)` - This function must set the [approval targets](src/BaseMarketConfig.sol#L14-L26) for the marketplace. These addresses will be used prior to each test to reset buyer/seller approvals.
- `name()` - This function must return the name of the marketplace to use in benchmarking results
- `market()` - This function must return the address of the marketplace. It is used to reset the marketplace storage between tests.

##### *Optional Functions*
There are a variety of different types of tests which your market can support by implementing any of the functions defined in the `Test Payload Calls` section of [`BaseMarketConfig`](src/BaseMarketConfig.sol). Tests that use unimplemented payload calls will show up as incompatable with your marketplace.

`beforeAllPrepareMarketplaceCall` is an optional setup function which allows for any arbitrary calls to be sent from any address. For example: it is used to deploy Wyvern proxies for the buyer and seller prior to benchmarking Wyvern.

### Adding A Test
Anyone can add a generalized test to this repository which will enable for checkpointing different functionalities across marketplaces.

#### Creating the Generalized Test
Generalized tests are written in [`GenericMarketplaceTest`](test/GenericMarketplaceTest.t.sol). Use the simple [ERC721->Ether](test/GenericMarketplaceTest.t.sol#L78-L110) test as a reference.

1. Ensure that the buyer (Bob) and seller (Alice) have sufficient funds for the transaction. Each user is dealt enough ETH prior to the test.
2. Find an appropriate payload call in [`BaseMarketConfig`](src/BaseMarketConfig.sol). If none exists, you may create a new one.
3. Use `_benchmarkCallWithParams` to call the payload.
4. Add assertions throughout the test to ensure that the marketplace is actually doing what you expect it to.
