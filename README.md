# STPP Smart Contracts

Hardhat workspace containing Solidity smart contracts for the STPP (Secure Token Presale Protocol) platform. This repository implements the core on-chain logic for permissionless token presales, including Dutch Auctions, Liquidity Bootstrap Pools (LBP), and token vesting mechanisms.

## Project Structure

```
contract/
├── contracts/                # Solidity source files
│   ├── core/                # Core protocol contracts
│   │   ├── auction/        # Dutch Auction implementation
│   │   │   ├── DutchAuction.sol
│   │   │   ├── AuctionConfig.sol
│   │   │   ├── errors/
│   │   │   └── events/
│   │   ├── lbp/            # Liquidity Bootstrap Pool
│   │   │   ├── SecureLBP.sol
│   │   │   ├── WeightedAMM.sol
│   │   │   ├── errors/
│   │   │   └── events/
│   │   └── vesting/        # Token vesting escrow
│   │       ├── TokenVestingEscrow.sol
│   │       ├── errors/
│   │       └── events/
│   │
│   ├── manager/            # Presale management contracts
│   │   ├── PresaleManager.sol      # Main presale orchestrator
│   │   ├── PublicPresaleFactory.sol # Factory for permissionless presales
│   │   ├── AuctionFactory.sol      # Auction creation factory
│   │   ├── UpkeepController.sol    # Chainlink Automation integration
│   │   ├── errors/
│   │   └── events/
│   │
│   ├── oracle/             # Price oracle for LBP
│   │   ├── LBPOracle.sol  # Adaptive fee and pause oracle
│   │   └── events/
│   │
│   ├── libraries/          # Reusable Solidity libraries
│   │   ├── CommitLib.sol           # Commit-reveal utilities
│   │   ├── PriceTickLib.sol        # Price tick calculations
│   │   ├── ReserveDecayLib.sol     # Reserve decay formulas
│   │   └── VestingMath.sol         # Vesting calculations
│   │
│   ├── interfaces/         # Contract interfaces
│   │   ├── IAuction.sol
│   │   ├── ILBP.sol
│   │   ├── IPresaleManager.sol
│   │   └── ...
│   │
│   ├── mocks/              # Mock contracts for testing
│   │   ├── TestToken.sol
│   │   ├── MockPriceFeed.sol
│   │   └── ...
│   │
│   └── test-attacks/       # Attack contracts for security testing
│       ├── ReentrantDutchAuctionAttacker.sol
│       └── ...
│
├── scripts/                # Deployment and utility scripts
│   ├── deployAll.ts        # Main deployment script
│   ├── generateWhitelistMerkle.ts  # Merkle tree generation
│   ├── uploadToIPFS.ts             # IPFS upload utility
│   └── computeBonusAllocations.ts  # Bonus computation script
│
├── test/                   # Hardhat test suite
│   ├── DutchAuction/       # Dutch Auction tests (14 test files)
│   ├── SecureLBP/          # SecureLBP tests (11 test files)
│   ├── TokenVestingEscrow/ # Vesting tests (5 test files)
│   ├── PresaleManager/     # Manager tests
│   ├── PublicPresaleFactory/ # PublicPresaleFactory tests
│   ├── Scenarios/          # Integration scenario tests
│   ├── test-WeightedAMM/   # WeightedAMM unit tests
│   └── utils/              # Test utilities and fixtures
│
├── artifacts/              # Compiled contract artifacts (generated)
├── cache/                  # Hardhat compilation cache (generated)
├── coverage/               # Test coverage reports (generated)
├── typechain-types/        # TypeScript types (generated)
├── hardhat.config.ts       # Hardhat configuration
├── tsconfig.json           # TypeScript configuration
└── package.json
```

### Key Directories

**`contracts/core/`** - Core protocol contracts implementing the three main mechanisms:
- **`auction/`**: Commit-reveal Dutch Auction with Merkle whitelisting, early participant bonuses, and dynamic reserve adjustments
- **`lbp/`**: SecureLBP and WeightedAMM for post-auction liquidity bootstrapping with time-based weight schedules
- **`vesting/`**: Token vesting escrow with configurable cliff periods and linear unlock schedules

**`contracts/manager/`** - Management and orchestration layer:
- **`PresaleManager.sol`**: Main orchestrator managing the presale lifecycle (auction → LBP → vesting)
- **`PublicPresaleFactory.sol`**: Permissionless factory enabling users to create presales without approval
- **`AuctionFactory.sol`**: Factory pattern for deploying auction contracts
- **`UpkeepController.sol`**: Chainlink Automation integration for time-based operations

**`contracts/oracle/`** - External data integration:
- **`LBPOracle.sol`**: Adaptive fee calculation and pause mechanism based on price divergence and volatility

**`contracts/libraries/`** - Reusable mathematical and cryptographic utilities:
- **`CommitLib.sol`**: Merkle proof verification and commit hash calculations
- **`PriceTickLib.sol`**: Price tick indexing and conversion utilities
- **`ReserveDecayLib.sol`**: Reserve decay formula implementations
- **`VestingMath.sol`**: Vesting schedule calculations

**`contracts/interfaces/`** - Contract interface definitions for type safety and interoperability

**`contracts/mocks/`** - Mock contracts for testing external dependencies (tokens, price feeds, etc.)

**`contracts/test-attacks/`** - Malicious contracts used in security tests to verify reentrancy protection and edge case handling

**`scripts/`** - Deployment and utility scripts:
- **`deployAll.ts`**: Comprehensive deployment script that deploys all contracts, saves ABIs and addresses, and configures the system
- **`generateWhitelistMerkle.ts`**: Generates Merkle tree from address list for whitelisting
- **`uploadToIPFS.ts`**: Uploads JSON files to IPFS and returns CIDs
- **`computeBonusAllocations.ts`**: Computes bonus allocations for early participants after auction finalization

**`test/`** - Comprehensive test suite:
- Organized by contract/module with numbered test files following execution order
- **`Scenarios/`**: End-to-end integration tests covering full presale lifecycle
- **`utils/`**: Shared test fixtures and utilities for contract deployment and setup

**`artifacts/`** - Generated by Hardhat during compilation; contains compiled contract bytecode and ABIs

**`typechain-types/`** - Generated TypeScript type definitions for type-safe contract interactions in tests and scripts

## Running the tests

```shell
npm install
npx hardhat test

# Run specific test suites
npm run test:securelbp      # SecureLBP tests
npm run test:weightedamm    # WeightedAMM tests
npm run test:dutchauction   # DutchAuction tests
npm run test:presalemanager # PresaleManager tests
npm run test:publicpresalefactory # PublicPresaleFactory tests
npm run test:lbp            # LBP tests
npm run test:vesting        # Vesting tests

npm run test:scenarios      # Scenario tests

