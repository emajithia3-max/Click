# Click - Season 1 Configuration Guide

This document lists all tunable parameters for Click Season 1. Most values are controlled via Firebase Remote Config, with local defaults in `RemoteConfigDefaults.plist`.

---

## Season Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `season_active_id` | String | `"season_1"` | Current active season identifier |
| `season_name` | String | `"Season 1"` | Display name for the current season |
| `season_end_utc` | Double | Unix timestamp | Season end date (4 weeks from start) |
| `whats_new_text` | String | See below | What's new message for season |

**Default whats_new_text:** `"Season 1 begins — ranks reset, fresh boosts, smoother progression."`

---

## Rank & Progression

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `rank_growth_a` | Double | `500` | Base tap threshold for Tier 1 V |
| `rank_growth_b` | Double | `1.22` | Exponential growth per rank (1.22 = 22% increase per rank) |
| `prestige_growth_a` | Double | `1.35` | Prestige multiplier compounding factor |

### Rank Threshold Formula
```
threshold(rankIndex) = rank_growth_a * (rank_growth_b ^ (rankIndex - 1))
```

### Season Base Multiplier Formula
```
rankBonus = 1.0 + ((rankIndex - 1) * 0.02)
prestigeBonus = prestige_growth_a ^ prestigeCount
seasonBaseMultiplier = rankBonus * prestigeBonus
```

### Prestige Threshold Easing
Each prestige reduces rank thresholds by 8%:
```
adjustedThreshold = baseThreshold * (0.92 ^ prestigeCount)
```

---

## Economy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `base_tap` | Double | `1` | Base value per tap |
| `click_multiplier_per_level` | Double | `0.10` | +10% tap value per upgrade level |
| `offline_multiplier_per_level` | Double | `0.20` | +20% offline rate per upgrade level |
| `milestone_coins_base` | Double | `10` | Base coins for milestone rewards |
| `rank_up_coins_base` | Double | `50` | Base coins for rank-up (multiplied by rank index) |

### Tap Value Formula
```
tapValue = baseTap * clickMultiplier * seasonBaseMultiplier * temporaryBoostMultiplier
```
Where `clickMultiplier = 1.0 + (click_multiplier_per_level * (level - 1))`

---

## Offline Earnings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `offline_hours_cap` | Double | `8` | Maximum hours of offline accumulation |
| `base_offline_rate` | Double | `10` | Base coins per hour while offline |

### Offline Earnings Formula
```
offlineCoins = min(offlineRate * elapsedHours, offlineRate * offline_hours_cap)
offlineRate = base_offline_rate * offlineMultiplier * seasonBaseMultiplier
```

---

## Boosts & Power-Ups

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `ad_rush_duration` | Double | `30` | Ad Rush duration in seconds |
| `ad_rush_multiplier` | Double | `2.0` | Ad Rush tap multiplier |
| `ad_rush_cooldown` | Double | `120` | Ad Rush cooldown in seconds |
| `overclock_duration` | Double | `15` | Overclock duration in seconds |
| `overclock_multiplier` | Double | `5.0` | Overclock tap multiplier |
| `overclock_cooldown` | Double | `300` | Overclock cooldown in seconds |

---

## Ads Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `admob_rewarded_enabled` | Bool | `true` | Enable/disable rewarded ads |
| `rewarded_cooldown_seconds` | Double | `120` | Global cooldown between rewarded ads |

### AdMob Test IDs (Built-in)
| Ad Type | Test Unit ID |
|---------|--------------|
| Rewarded | `ca-app-pub-3940256099942544/1712485313` |
| Banner | `ca-app-pub-3940256099942544/2934735716` |
| App ID | `ca-app-pub-3940256099942544~1458002511` |

---

## World Rank / Leaderboard

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `world_rank_feature_enabled` | Bool | `true` | Enable World Rank feature |
| `world_rank_update_interval_ms` | Int | `5000` | Client update interval in milliseconds |

---

## Shop Pricing (Hardcoded Defaults)

### Click Multiplier
| Level | Price |
|-------|-------|
| 1→2 | 50 |
| 2→3 | 100 |
| 3→4 | 200 |
| 4→5 | 400 |
| ... | × 2.0 per level |

### Offline Multiplier
| Level | Price |
|-------|-------|
| 1→2 | 100 |
| 2→3 | 220 |
| 3→4 | 484 |
| ... | × 2.2 per level |

### Overclock Pack
- **Price:** 500 coins (fixed)
- **Effect:** x5 taps for 15 seconds

---

## Tier Colors

| Tier | Hex Code | Description |
|------|----------|-------------|
| 1 | `#A3A3A3` | Gray |
| 2 | `#8BC6EC` | Light Blue |
| 3 | `#B08968` | Bronze |
| 4 | `#C0C0C0` | Silver |
| 5 | `#E6B422` | Gold |
| 6 | `#9AD1D4` | Teal |
| 7 | `#6EE7F0` | Cyan |
| 8 | `#7C3AED` | Purple |
| 9 | `#EF4444` | Red |
| 10 | `#22C55E` | Green |

