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
 - **Docking**
	- When using a docking port, make sure to change its nametag to **"APAS"**.
	
 # Action Groups:
- 1 - Toggle engine modes
- 2 - Soot shaders
- 3 - Strongback retract
- 4 - Rodan Shroud
- 5 - Trunk Decouple
	
 # What's new!

 - **(0.8.0)** Reworked ASDS mode! New de-orbit script for Gigan and Rodan.

 # Disclaimer:
 - Before using this script, you must have prior knowledge of kOS in order for you to use this script
 properly. The systems largely differ in each and every craft (different mods, setup, etc.) so you must 
 know how to tune PIDs and such to your own likings.
 - De-orbit script is heavily hard-coded, proceed with caution. For better results, make sure plane difference is less than five degrees.
 - ASDS profile works best when used on equatorial launches.

 # Known Bugs:
 - None ATM.
	
 # Planned:
 - (soonTM)..
