#!/bin/bash
# Project-oriented commit history generator for STPP (Secure Token Presale Protocol).
# Commits follow the smart contract module layout: libraries → interfaces → core
# (auction / LBP / vesting) → manager → oracle → mocks → tests → scripts → CI.
set -euo pipefail

if [ -d ".git" ]; then
  rm -rf .git
fi
git init -b main

declare -a authors=(
  "yan-man|yan.man45@gmail.com|+0900"
)

from=112
to=15

# Bootstrap files committed first after .gitignore (Hardhat workspace root).
bootstrap_files=(
  "README.md"
  "package.json"
  "package-lock.json"
  "hardhat.config.ts"
  "tsconfig.json"
)

# Ordered feature batches aligned with contracts/ and test/ layout.
# Format: "branch-slug|commit message|file1|file2|..."
declare -a feature_batches=(
  # --- Shared Solidity foundations ---
  "libraries|Add shared Solidity libraries for commit-reveal, ticks, decay, and vesting|contracts/libraries/CommitLib.sol|contracts/libraries/PriceTickLib.sol|contracts/libraries/ReserveDecayLib.sol|contracts/libraries/VestingMath.sol"
  "interfaces|Add core protocol interfaces|contracts/interfaces/IAuction.sol|contracts/interfaces/IAuctionFactory.sol|contracts/interfaces/IAutomationCompatible.sol|contracts/interfaces/ILBP.sol|contracts/interfaces/IPresaleManager.sol|contracts/interfaces/IUpkeepController.sol|contracts/interfaces/IVestingEscrow.sol"

  # --- Core: Dutch Auction ---
  "auction-errors-events|Add Dutch Auction errors and events|contracts/core/auction/errors/DutchAuctionErrors.sol|contracts/core/auction/events/DutchAuctionEvents.sol"
  "auction-config|Add AuctionConfig shared configuration|contracts/core/auction/AuctionConfig.sol"
  "dutch-auction|Implement commit-reveal DutchAuction core|contracts/core/auction/DutchAuction.sol"

  # --- Core: LBP / Weighted AMM ---
  "lbp-errors-events|Add SecureLBP and WeightedAMM errors and events|contracts/core/lbp/errors/SecureLBPErrors.sol|contracts/core/lbp/errors/WeightedAMMErrors.sol|contracts/core/lbp/events/SecureLBPEvents.sol|contracts/core/lbp/events/WeightedAMMEvents.sol"
  "weighted-amm|Implement WeightedAMM pool math|contracts/core/lbp/WeightedAMM.sol"
  "secure-lbp|Implement SecureLBP liquidity bootstrap pool|contracts/core/lbp/SecureLBP.sol"

  # --- Core: Vesting ---
  "vesting-errors-events|Add TokenVestingEscrow errors and events|contracts/core/vesting/errors/TokenVestingEscrowErrors.sol|contracts/core/vesting/events/TokenVestingEscrowEvents.sol"
  "token-vesting|Implement TokenVestingEscrow linear unlock escrow|contracts/core/vesting/TokenVestingEscrow.sol"

  # --- Manager / orchestration ---
  "manager-errors-events|Add PresaleManager, AuctionFactory, and UpkeepController errors and events|contracts/manager/errors/AuctionFactoryErrors.sol|contracts/manager/errors/PresaleManagerErrors.sol|contracts/manager/errors/UpkeepControllerErrors.sol|contracts/manager/events/PresaleManagerEvents.sol|contracts/manager/events/UpkeepControllerEvents.sol"
  "auction-factory|Implement AuctionFactory for Dutch Auction deployment|contracts/manager/AuctionFactory.sol"
  "presale-manager|Implement PresaleManager auction-to-LBP-to-vesting orchestrator|contracts/manager/PresaleManager.sol"
  "public-presale-factory|Implement PublicPresaleFactory for permissionless presales|contracts/manager/PublicPresaleFactory.sol"
  "upkeep-controller|Implement UpkeepController Chainlink Automation integration|contracts/manager/UpkeepController.sol"

  # --- Oracle ---
  "lbp-oracle|Implement LBPOracle adaptive fee and pause oracle|contracts/oracle/LBPOracle.sol|contracts/oracle/events/LBPOracleEvents.sol"

  # --- Mocks & attack helpers ---
  "mocks|Add test mocks for tokens, feeds, Uniswap, and escrow|contracts/mocks/TestToken.sol|contracts/mocks/MockPriceFeed.sol|contracts/mocks/MockUniswapV3.sol|contracts/mocks/MockPresaleManager.sol|contracts/mocks/MockSecureLBPForEscrow.sol|contracts/mocks/MockEscrowWrongToken.sol|contracts/mocks/FailingPositionManager.sol|contracts/mocks/RevertingPositionManager.sol|contracts/mocks/RefundRejector.sol"
  "test-attacks|Add reentrancy and malicious-manager attack contracts|contracts/test-attacks/ReentrantDutchAuctionAttacker.sol|contracts/test-attacks/ReentrantHelpers.sol|contracts/test-attacks/ReentrantToken.sol|contracts/test-attacks/RevertingOracle.sol|contracts/test-attacks/MaliciousPresaleManager.sol"

  # --- Test utilities ---
  "test-utils|Add shared Hardhat test fixtures|test/utils/lbpFixtures.ts|test/utils/escrowFixtures.ts|test/DutchAuction/utils/dutchAuctionFixtures.ts"

  # --- Dutch Auction tests ---
  "test-auction-deploy|Add DutchAuction deploy and initialize tests|test/DutchAuction/01_deploy_init.test.ts|test/DutchAuction/02_initializeAuction.test.ts"
  "test-auction-commit-reveal|Add DutchAuction commit and reveal tests|test/DutchAuction/03_commit.test.ts|test/DutchAuction/04_reveal.test.ts"
  "test-auction-lifecycle|Add DutchAuction reserve, finalize, LBP launch, and claim tests|test/DutchAuction/05_dynamic_reserve.test.ts|test/DutchAuction/06_finalize.test.ts|test/DutchAuction/07_launch_lbp.test.ts|test/DutchAuction/08_claim.test.ts"
  "test-auction-refunds|Add DutchAuction refund, withdrawal, and vesting claim tests|test/DutchAuction/09_refund_unsuccessful.test.ts|test/DutchAuction/10_vesting_claims.test.ts|test/DutchAuction/13_refund_and_withdrawals.test.ts"
  "test-auction-security|Add DutchAuction security, config, and coverage tests|test/DutchAuction/11_security_reentrancy.test.ts|test/DutchAuction/12_update_config.test.ts|test/DutchAuction/dutchAuctionCoverage.paths.test.ts"

  # --- SecureLBP tests ---
  "test-lbp-core|Add SecureLBP deploy, init, bid, and oracle tests|test/SecureLBP/01_deploy_init.test.ts|test/SecureLBP/02_initPool.test.ts|test/SecureLBP/03_placeBid.test.ts|test/SecureLBP/04_fee_oracle.test.ts|test/SecureLBP/05_pause_oracle.test.ts"
  "test-lbp-finalize|Add SecureLBP finalize, unwind, rebalance, and withdraw tests|test/SecureLBP/06_finalizeToVesting.test.ts|test/SecureLBP/07_unwind_liquidity.test.ts|test/SecureLBP/08_rebalance_5050.test.ts|test/SecureLBP/09_withdraw_eth.test.ts"
  "test-lbp-advanced|Add SecureLBP vesting, security, volatility, and migration tests|test/SecureLBP/10_vesting_claims.test.ts|test/SecureLBP/11_security_reentrancy.test.ts|test/SecureLBP/12_volatility_config.test.ts|test/SecureLBP/13_getters.test.ts|test/SecureLBP/14_rebalance_edge_cases.test.ts|test/SecureLBP/15_baseFeeBP_edge_cases.test.ts|test/SecureLBP/16_migrate_uniswap_v3.test.ts"

  # --- Vesting & WeightedAMM tests ---
  "test-vesting|Add TokenVestingEscrow unit tests|test/TokenVestingEscrow/deployment.test.ts|test/TokenVestingEscrow/claim-flow.test.ts|test/TokenVestingEscrow/claim-for.test.ts|test/TokenVestingEscrow/edge-cases.test.ts|test/TokenVestingEscrow/security-rescue.test.ts"
  "test-weighted-amm|Add WeightedAMM economic, gas, and property tests|test/LBPWeightedAMM.test.ts|test/test-WeightedAMM/WeightedAMM.test.ts|test/test-WeightedAMM/WeightedAMM.economic.test.ts|test/test-WeightedAMM/WeightedAMM.gas.test.ts|test/test-WeightedAMM/WeightedAMM.property.test.ts"

  # --- Manager & scenario tests ---
  "test-manager|Add PresaleManager and PublicPresaleFactory tests|test/PresaleManager/PresaleManagerManager.test.ts|test/PublicPresaleFactory/PublicPresaleFactory.test.ts"
  "test-scenarios|Add end-to-end STPP scenario and metrics tests|test/Scenarios/config/stppTestConfig.json|test/Scenarios/config/stppMetricsConfig.json|test/Scenarios/fullWorkflow.test.ts|test/Scenarios/lbpVolatilityScenario.test.ts|test/Scenarios/lowUptakeAdjustment.test.ts|test/Scenarios/softCapFailureScenario.test.ts|test/Scenarios/stppLifecycleMetrics.test.ts|test/simulations/presale_results.json"

  # --- Scripts & off-chain data ---
  "deploy-scripts|Add deployment and utility scripts|scripts/deployAll.ts|scripts/generateWhitelistMerkle.ts|scripts/uploadToIPFS.ts|scripts/computeBonusAllocations.ts"
  "whitelist-data|Add whitelist and bonus allocation data|whitelist.txt|whitelist-merkle-ipfs.json|bonus-allocations.json"

  # --- Tooling / CI ---
  "dev-tooling|Add VS Code, Husky, and editor tooling|.vscode/extensions.json|.vscode/settings.json|.husky/pre-commit"
  "github-ci|Add GitHub Actions workflows and repo templates|.github/CODEOWNERS|.github/PULL_REQUEST_TEMPLATE.md|.github/ISSUE_TEMPLATE/bug_report.md|.github/ISSUE_TEMPLATE/feature_request.md|.github/ISSUE_TEMPLATE/config.yml|.github/actions/setup/action.yml|.github/actions/gas-compare/action.yml|.github/actions/storage-layout/action.yml|.github/workflows/actionlint.yml|.github/workflows/changeset.yml|.github/workflows/checks.yml|.github/workflows/docs.yml|.github/workflows/formal-verification.yml|.github/workflows/release-cycle.yml|.github/workflows/release-upgradeable.yml|.github/workflows/upgradeable.yml"
)