**Glow Effect:** Tiers 6-10 have a glow effect with increasing intensity.

---

## Rank Structure

- **Total Ranks:** 50
- **Tiers:** 10 (Tier 1 through Tier 10)
- **Levels per Tier:** 5 (V, IV, III, II, I)
- **Order:** Tier 1 V (lowest) → Tier 10 I (highest)

### Example Rank Thresholds (with defaults)

| Rank | Index | Threshold |
|------|-------|-----------|
| Tier 1 V | 1 | 500 |
| Tier 1 IV | 2 | 610 |
| Tier 1 III | 3 | 744 |
| Tier 1 II | 4 | 908 |
| Tier 1 I | 5 | 1,107 |
| Tier 2 V | 6 | 1,351 |
| ... | ... | ... |
| Tier 10 I | 50 | ~2.8B |

---

## Firebase Collections

### Users Collection: `users/{uid}`
```json
{
  "displayName": "string",
  "createdAt": "timestamp",
  "lifetimeTaps": "number",
  "lifetimeBestRankIndex": "number",
  "cosmetics": ["string"],
  "leaderboardOptIn": "boolean"
}
```

### Season Data: `users/{uid}/season/{seasonId}`
```json
{
  "currentSeasonTaps": "number",
  "coins": "number",
  "clickMultiplierLevel": "number",
  "offlineMultiplierLevel": "number",
  "rankIndex": "number",
  "prestigeCount": "number",
  "seasonBaseMultiplier": "number",
  "lastActiveAt": "timestamp",
  "boostInventory": {"string": "number"},
  "adRushLastUsed": "timestamp?",
  "overclockLastUsed": "timestamp?"
}
```

### Seasons Collection: `seasons/{seasonId}`
```json
{
  "name": "string",
  "startUtc": "timestamp",
  "endUtc": "timestamp",
  "isActive": "boolean",
  "coefficients": {
    "rankGrowthA": "number",
    "rankGrowthB": "number",
    "prestigeGrowthA": "number"
  }
}
```

### Leaderboards: `leaderboards/{seasonId}`
```json
{
  "top": [
    {
      "uid": "string",
      "displayName": "string",
      "taps": "number",
      "rankIndex": "number"
    }
  ],
  "buckets": {"threshold": "count"},
  "totalPlayers": "number",
  "lastUpdated": "timestamp"
}
```

---

## Analytics Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `session_start` | - | App launch |
| `session_end` | - | App background/close |
| `tap` | (sampled) | On tap |
| `rank_up` | `rankIndex` | Player ranks up |
| `prestige` | `prestigeCountBefore` | Player prestiges |
| `shop_purchase` | `itemId` | Shop purchase |
| `rewarded_show` | - | Ad shown |
| `rewarded_complete` | - | Ad completed |
| `season_rollover` | - | Season ends |

---

## Balancing Guidelines

### Early Game (Tier 1-2)
- Players should reach Tier 1 I within first session (~30 min active play)
- First prestige available after Tier 1 V (very early)
- Prestige provides ~2x multiplier initially

### Mid Game (Tier 3-5)
- Multiple prestiges needed to progress efficiently
- 10x multiplier achievable with 2-3 prestiges
- Shop upgrades become important

### Late Game (Tier 6-10)
- Heavy prestige cycling required
- 100x+ multipliers for competitive play
- Offline earnings crucial for progression

### Anchor Points
- **First Prestige:** ~2x multiplier
- **Early T2 Transition:** ~10x with a few prestiges
- **Max Potential:** Soft-capped to keep numbers readable

---

## Implementation Checklist

### Before Release
- [ ] Replace `GoogleService-Info.plist` with production Firebase config
- [ ] Replace AdMob test IDs with production ad unit IDs
- [ ] Set production `season_end_utc` in Remote Config
- [ ] Configure Firebase Security Rules
- [ ] Set up Cloud Functions for leaderboard aggregation
- [ ] Create app icon variants per season
- [ ] Configure App Store Connect

### Remote Config Setup
1. Create parameters matching keys above
2. Set default values
3. Create conditions for A/B testing if needed
4. Publish configuration

### Firestore Indexes Required
```
Collection: leaderboardEntries/{seasonId}/entries
Fields: taps (DESC), updatedAt (DESC)

Collection: users/{uid}/seasonHistory
Fields: endDate (DESC)
```

---

## Version History

| Version | Season | Changes |
|---------|--------|---------|
| 1.0 | Season 1 | Initial release |

---

## Support

For questions about configuration:
- Review Remote Config documentation
- Check Firebase Console for active values
- Monitor Analytics for balance issues
