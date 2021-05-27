# Manual:
- **Required Mods**
	- Tundra Explorations
	- kOSForAll
		- *adds kOS core to control pods directly*
	- MechJeb
		- *mechjeb removes engine spool from tundra engines*
		- *but you want the spool? don't worry, the script has pseudo spool function built into it*
- **Boot Scripts**
	- Put the boot scripts to their designated stages.
- **Mission Parameters**
	- When the rocket is loaded on the pad, a GUI will appear. Set your target parameters in the spaces, the script will try its best to put your payload into orbit.
	- If you want to dock, toggle the **Rendezvous?** button then put in your target ship's name in the space beside it.
	- **Note: Inputting invalid characters ( ex: strings instead of scalars ) in the GUI will result to script crashing.**
	- If you dont want to use the GUI, see the next section for instructions.  
- **Docking**
	- When docking, change the nametag of your port and the target's port to **"APAS"**.
- **Action Groups**
	- AG1 - Toggle engine modes
	- AG2 - Soot shaders
	- AG3 - Heavy booster engine toggles
	- AG4 - Rodan shroud
	- AG5 - Trunk decouple
- **Nametags (BOOSTER - NAMETAG - PART)**
	- Core - **VC-13B** - Interstage
	- Side Booster A - **ABooster** - Booster nosecone
	- Side Booster B - **BBooster** - Booster nosecone
- **Droneship**
	- Watch Quasy's video on how to setup ASDS landings here: https://youtu.be/nxGF1jf14Lo.
	   
# GUI:
- **Landing Profile**
	- RTLS - Return To Launch Site *( \<7t payload )*
	- ASDS - Autonomous Spaceport Drone Ship *( \<9t payload )*
	- Heavy - Dual RTLS + Core ASDS *( \<15t payload )*
	- Expend - No recovery *( >15t payload )*
- **Payload Mass (kg)**
	- The script will actually work even if payload mass is wrong. For efficient launches, set this to the correct value.
- **Target Orbit (km / deg)**
	- Only capable of circular orbits, 0° for equatorial and 90° for polar orbits, go higher for retrograde orbits.
	- Inclination will be overwritten if the ship is set to rendezvous to a target.
- **Payload Type**
	- Gigan
	- Rodan
	- Fairing *( also use this when launching Gigan XL )*
- **Rendezvous and Docking**
	- Input the target's name, if there is no ship found the script will crash.

If you instead want a GUI-less launch, rename NOGUI.**txt** to NOGUI.**ks**.

# Changelog:
- **v1.0.2**
	- \+ Added 1-3-1 engine sequence for the landing burn
	- % Fixed drag function incorrectly reading data
- **v1.0.1**
	- % Fixed a bug where the bottom of the ocean is targeted instead of the droneship
	- % Small tweak to ASDS mode
	- **v1.0.0**
	- \+ Mission parameters GUI
	- \+ Heavy config and dual booster landing capability
	- % PID rebalance
	- % Small ASDS landing rework to prepare for a bigger rework 
	- % Plane matching now happens at higher orbit to conserve Δv
	- \- Trajectories dependency
	- \- Deorbit script ( heavily hardcoded )
