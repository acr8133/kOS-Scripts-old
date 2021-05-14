 # Durp9 Launch and Landing Software
 Kerbal Operating System **(kOS)** scripts for Tundra Exploration rockets. The script is capable of bringing payload into target orbit and target inclination. It also has the capability of landing Ghidorah 9's first stage and side boosters into the target coordinates.

 # Manual:
 - **Boot Scripts**
	- Put the boot scripts to their designated stages.
 - **Mission Parameters**
	- When the rocket is loaded on the pad, a GUI will appear. Set your target parameters in the spaces, the script will try its best to put your payload into orbit.
	- If you want to dock, toggle the **Rendezvous?** button then put in your target ship's name in the space beside it.
	- **Note: Inputting invalid characters ( ex: strings instead of scalars ) in the GUI will result to script crashing.**
	- If you dont want to use the GUI, see the next section for instructions.  
 - **Docking**
	- When docking, change the nametag of your port and the target's port to **"APAS"**.
	   
 # GUI:
 - **Landing Profile**
 	- RTLS - Return To Launch Site *( \<7t payload )*
 	- ASDS - Autonomous Spaceport Drone Ship *( \<9t payload )*
 	- Heavy - Dual RTLS + Core ASDS *( \<15t payload )*
 	- Expend - No recovery *( >15t payload )*
 - **Payload Mass (kg)**
 	- The script will actually work even if payload mass is wrong. For efficient launches, set this to the correct value.
 - **Target Orbit (km / deg)**
 	- Only capable of circular orbits, 0° for equatorial and 90° for polar orbits.
 	- Inclination will be overwritten if the ship is set to rendezvous to a target.
 - **Payload Type**
 	- Gigan
    - Rodan
    - Fairing *( also use this when launching Gigan XL )*
 - **Rendezvous and Docking**
 	- Input the target's name, if there is no ship found the script will crash.
 
 If you instead want a GUI-less launch, rename NOGUI.**txt** to NOGUI.**ks**.
 
 # Action Groups:
- 1 - Toggle engine modes
- 2 - Soot shaders
- 3 - Heavy booster engine toggles
- 4 - Rodan shroud
- 5 - Trunk decouple
	
 # Changelog:
 - \+ Mission parameters GUI
 - \+ Heavy config and dual booster landing capability
 - % PID rebalance
 - % Small ASDS landing rework to prepare for a bigger rework 
 - % Plane matching now happens at higher orbit to conserve Δv
 - \- Trajectories dependency
 - \- Deorbit script ( heavily hardcoded )


 # Disclaimer:
 - The script is tested and balanced to work on 2.5x rescale system.
 - ASDS profile works best in equatorial launches.
 
 # Known Bugs:
 - Circulation maneuver execution causes the second stage overstreer.
 - Drag function incorrectly reading values, will result in very high touchdown speed. *(lithobraking)*
 - Script broken when using full expend mode on Heavy variant.
	
 # Planned:
 - Yet another ASDS landing rework
 	- third rework will be made to increase landing success chance in inclined launches
 	- this is also a preparation for the Gojira rocket
 - 1-3-1 Engine landing sequence
 - Gojira ( Starship and Superheavy )