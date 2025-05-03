# Verdant: Game Mechanics Description

Verdant is a blockchain-based game where players manage miners and items to accumulate rewards and enhance their gameplay. Players maintain inventories of miners, items, and currencies, engage in a referral system, and interact with a gifting mechanism. Miners generate rewards, while items provide strategic effects to boost or hinder miners. The game features four tiers—Promotional, Common, Rare, and Mythic—with miners and items (except for the Promotional tier, which has no items), offering strategic depth and engaging inventory management.

## Players

Players are the participants in Verdant, each with an inventory comprising:

- **Miner Bag**: Owned miners (active and usable) and gifted miners (pending claim).
- **Item Bag**: Owned items (usable) and gifted items (pending claim).
- **Currencies**: Verdant (an ERC-20 token), Bloom, and Verdite (internal currencies).
- **Referrer**: The player who referred them, earning rewards from their purchases.
- **Referral Count**: The number of players they have referred.

## Miners

Miners are entities that generate Verdite rewards over time. Verdant starts with four miner types, each tied to a specific tier:

- **Starter (Promotional)**:
  - Rewards Rate: ~2,083.33 Verdite/day (based on 50,000 Bloom cost).
  - Rewards Capacity: ~1,388.89 Verdite.
  - Maintenance Cost: ~291.67 Bloom/week.
- **Basic (Common)**:
  - Rewards Rate: ~27,777.78 Verdite/day (based on 500,000 Bloom cost).
  - Rewards Capacity: ~13,888.89 Verdite.
  - Maintenance Cost: ~3,888.89 Bloom/week.
- **Advanced (Rare)**:
  - Rewards Rate: ~416,666.67 Verdite/day (based on 5,000,000 Bloom cost).
  - Rewards Capacity: ~166,666.67 Verdite.
  - Maintenance Cost: ~58,333.33 Bloom/week.
- **Elite (Mythic)**:
  - Rewards Rate: ~8,333,333.33 Verdite/day (based on 50,000,000 Bloom cost).
  - Rewards Capacity: ~2,777,777.78 Verdite.
  - Maintenance Cost: ~1,166,666.67 Bloom/week.

All miners share:

- **Lives**: Maximum of 2.
- **Shields**: Start with 2, with a capacity of 4.
- **Maintenance Window**: 7 days.

### Miner Mechanics

- **Rewards**: Miners accumulate Verdite at their rewards rate until reaching their rewards capacity. Players can claim rewards for a single miner or multiple miners at once. Rewards rates are calculated as:
  - Starter: (Cost in Bloom * 5) / 180.
  - Basic: (Cost in Bloom * 5) / 90.
  - Advanced: (Cost in Bloom * 5) / 60.
  - Elite: (Cost in Bloom * 5) / 30.
  - (Conversion: 1 Bloom = 1 Verdite, as 1,000 Bloom = 1 Verdant = 5,000 Verdite.)
- **Rewards Capacity**: Limits the maximum Verdite a miner can hold:
  - Starter: Daily rewards / 1.5.
  - Basic: Daily rewards / 2.
  - Advanced: Daily rewards / 2.5.
  - Elite: Daily rewards / 3.
- **Maintenance**: Players must maintain miners every 7 days using Bloom to prevent life loss. The maintenance cost is equal to the weekly rewards (Rewards Rate * 7 days) converted to Bloom (1 Verdite = 0.0002 Bloom) divided by 10, scaled linearly based on time elapsed since the last maintenance. Failure to maintain within 7 days deducts one life. If both lives are lost, the miner is **destroyed** and cannot be recovered.
- **Shields**: Shields protect miners from Bomb item attacks:
  - **MinorBomb**: Removes 1 shield.
  - **MajorBomb**: Removes 2 shields.
  - If shields reach 0, the miner becomes **disabled** (reversible via a Revive item). Disabled miners cannot generate rewards or be maintained until revived.
- **Destruction States**:
  - **Destroyed (irreversible)**: Occurs when lives reach 0 due to maintenance failure. Destroyed miners can be overwritten by new miners.
  - **Disabled (reversible)**: Occurs when shields reach 0 due to Bomb attacks. Disabled miners (shields = 0, lives > 0) can be revived or overwritten.
- **Grace Period**: After a Bomb attack that leaves shields above 0, the miner gains a 24-hour grace period during which it cannot be attacked by another Bomb.

