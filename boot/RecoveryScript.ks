// Ghidorah v0.6 -- First Stage Script
clearscreen.

local corelist is list().
list processors in corelist.
local startcorecount is corelist:length.
local currentcorecount is startcorecount.

until currentcorecount = 1
{
    list processors in corelist.
    set currentcorecount to corelist:length.
    wait 0.1.
}

StartUp().
Main().

function Main 
{
	// function calls
    Flip1().
    Boostback().
	Flip2().
	Reentry().
	AtmoGNC().
	Land().
	shutdown.
}

function StartUp 
{
    // run prerequitistes
    runoncepath("0:/missionParameters.ks").
    runoncepath("0:/gncFunc.ks").

    // control variables
    set throt to 0.
    lock throttle to throt.

    // steeringmanager re-tune
    set steeringmanager:rollts to 5.
	set steeringmanager:pitchpid:kd to steeringmanager:pitchpid:kd + 2.
	set steeringmanager:yawpid:kd to steeringmanager:yawpid:kd + 2.

    // profile variables
    set targetAzimuth to Azimuth(targetInc, targetOrb).
    set landingOvershoot to ((maxPayload - payloadMass) / 10000000) * 5.
	set ctrlOverride to ((maxPayload - payloadMass) / 10000) * 3.125.
	set burnOvershoot to ((maxPayload - payloadMass) / 10000) * (1/2).
	if (payloadMass > (maxPayload / 2))
		set boostbackLimiter to 0.7.
	else
		set boostbackLimiter to 1.

    // booster variables
    set coreAltitude to 29.285.
    lock trueAltitude to alt:radar - coreAltitude.

    // init
    set deltaTraj to 0.
    PIDvalue().
    PIDload().
}

function Flip1 
{
    rcs on.
    lock steering to lookdirup(
        heading(targetAzimuth, MECOangle):vector,
        heading(90 + targetAzimuth, 0):vector).
    wait 2 + MECOdelay.
    toggle AG1. // switch engine mode to 3
    unlock steering.
    wait 0.1.

    set ship:control:yaw to -1.
    wait 5.
    wait until ForwardVec() <= (35 - pitchComp).
    set ship:control:yaw to 0.

    wait until ForwardVec() <= (15 - pitchComp).
    lock steering to lookdirup(
        heading(targetAzimuth, 180):vector,
        heading(90 + targetAzimuth, 0):vector).
    set throt to 1.

    wait 2.
    steeringmanager:resettodefault().
}

function Boostback  
{   // will be changed to use pro-nav instead of retro-target
    rcs off.
    lock BBvec to LZ:altitudeposition(ship:altitude + 2000).
    lock steering to lookdirup(
        vxcl(up:vector, ship:srfretrograde:vector:normalized) +
		(up:vector:normalized * 0.05 * vxcl(up:vector, ship:srfretrograde:vector:normalized):mag),
 	   heading(90 + targetAzimuth, 0):vector).
    
    wait until vxcl(up:vector, ship:srfretrograde:vector:normalized):mag <= 0.03.
    lock steering to lookdirup(
        BBvec, 
        heading(90 + targetAzimuth, 0):vector).
    lock throt to min(max(0.125, Trajectories("dist") - 0.05), boostbackLimiter).

    wait until DeltaTrajectories() > 0.
    wait (1.3 + BBdelay + burnOvershoot).   // overshoot landing zone
    set throt to 0.
}

function Flip2 
{
	set steeringmanager:rollts to 5.
	set steeringmanager:pitchpid:kd to steeringmanager:pitchpid:kd + 5.
	set steeringmanager:yawpid:kd to steeringmanager:yawpid:kd + 5.
	
	rcs on.
	lock steering to lookdirup(
		heading(targetAzimuth, 180):vector, 
		heading(90 + targetAzimuth, 0):vector).
		
	wait 5.
	unlock steering.
	wait 0.1.
	
	set ship:control:yaw to 1.
	wait (3.5 + (pitchComp / 4)).
	set ship:control:yaw to 0.
		
	wait until ForwardVec() >= 85.
	brakes on.
	wait until ForwardVec() <= 75.
	
	lock steering to lookdirup(
		heading(targetAzimuth, (60 - pitchComp)):vector, 
		heading(180, 0):vector).
	brakes on.
	
	wait until ForwardVec() <= (60 - pitchComp).
	wait 10.
	rcs off.
	unlock steering.
	
	until RetroDiff("UP") >= (60 - pitchComp).
	steeringmanager:resettodefault().
}

