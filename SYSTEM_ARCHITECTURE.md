# Verdant System Architecture

## Core Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            External Systems                             │
│                                                                         │
│  ┌───────────────┐         ┌───────────────┐      ┌──────────────────┐  │
│  │   Uniswap V2  │         │ Verdant Token │      │   Player Wallet  │  │
│  │ Liquidity Pair│◄────────┤    (ERC-20)   │◄─────┤                  │  │
│  └───────┬───────┘         └───────┬───────┘      └────────┬─────────┘  │
└──────────┼─────────────────────────┼───────────────────────┼────────────┘
           │                         │                       │
           │                         │                       │
           ▼                         ▼                       ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                               Smart Contracts                              │
│                                                                            │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                        StorageCore (UUPS Upgradeable)              │    │
│  │                                                                    │    │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌──────────────────────┐  │    │
│  │  │    Data Types   │ │  Player Assets  │ │  Economic Parameters │  │    │
│  │  │                 │ │                 │ │                      │  │    │
│  │  │ - Miner         │ │ - playerMiners  │ │ - bloomRate          │  │    │
│  │  │ - MinerType     │ │ - playerItems   │ │ - verditeRate        │  │    │
│  │  │ - GiftMiner     │ │ - playerGiftMiners│ │ - taxPercentage    │  │    │
│  │  │ - Item          │ │ - playerGiftItems│ │ - referralPercentage│  │    │
│  │  │ - ItemType      │ │ - bloomBalances │ └──────────────────────┘  │    │
│  │  │ - GiftItem      │ │ - verditeBalances│                          │    │
│  │  └─────────────────┘ │ - referrers     │                           │    │
│  │                      │ - referralCount │                           │    │
│  │                      └─────────────────┘                           │    │
│  │                                                                    │    │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌──────────────────────┐  │    │
│  │  │  Miner Methods  │ │  Item Methods   │ │  Currency Methods    │  │    │
│  │  │                 │ │                 │ │                      │  │    │
│  │  │ - createMiner   │ │ - createItem    │ │ - updateBloomBalance │  │    │
│  │  │ - replaceMiner  │ │ - updateItemQuantity │ - updateVerditeBalance│   │
│  │  │ - updateMiner*  │ │ - removeItem    │ │ - receiveVerdant     │  │    │
│  │  │ - createGiftMiner││ - createGiftItem│ │ - sendVerdant        │  │    │
│  │  └─────────────────┘ └─────────────────┘ └──────────────────────┘  │    │
│  │                                                                    │    │
│  └───────────────┬────────────────────┬─────────────────────┬─────────┘    │
│                  │                    │                     │              │
│                  ▼                    │                     ▼              │
│   ┌──────────────────────────┐        │         ┌────────────────────────┐ │
│   │        MinerLogic        │        │         │       ItemLogic        │ │
│   │                          │        │         │                        │ │
│   │  ┌────────────────────┐  │        │         │ ┌─────────────────────┐│ │  
│   │  │    Game Constants  │  │        │         │ │  Game Constants     ││ │  
│   │  │ - MAINTENANCE_WINDOW  │        │         │ │ - GRACE_PERIOD      ││ │  
│   │  │ - Rarity Constants │  │        │         │ │ - Rarity Constants  ││ │
│   │  │ - Miner Constants  │  │        │         │ │ - Item Constants    ││ │
│   │  │ - Reward Divisors  │  │        │         │ │ - Slot Constants    ││ │
│   │  │ - calculateRewards │  │        │         │ │ - calculateItemCost ││ │
│   │  │ - calculateMinerLives │ ◄──────┘         │ │ - findItemSlot      ││ │
│   │  │ - calculateAvailableSlots                │ └─────────────────────┘│ │
│   │  └────────────────────┘  │                  │                        │ │
│   │                          │                  │                        │ │
│   │  ┌────────────────────┐  │                  │ ┌───────────────────┐  │ │
│   │  │   Miner Actions    │  │                  │ │   Item Actions    │  │ │
│   │  │ - purchaseMiner    │  │                  │ │ - purchaseItem    │  │ │
│   │  │ - claimRewards     │  │                  │ │ - useExpansionSlot│  │ │
│   │  │ - maintainMiner    │  │                  │ │ - useBomb         │  │ │
│   │  │ - claimGiftMiner   │  │                  │ │ - useShield       │  │ │
│   │  │ - refineVerdite    │  │                  │ │ - useRestore      │  │ │
│   │  │ - purchaseBloom    │  │                  │ │ - useRevive       │  │ │
│   │  │ - useMorph         │  │                  │ │ - claimGiftItem   │  │ │
│   │  └────────────────────┘  │                  │ │ - useMorph        │  │ │
│   │                          │                  │ │ - claimGiftItem   │  │ │
│   └──────────────────────────┘                  └────────────────────────┘ │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                             Player Interface                             │
│                                                                          │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────────┐  │
│  │  Miner Actions │  │  Item Actions  │  │     Currency Management    │  │
│  │                │  │                │  │                            │  │
│  │ - Buy Miners   │  │ - Buy Items    │  │ - Purchase Bloom           │  │
│  │ - Claim Rewards│  │ - Use Items    │  │ - Refine Verdite           │  │
│  │ - Maintenance  │  │ - Gift Claims  │  │ - View Balances            │  │
│  └────────────────┘  └────────────────┘  └────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