### Miner Capacity

Players have a limited capacity for active miners, tracked by tier:

- **Default Capacity**:
  - Promotional: 3 Starter Miners.
  - Common: 5 Basic Miners.
  - Rare: 3 Advanced Miners.
  - Mythic: 1 Elite Miner.
- **Maximum Capacity** (via Expansion Slot items, except for Promotional tier):
  - Promotional: 3 Starter Miners (no Expansion Slots available).
  - Common: 20 Basic Miners.
  - Rare: 15 Advanced Miners.
  - Mythic: 10 Elite Miners.
- Capacities apply to all miners of the same tier, including future types added by the game administrator.

### Miner Acquisition

- **Purchase**: Players buy miners using Bloom, with costs dynamically scaled based on the Verdant/WETH Uniswap V2 liquidity pair:
  - Starter: CANNOT BE PURCHASED BUT IS WORTH 50,000 Bloom or 0.01% of the Verdant token supply in the pair for purposes of rewards calculation.
  - Basic: Minimum of 500,000 Bloom or 0.075% of the Verdant token supply in the pair.
  - Advanced: Minimum of 5,000,000 Bloom or 0.3% of the Verdant token supply.
  - Elite: Minimum of 50,000,000 Bloom or 1.5% of the Verdant token supply.
- **Gifting**: The game administrator can gift miners to any player, placing them in the player's gift inventory.
- **Claiming**: Players claim gifted miners to move them to their main inventory, making them usable.
- **Overwriting Logic**: If the slot capacity for a miner's tier is full (active miners equal total slots), the game searches for:
  - A **destroyed miner** (lives = 0) to replace first. The destroyed miner is completely removed and the new miner takes its place with a new ID and fresh attributes.
  - A **disabled miner** (shields = 0, lives > 0) to replace if no destroyed miner is found. The disabled miner is completely removed and the new miner takes its place with a new ID and fresh attributes.
  - If no overwritable miner exists and slots are full, the purchase, morph or gift claim fails.

## Items

Items are entities with unique IDs, stored in a player's main inventory (usable) or gift inventory (pending claim). Players track their items via `itemIDs` (main inventory) and `giftItemIDs` (gift inventory). Verdant includes items across all four rarities (Promotional, Common, Rare, Mythic):

- **Promotional (5 types)**: MinorBomb, MajorBomb, MinorShield, MajorShield, Revive.
- **Common (8 types)**: ExpansionSlot, MinorBomb, MajorBomb, MinorShield, MajorShield, Restore, Revive, Morph.
- **Rare (8 types)**: ExpansionSlot, MinorBomb, MajorBomb, MinorShield, MajorShield, Restore, Revive, Morph.
- **Mythic (8 types)**: ExpansionSlot, MinorBomb, MajorBomb, MinorShield, MajorShield, Restore, Revive, Morph.

### Item Types and Effects

Each item has a specific effect:

