# Basic Script Troubleshooting:

- **Pre-flight**
	- GUI suddenly disappeared
		- you might have entered an invalid character, revert to launch.
	- ***While Invoking function...*** terminal error
		- the nametags are setup wrong

- **Ascent and Gravity Turn**
	- *no bugs found yet*
	
- **MECO and Booster Separation**
	- Booster is out of control on separation
		- make sure the stage 2 engine doesn't "kick" the booster stage

- **Flip and Boostback**
	- Booster lost control on flip
		- do not timewarp
	- Booster overshooting
		- do not timewarp

- **Re-entry and Atmospheric Guidance**
	- Atmosphere guidance not guiding booster properly
		- your IPU config might be too low, script is tested at minimum of 1000 IPU
		- do not timewarp

- **Landing Burn**
	- Booster is coming in too hot
		- the computers will attempt a 1-3-1 engine sequence if coming in faster than expected. if this failed, contact dev.
