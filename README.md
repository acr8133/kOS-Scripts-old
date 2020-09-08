 # Ghidorah 9
 Kerbal Operating System **(kOS)** scripts that's currently being used on 
 Tundra Exploration's Ghidorah launch system. The script is capable of bringing payload
 into target orbit and target inclination. It also has the capability of
 landing Ghidorah 9's first stage boosters into the target coordinates.

 # Usage:
 - **Boot Scripts**
	- Put the **AscentScript.ks** at the second stage and **RecoveryScript.ks** at the
	first stage of the rocket.
 - **Mission Parameters**
	- Found inside the **missionParameters.ks** are variables you can set to tune
	the rocket for your own missions. You can refer to the instructions inside the **missionParameters.ks** for tuning the script to your own KSP missions.
    - You can set a **target** on the first line of the file. It will override the set target inclination, with the current target inclination.
	
 # Action Groups:
- 1 - Toggle engine modes
- 2 - Soot shaders
- 3 - Strongback retract
- 4 - Rodan Shroud
	
 # What's new!

 - **(0.7.7)** Addded abort system, RTLS trajectory rebalance, and new drag force function.
 - **(0.7.4)** Fixed RollAlign bug, fixed stuck throttle stick, code formatting change.
 - **(0.7.3)** ASDS and Full Expended mode *(early experimental)*.
 - **(0.7.3)** Reworked some parts of the docking script.
 - **(0.7.1)** New rendezvous and docking sequence for Gigan and Rodan.
 - **(0.7.0)** Instantaneous launch window timing.

 # Disclaimer:
 - Before using this script, you must have prior knowledge of kOS in order for you to use this script
 properly. The systems largely differ in each and every craft (different mods, setup, etc.) so you must 
 know how to tune PIDs and such to your own likings.

 # Known Bugs:
 - ASDS mode will get a huge makeover.
	
 # Planned:
 - New RTLS-ish ASDS mode, for easier gameplay. (No need to reposition droneships on each mission)
 - Re-entry Guidance Computer for Gigan and Rodan. (Land near the KSC)
 - *~~Automatic Flight Termination System (AFTS)~~* **No Longer Planned!**.
 - GUI for mission profiles	
 - (soonTM)..