- **ExpansionSlot**: Increases the miner capacity for its rarity by 1 (up to maximum capacity; not applicable to Promotional tier).
- **MinorBomb**: Removes 1 shield from a miner.
- **MajorBomb**: Removes 2 shields from a miner.
- **MinorShield**: Adds 1 shield (up to the miner's shields capacity).
- **MajorShield**: Adds 2 shields (up to the miner's shields capacity).
- **Restore**: Adds 1 life (up to 2) to an active miner (shields > 0).
- **Revive**: Restores a disabled miner (shields = 0, lives > 0) to its initial shields.
- **Morph**: Upgrades a miner to the next rarity (e.g., Basic to Advanced).

### Item Mechanics

- **Rarity Restrictions**:
  - Items affect miners of matching rarity (Promotional items affect Promotional miners, Common items affect Common miners, etc.)
  - Morph items (Common, Rare, Mythic) affect miners one rarity below (Common Morph for Promotional miners, Rare Morph for Common miners, Mythic Morph for Rare miners).
- **Usage**:
  - Items are consumed upon use, removed from the player's main inventory.
  - Usage requirements:
    - **Morph**: Miner must be active (lives > 0, shields > 0).
    - **Revive**: Miner must be disabled (shields = 0, lives > 0).
    - **Other Items**: Miner must have lives > 0 (active or disabled).
  - Bomb attacks trigger a 24-hour grace period if the miner's shields remain above 0.
  - Restore cannot revive disabled or destroyed miners or exceed the 2-life limit.
- **Acquisition**:
  - Excluding Morph, which is not purchasable/has no value/is worth 0, each items price is a function.
  - It's implied for items with functions relying on "Miner Cost" that the miner is the equivalent rarity miner of the item rarity.
  - **Purchase**:
    - If the user has withdrawals but no deposits, as is the case when they are gifted miners, then the function that computes withdrawals / deposits will resolve to a fixed rate of 1.
    - **ExpansionSlot**: Miner Cost * 0.05.
    - **MinorBomb**: Miner Cost * 0.01.
    - **MajorBomb**: Miner Cost * 0.02.
    - **MinorShield**: Miner Daily Rewards * 0.1 * (1 + withdrawals / deposits).
    - **MajorShield**: Miner Daily Rewards * 0.2 * (1 + withdrawals / deposits).
    - **Restore**: Miner Cost * 0.4.
    - **Revive**: Minimum of 0.7 * Miner Cost and 0.15 * Miner Cost * (1 + withdrawals / deposits).
  - **Gifting**: The administrator can gift any item, including Morph, to any player.
  - **Claiming**: Players claim gifted items to move them to their main inventory.
- **Inventory Limits**:
  - **ExpansionSlot**: Limited by maximum capacity (20 Common, 15 Rare, 10 Mythic slots).
  - **MinorBomb, MajorBomb, MinorShield, MajorShield, Restore, Revive**: 99 each per player.
  - **Morph**: 1 per player.
  - Claiming gifted items cannot bypass these limits.

## Currencies

Verdant features three distinct currencies:

- **Verdant**: An ERC-20 token, used to acquire Bloom (1 Verdant = 1,000 Bloom).
- **Bloom**: An internal currency, used to purchase miners and items, and to pay maintenance costs.
- **Verdite**: An internal currency, earned as miner rewards, convertible to Verdant (1,000 Verdite = 0.2 Verdant, or 5,000 Verdite = 1 Verdant).

### Exchange Rates

- **Verdant to Bloom**: 1 Verdant = 1,000 Bloom.
- **Verdite to Verdant**: 5,000 Verdite = 1 Verdant.
- **Tax**: A 10% tax applies to Bloom purchases and Verdite refinement, in Verdant, with the taxed Verdant tokens sent to the Verdant ERC-20 contract.

## Referrals

- Players can designate a referrer, who earns 2.5% of their post-tax Bloom purchases (miners and items) as Bloom rewards.
- The referral count tracks how many players a player has referred.

## Inventory Management

Players manage their inventories through:

- **Main Inventory**: Contains usable miners (`minerIDs`) and items (`itemIDs`).
- **Gift Inventory**: Contains gifted miners (`giftMinerIDs`) and items (`giftItemIDs`), which must be claimed to become usable.
- **Single Actions**:
  - Claim rewards, maintain, or purchase miners.
  - Use, purchase, or claim items.
- **Bulk Actions**:
  - Claim rewards for multiple miners.
  - Maintain multiple miners.
  - Claim all gifted miners and items at once.
- **State Retrieval**:
  - View all miners' states (rewards, lives, shields, etc.).
  - View owned and gifted items (IDs, types, rarities).
- The system ensures players can manage their inventory seamlessly, with clear visibility into their miners and items.

## Administration

The game administrator has special privileges:

- **Add Miner/Item Types**: Introduce new miners or items with custom properties across all rarity tiers.
- **Gift Miners/Items**: Distribute miners or items to any player, individually or in bulk.
- **Adjust Parameters**: Modify Bloom/Verdite exchange rates, tax percentage, referral percentage, and slot capacities.

## Gifting System

- **Gifting**: The administrator can gift any miner or item to a player, placing it in their gift inventory.
- **Claiming**: Players must claim gifted miners or items to move them to their main inventory, where they become usable.
- **Restrictions**: Gifted miners/items are not usable until claimed, and claiming respects inventory limits (e.g., no more than 99 MinorBombs).

## Additional Mechanics

- **Miner Upgrades**: Morph items upgrade a miner to the next rarity, resetting shields and lives to the new type's defaults.
- **Dynamic Costs**: Miner purchase costs (except Starter) adjust based on the Verdant/WETH liquidity pair, ensuring market-responsive pricing.
- **Scalability**: The administrator can introduce new miner and item types, expanding gameplay options. 