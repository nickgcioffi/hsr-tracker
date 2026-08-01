# HSR Tracker

Turn daily habits and workouts into Honkai: Star Rail gacha pulls.

## Concept

- **Dailies** (bed, scripture, prayer, cleaning) → small jade income
- **Workout tiers** (walk → beast mode) → pull currency + relic quality
- External, visible progress as a motivation aid — earn pulls by doing the thing, not by feeling like doing the thing.


## Tech

- SwiftUI + SwiftData
- iOS (macOS support via NavigationSplitView wrapper, untested)

## Roadmap

1. Establish a simple iOS UI, white screen or otherwise 
2. Add a checklist to plan for characters and sets (v0.2.0)
3. Introduce a database of all characters and relic sets into the app so that it is easy to choose your sets. No need for images yet. Use community made jsons to get records. (v0.3.0)
4. New tab: add a system to count jades based on checking a box. (v0.4.0)
5. Iterate on the jade system, and have a dailies system, with notifications, and a daily reset at midnight. (v0.5.0)
6. Add a cute little dynamic island activity/live activity to show your current jade count and dailies remaining. Goes away after finishing all dailies. (v0.6.0)
7. Integrate Healthkit. Use workouts as a basis of jade claims, and use recorded effort to give bonuses. (v0.7.0)
8. Introduce a relic system, granting the ability to choose how many relics you can add to a character. Redeemable from how many workouts or dailies you've completed. (v0.8.0)
9. Polishing (v0.9.0)
10. Add a pull system directly into the app, while granting yourself the ability to import your own data from your account to give you a better scope. (v1.0)
 