function Reentry 
{
	lock steering to lookdirup(
		ship:srfretrograde:vector:normalized, 
		heading(180, 0):vector).
	rcs on.

	wait until alt:radar < reentryHeight + 5000.
	// rcs off.
	
	wait until alt:radar < reentryHeight.
	set throt to 1.
	toggle AG2.
	toggle AG4.
	
	wait until ship:verticalspeed > (-(reentryVelocity + reentryComp)).
	set throt to 0.
}

function AtmoGNC 
{
	lock throt to 0.
	toggle AG1.
	
	lock steering to lookdirup((
		ship:srfretrograde:vector:normalized * 10 +
		ship:facing:topvector:normalized * AlatError * (AoAlimiter) +
		ship:facing:starvector:normalized * AlngError * -(AoAlimiter)),
		heading(180, 0):vector).

	// wait until ship:verticalspeed > -300.
	toggle AG4.									//experimental
		
	rcs on.
	wait until alt:radar < 5000.
	rcs off.
}

function Land 
{
	wait until trueAltitude <= LandHeight1() and LandHeight1() < 5000.// + burnOveshoot.

	lock steering to lookdirup(
		srfretrograde:vector, 
		heading(180, 0):vector).
	lock throt to LandThrottle().
	
	wait until ship:verticalspeed > -200.

	lock steering to lookdirup((
		ship:facing:topvector:normalized * HlatError * -2000 + 
		ship:facing:starvector:normalized * HlngError * 2000 + 
		ship:srfretrograde:vector:normalized * 20), 
		heading(180, 0):vector).

	wait until ship:verticalspeed > -50.
	
	lock steering to lookdirup((
		ship:facing:topvector:normalized * HlatError * -1250 + 
		ship:facing:starvector:normalized * HlngError * 1250 + 
		ship:up:vector * 20), 
		heading(180, 0):vector).
	
	wait until trueAltitude < 150.
	gear on.
	
	wait until trueAltitude < 20.
	lock steering to lookdirup(heading(90, 90):vector, heading(180, 0):vector).
	
	wait until ship:verticalspeed > -3.
	lock throt to (0.65 * ship:mass * (body:mu / body:position:sqrmagnitude) / (ship:availablethrust + 0.0001)).
	
	wait until ship:verticalspeed > -1.
	lock throt to  (0.35 * ship:mass * (body:mu / body:position:sqrmagnitude) / (ship:availablethrust + 0.0001)).
	
	wait 1.
	set throt to 0.
    set ship:control:pilotmainthrottle to 0.
	unlock steering.
	unlock throttle.
	wait 5.
}

// PID VALUES SETUP

function PIDvalue 
{
    // atmospheric gridfins
	set atmP to 25.
	set atmI to 3.
	set atmD to 6.5.
	
	set AlatP to atmP.
	set AlatI to atmI.
	set AlatD to atmD.
	set AlatError to 0.
	
	set AlngP to atmP.
	set AlngI to atmI.
	set AlngD to atmD.
	set AlngError to 0.
	
	// engine gimbal
	set hvrP to 0.085.
	set hvrI to 0.025.
	set hvrD to 0.045.
	
	set HlatP to atmP.
	set HlatI to atmI.
	set HlatD to atmD.
	set HlatError to 0.
	
	set HlngP to atmP.
	set HlngI to atmI.
	set HlngD to atmD.
	set HlngError to 0.
}

function PIDload 
{
	set AlatPID to pidloop(AlatP, AlatI, AlatD, -0.1, 0.1).
	set AlatPID:setpoint to LZ:lat.	
	
	set AlngPID to pidloop(AlngP, AlngI, AlngD, -0.1, 0.1).
	set AlngPID:setpoint to (LZ:lng - (landingOffset + (landingOvershoot / 10))).
	
	lock AlatError to AlatPID:update(time:seconds, Trajectories("lat")).
	lock AlngError to AlngPID:update(time:seconds, Trajectories("lng")).
	
	set HlatPID to pidloop(HlatP, HlatI, HlatD, -0.0003, 0.0003).
	set HlatPID:setpoint to LZ:lat.	
	
	set HlngPID to pidloop(HlngP, HlngI, HlngD, -0.0003, 0.0003).
	set HlngPID:setpoint to LZ:lng.
	
	lock HlatError to HlatPID:update(time:seconds, Trajectories("lat")).
	lock HlngError to HlngPID:update(time:seconds, Trajectories("lng")).
}

until false {wait 0.1.}