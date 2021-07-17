Kerbal Operating System **(kOS)** scripts for Tundra Exploration rockets. 
The script is capable of bringing payload into target orbit and target inclination. 
It also has the capability of landing boosters into the target coordinates.
Several links are provided below.
 
# Useful Links:
- [User Manual](https://acr8133.github.io/TUNDRA-Launch-Script/manual)
- [Troubleshooting](https://acr8133.github.io/TUNDRA-Launch-Script/troubleshoot)

# My Stuff:
- [YouTube](https://www.youtube.com/channel/UCk_DBA5HwP1-caYMyhU4a5A)
- Discord: ACR#8397

# Disclaimer:
- The script is tested and balanced to work on 2.5x rescale system.
- Tested on Tundra Exploration's latest github release.

# Changelog (v2.0.0a):
- Gojira (Starship and Superheavy) launch and land capabilities.
- Adjusted landing burn trigger altitude.
- Added fail-safe conditions to landing burns.
- Custom control point Module Manager patch.
- Made it so that PIDs uses latitude and longitude vectors instead of craft faces.
- Increased orbit planning accuracy by using vectors instead of numerical equations.
- Removed launch GUI, will be re-added in the future.
- Re-added Trajectories as a dependency for landing while keeping Heavy landing capabilities.

# Known Bugs:
- Docking breaks randomly.
- Switching boosters during boostback and landing breaks the script. 
- Script broken when using full expend mode on Heavy variant.
- Gojira(SS) bellyflop maneuver can go wild sometimes.
- Gojira(SS) landing can miscalculate landing burn.
- Gojira(SS) flips a lot during orbital adjustments. 
- A lot has changed so expect unmentioned issues.

# Planned:
- Flight Manager for Reusable Stages (FMRS) compatibility.
- Easier LZ selection.
- Gojira(SS) Orbital Refuelling.
- Gojira(SS) Rendezvous and Docking.
- Gojira(SS) Duna Landing, Mun landings will also be made once Moonship(Munship?) is released from Tundra.
- Better landing guidance for Gojira(SH).
- Gojira(SH) ASDS landing mode.
- Compatibility for Kari's Starship mod.