## System Components

### 1. Smart Contracts

#### StorageCore.sol
The central data repository that implements the UUPS (Universal Upgradeable Proxy Standard) pattern to allow for upgradeability. This contract:
- Stores all game state data (miners, items, balances, etc.)
- Manages access control via roles (LOGIC_ROLE)
- Handles direct token transfers (Verdant)
- Provides data access methods for logic contracts

#### MinerLogic.sol
Contains all business logic related to miners, including:
- Miner purchase and creation
- Miner maintenance and rewards calculation
- Verdite refinement and Bloom purchase
- Gift miner claiming
- Various calculations for costs, rewards, and capacity

#### ItemLogic.sol
Contains all business logic related to items, including:
- Item purchase and creation
- Item usage effects (bombs, shields, etc.)
- Gift item claiming
- Item cost calculations

### 2. External Systems

#### Verdant Token
An ERC-20 token that:
- Serves as the primary external currency
- Can be converted to and from internal currencies (Bloom, Verdite)
- Receives tax from transactions

#### Uniswap V2 Liquidity Pair
Used for:
- Dynamic pricing of miners based on liquidity
- Market-responsive game economics

#### Player Wallet
- Stores Verdant tokens
- Interacts with the game contracts
- Used for authentication

## Data Flow

1. **Player Actions**:
   - Players interact with MinerLogic and ItemLogic contracts
   - Logic contracts validate game rules and player permissions
   - Logic contracts call StorageCore to update state

2. **Currency Flow**:
   - External: Verdant tokens (ERC-20)
   - Internal: Bloom and Verdite (tracked in StorageCore)
   - Conversions: Verdant ⟷ Bloom ⟷ Verdite with applicable tax

3. **Reward Generation**:
   - Miners generate Verdite rewards over time
   - Players claim rewards through MinerLogic
   - Rewards are stored in StorageCore until claimed

4. **Item Usage**:
   - Items affect miners (shields, lives, etc.)
   - ItemLogic applies effects and consumes items
   - StorageCore updates miner and item state

## Security Architecture

1. **Access Control**:
   - StorageCore implements AccessControlUpgradeable
   - LOGIC_ROLE granted to logic contracts
   - Owner role for administrative functions

2. **Upgradeability**:
   - UUPS pattern ensures contracts can be upgraded
   - Only owner can authorize upgrades

3. **Economic Safeguards**:
   - Tax mechanism for Verdant transactions
   - Dynamic pricing based on liquidity
   - Grace periods for miners after attacks

## Game Loop

1. Players purchase miners using Bloom
2. Miners generate Verdite rewards over time
3. Players maintain miners to prevent life loss
4. Players use items to enhance miners or attack others
5. Players refine Verdite into Verdant tokens
6. The cycle continues with purchasing more miners/items

## Key Smart Contract Interactions

- **MinerLogic ⟷ StorageCore**: MinerLogic calls StorageCore for all miner data and updates
- **ItemLogic ⟷ StorageCore**: ItemLogic calls StorageCore for all item data and updates
- **ItemLogic ⟷ MinerLogic**: ItemLogic uses MinerLogic to calculate costs and miner states
- **StorageCore ⟷ Verdant Token**: StorageCore transfers Verdant tokens for purchases and refinement 