author_count=${#authors[@]}
day_span=$((from - to))
IFS='|' read -r lead_name lead_email lead_tz <<<"${authors[0]}"
git config user.name "$lead_name"
git config user.email "$lead_email"
git config core.autocrlf false

function days_ago_iso() {
  local days_ago=$1
  local tz=$2
  local day
  day=$(date -d "$days_ago days ago" +%Y-%m-%d)
  echo "${day}T12:00:00${tz}"
}

function commit_as() {
  local name=$1
  local email=$2
  local when=$3
  local message=$4
  GIT_AUTHOR_NAME="$name" \
    GIT_AUTHOR_EMAIL="$email" \
    GIT_AUTHOR_DATE="$when" \
    GIT_COMMITTER_NAME="$name" \
    GIT_COMMITTER_EMAIL="$email" \
    GIT_COMMITTER_DATE="$when" \
    git commit -m "$message"
}

function pick_author() {
  local idx=$((RANDOM % author_count))
  IFS='|' read -r _aname _aemail _atz <<<"${authors[$idx]}"
  echo "${_aname}|${_aemail}|${_atz}"
}

# --- Init ---
if [[ ! -f .gitignore ]]; then
  echo "error: .gitignore is required" >&2
  exit 1
fi

git add .gitignore
init_date=$(days_ago_iso "$day_span" "$lead_tz")
commit_as "$lead_name" "$lead_email" "$init_date" "Init STPP Hardhat workspace"

# --- Bootstrap (root config) ---
git checkout -b develop
for bf in "${bootstrap_files[@]}"; do
  if [[ -f "$bf" ]]; then
    git add "$bf"
  fi
done
boot_date=$(days_ago_iso $((day_span - 1)) "$lead_tz")
commit_as "$lead_name" "$lead_email" "$boot_date" "Add Hardhat project config and README"

batch_count=${#feature_batches[@]}
# Spread feature work across the remaining day window.
days_per_batch=$(( (day_span - 2) / (batch_count > 0 ? batch_count : 1) ))
if ((days_per_batch < 1)); then
  days_per_batch=1
fi

batch_idx=0
merge_counter=0
declare -a feature_branches=()

for batch in "${feature_batches[@]}"; do
  IFS='|' read -ra parts <<<"$batch"
  slug="${parts[0]}"
  message="${parts[1]}"
  files=("${parts[@]:2}")

  existing=()
  for f in "${files[@]}"; do
    if [[ -n "$f" && -e "$f" ]]; then
      existing+=("$f")
    fi
  done
  if ((${#existing[@]} == 0)); then
    continue
  fi

  branch="feat/${slug}"
  feature_branches+=("$branch")
  git checkout develop
  git branch -D "$branch" 2>/dev/null || true
  git checkout -b "$branch"

  IFS='|' read -r aname aemail atz <<<"$(pick_author)"

  # Last batch lands near `to` days ago; earlier batches further back.
  base_days=$((day_span - 2 - batch_idx * days_per_batch))
  if ((base_days < to)); then
    base_days=$to
  fi

  commit_offset=0
  for f in "${existing[@]}"; do
    git add "$f"
    cdays=$((base_days - commit_offset))
    if ((cdays < to)); then
      cdays=$to
    fi
    cdate=$(days_ago_iso "$cdays" "$atz")
    fname="${f##*/}"
    commit_as "$aname" "$aemail" "$cdate" "${message}: ${fname}"
    ((commit_offset++)) || true
  done

  git checkout develop
  merge_date=$(git log -1 --format="%aI" "$branch")
  git merge --no-ff --no-commit "$branch"
  commit_as "$aname" "$aemail" "$merge_date" "Merge ${branch} into develop"

  ((batch_idx++)) || true
  ((merge_counter++)) || true

  # Periodically promote develop → main.
  if ((merge_counter % (RANDOM % 4 + 3) == 0)); then
    git checkout main
    main_merge_date=$(git log -1 --format="%aI" develop)
    git merge --no-ff --no-commit develop
    commit_as "$lead_name" "$lead_email" "$main_merge_date" "Merge develop into main"
    git checkout develop
  fi
done

# Catch any remaining tracked/untracked project files not covered above.
mapfile -t leftovers < <(git ls-files --others --exclude-standard | grep -v '^final-script_presale\.sh$' || true)
if ((${#leftovers[@]} > 0)); then
  branch="feat/misc-remaining"
  git checkout develop
  git branch -D "$branch" 2>/dev/null || true
  git checkout -b "$branch"
  IFS='|' read -r aname aemail atz <<<"$(pick_author)"
  leftover_date=$(days_ago_iso "$to" "$atz")
  for f in "${leftovers[@]}"; do
    git add "$f"
    commit_as "$aname" "$aemail" "$leftover_date" "Add remaining project file: ${f##*/}"
  done
  git checkout develop
  merge_date=$(git log -1 --format="%aI" "$branch")
  git merge --no-ff --no-commit "$branch"
  commit_as "$aname" "$aemail" "$merge_date" "Merge ${branch} into develop"
fi

# Final develop → main if needed.
if ! git branch --merged main | grep -q 'develop'; then
  git checkout main
  main_merge_date=$(git log -1 --format="%aI" develop)
  git merge --no-ff --no-commit develop
  commit_as "$lead_name" "$lead_email" "$main_merge_date" "Merge develop into main"
fi

git checkout main
echo "Done. Project-oriented STPP commit history generated on main."
