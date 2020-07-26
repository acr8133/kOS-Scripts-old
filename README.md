# Ghidorah 9
 Kerbal Operating System **(kOS)** scripts that's currently being used on 
 Tundra Exploration's Ghidorah launch system. The script is capable of bringing payload
 into target orbit and target inclination. It also has the capability of
 landing Ghidorah 9's first stage boosters into the target coordinates.
  **Current Version: V0.6**

 # Usage:
 - **Boot Scripts**
		Put the **AscentScript.ks** at the second stage and **RecoveryScript.ks** at the
		first stage of the rocket.
 - **Mission Parameters**
	   	Found inside the **missionParameters.ks** are some variables you can set to tune
		the rocket for your own missions. Change the numbers beside the **HighDrag()** function
		according to which strongback are you using **(quotation marks included)**. Easiest to
		change are: targetOrb **(target orbit)**, targetInc **(target inclination)**, and LZ.
 # Action Groups:
	1 - Toggle engine modes
	2 - Soot shaders
	3 - Strongback retract
	
 # Bugs:
 - maybe unstable because vectors are still not normalized
	
 # Planned:
- Telemetry on terminal window.
- Automatic Crew Abort System.
- Automatic Flight Termination System (AFTS).
- Add launch window function.
- Automatic rendezvous and docking for Rodan.
- GUI for mission profiles	
- Droneship landings??	
- (soonTM)..