// Ghidorah v0.6 -- First Stage Script
clearscreen.
// core:part:getmodule("kOSProcessor"):doEvent("Open Terminal").
until AG10 wait 1.

// run prerequitistes (load functions to cpu)
runoncepath("0:/TUNDRA/missionParameters").
runoncepath("0:/TUNDRA/libGNC").
runoncepath("0:/TUNDRA/launchWindow").

// system registry
local eqtrDirChoose is saveEqtrFunc().
eqtrDirChoose:set(DirCorr()).
local azmthDirChoose is saveAzmthFunc().
azmthDirChoose:set(Azimuth(DirCorr() * targetInc, targetOrb)).

global eqtrDir is eqtrDirChoose:get(). print "EQTR: " + eqtrDir at (0, 1).
global targetAzimuth is azmthDirChoose:get(). print "AZMTH: " + targetAzimuth at (0, 2).

// wait till separation
local corelist is list().
list processors in corelist.
local startcorecount is corelist:length.
local currentcorecount is startcorecount.

if (profile = "Full") {
	shutdown.
}

until currentcorecount <= 2 {
    list processors in corelist.
    set currentcorecount to corelist:length.
    wait 0.1.
}

StartUp().
Main().

function Main {
	// function calls
	if (profile = "RTLS") {	
		Flip1(0.9, 180, 30, 50).
		Boostback().
		Flip2(60).
		Reentry1(60).
		AtmoGNC().
		Land().
		AG10 off.
		shutdown.
	} else {
		Flip1(0.9, 180, 30, 50).
		Boostback().
		Flip2(45).
		Reentry1(45).
		AtmoGNC().
		Land().
		AG10 off.
		shutdown.
	}
}

function StartUp {	
    // control variables
    set throt to 0.
    lock throttle to throt.

    // steeringmanager re-tune
    set steeringmanager:rollts to 20.
	set steeringmanager:pitchpid:kd to steeringmanager:pitchpid:kd + 3.
	set steeringmanager:yawpid:kd to steeringmanager:yawpid:kd + 3.

    // profile variables
    set landingOvershoot to ((maxPayload - payloadMass) / 10000000) * 8.5.
	set ctrlOverride to ((maxPayload - payloadMass) / 10000) * 3.125.
	set burnOvershoot to ((maxPayload - payloadMass) / 10000) * 1.5.

    // booster variables
    set coreAltitude to 29.285.
    lock trueAltitude to alt:radar - coreAltitude.

    // init
    set deltaTraj to 0.
    PIDvalue().
    PIDload().
}

function Flip1 {
	parameter flipPower, finalAttitude, unlockAngle, waitAngle. 
	// parameters w,x,y,z - rcs until z, counter at y, stop at x, at power w

	local tangentVector is heading(targetAzimuth, 0):vector.

    rcs on.
    lock steering to lookdirup(
        heading(targetAzimuth, MECOangle):vector,
        heading(90 + targetAzimuth, 0):vector).
    wait 3.
    toggle AG1. // switch engine mode to 3
    unlock steering.
    wait 0.1.

    set ship:control:yaw to -1 * flipPower.
    wait 5.
	
	until (vang(ship:facing:forevector, tangentVector) >= 180 - unlockAngle) {
		print "TANGENT ANGLE: " + vang(ship:facing:forevector, tangentVector) at (0, 4).
		if (vang(ship:facing:forevector, tangentVector) > 90) {
			set ship:control:roll to (RollAlign()).
		}
	}

    set ship:control:neutralize to true.
	set throt to 0.25.

    wait until ForwardVec() <= unlockAngle.

	lock steering to lookdirup(
        heading(targetAzimuth, finalAttitude):vector,
        heading(90 + targetAzimuth, 0):vector).

    set throt to 1.
    wait 3.
    steeringmanager:resettodefault().
}

function Boostback {
    rcs off.
    lock BBvec to LZ:altitudeposition(ship:altitude + 750).
    lock steering to lookdirup(
        vxcl(up:vector, ship:srfretrograde:vector:normalized) +
		(up:vector:normalized * 0.025 * vxcl(up:vector, ship:srfretrograde:vector:normalized):mag),
 		heading(90 + targetAzimuth, 0):vector).
    
	if (profile = "RTLS") {
		wait until vxcl(up:vector, ship:srfretrograde:vector:normalized):mag <= 0.03.
		lock steering to lookdirup(
			BBvec, 
			heading(90 + targetAzimuth, 0):vector).
	}

	if (profile = "RTLS") {
		lock throt to max(0.125, Trajectories("dist") - 0.05).
		wait until DeltaTrajectories() > 0.
		wait (1.5 + burnOvershoot). 
	} else {
		lock throt to max(0.125, Trajectories("dist") - 0.325).
		wait until Trajectories("dist") < 0.375.	// ASDS profile needs to work differently
	}
    set throt to 0.
}

function Flip2 {
	parameter holdAngle.

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
	
	if (profile = "RTLS") {
		set ship:control:yaw to 1.
		wait 5.
		set ship:control:yaw to 0.
		
		wait until ForwardVec() >= 85.
		brakes on.
		wait until ForwardVec() <= 75.

		lock steering to lookdirup(
		heading(targetAzimuth, holdAngle):vector, 
		heading(90 + targetAzimuth, 0):vector).

		wait until ForwardVec() <= holdAngle.
	} else {
		set ship:control:yaw to 1.
		wait 2.5.
		set ship:control:yaw to 0.

		wait until ForwardVec() >= 40.
		brakes on.

		lock steering to lookdirup(
		heading(targetAzimuth, 90 + holdAngle):vector, 
		heading(90 + targetAzimuth, 0):vector).

		wait until ForwardVec() >= holdAngle.
	}
	
	wait 10.
	// rcs off.
	sas on.
	unlock steering.
}

function Reentry1 {
	parameter holdAngle.

	wait until RetroDiff("UP") >= holdAngle.
	steeringmanager:resettodefault().

	lock steering to lookdirup(
		ship:srfretrograde:vector:normalized, 
		heading(90 + targetAzimuth, 0):vector).
	sas off.

	until alt:radar < reentryHeight + 5000 {
		print "TRAJ-LZ: " + (Trajectories("lng") - ship:geoposition:lng) at (0, 6).
		print "DRAG: " + DragValue() at (0, 8).
	}
	until alt:radar < reentryHeight {
		print "TRAJ-LZ: " + (Trajectories("lng") - ship:geoposition:lng) at (0, 6).
		print "DRAG: " + DragValue() at (0, 8).

	}

	lock steering to lookdirup(
		ship:srfretrograde:vector:normalized * angleaxis(2.5, ship:facing:topvector), 
		heading(90 + targetAzimuth, 0):vector).
	set throt to 1.
	toggle AG2.
	
	wait until ship:airspeed < reentryVelocity.
	set throt to 0.
}

function AtmoGNC {
	lock throt to 0.
	toggle AG1.
	
	lock steering to lookdirup((
		ship:srfretrograde:vector:normalized * 10 +
		ship:facing:topvector:normalized * AlatError * (AoAlimiter) +
		ship:facing:starvector:normalized * AlngError * -(AoAlimiter)),
		heading(90 + targetAzimuth, 0):vector).

	until alt:radar < 5000 {
		wait 0.
		print "TRAJ-LZ: " + (Trajectories("lng") - ship:geoposition:lng) at (0, 6).
		print "DRAG: " + DragValue() at (0, 8).

		// print ""

		if (ship:altitude < 11000) {
			rcs off.
		} else {
			rcs on.
		}
	}
}

function Land {
	lock landApprox to LandHeight1().

	until trueAltitude <= (landApprox) {
		wait 0.
	}

	lock throt to 0.4.
	lock steering to lookdirup(
		srfretrograde:vector, 
		heading(90 + targetAzimuth, 0):vector).
	wait 1.					// engine spool lol
	lock throt to 1.
	
	until ship:verticalspeed > -225 {
		wait 0.
	}

	when (trueAltitude < 200) then {
		gear on.
	}

	lock throt to LandThrottle().
	lock steering to lookdirup((
		ship:facing:topvector:normalized * HlatError * -7500 + 
		ship:facing:starvector:normalized * HlngError * 7500 + 
		(-ship:velocity:surface + up:vector)), 
		heading(90 + targetAzimuth, 0):vector).

	wait until ship:verticalspeed > -30.
	
	lock steering to lookdirup((
		ship:facing:topvector:normalized * HlatError * -1000 + 
		ship:facing:starvector:normalized * HlngError * 1000 + 
		ship:up:vector:normalized * 20), 
		heading(90 + targetAzimuth, 0):vector).
	
	wait until trueAltitude < 20.
	lock steering to lookdirup(heading(90, 90):vector, heading(90 + targetAzimuth, 0):vector).
	
	wait until ship:verticalspeed > -5.
	lock throt to (0.9 * ship:mass * (body:mu / body:position:sqrmagnitude) / (ship:availablethrust + 0.0000001)).	// vertical velocity hold (avoids bounce too)
	
	rcs on.
	wait until ship:verticalspeed > -1.
	lock throt to  (0.35 * ship:mass * (body:mu / body:position:sqrmagnitude) / (ship:availablethrust + 0.0000001)).
	
	wait 1.
	set throt to 0.1.	// depressurize tank
    set ship:control:pilotmainthrottle to 0.
	unlock steering.
	unlock throttle.
	wait 5.
}

// ROLL ALIGNMENT MODULE

function RollAlign {
	wait 0.
	return rollPID:update(time:seconds, vang(ship:facing:topvector, body:position)).
}

// PID VALUES SETUP

function PIDvalue {
    // atmospheric gridfins
	set atmP to 13.
	set atmI to 0.15.
	set atmD to 5.5.
	
	set AlatP to atmP.
	set AlatI to atmI.
	set AlatD to atmD.
	set AlatError to 0.
	
	set AlngP to atmP.
	set AlngI to atmI.
	set AlngD to atmD.
	set AlngError to 0.
	
	// engine gimbal
	set hvrP to 0.09438.
	set hvrI to 0.033.
	set hvrD to 0.05472.
	
	set HlatP to atmP.
	set HlatI to atmI.
	set HlatD to atmD.
	set HlatError to 0.
	
	set HlngP to atmP.
	set HlngI to atmI.
	set HlngD to atmD.
	set HlngError to 0.
}

function PIDload {
	set rollPID to pidloop(0.5, 0, 0.75, -1, 1).
	set rollPID:setpoint to 90.

	set AlatPID to pidloop(AlatP, AlatI, AlatD, -0.1, 0.1).
	set AlatPID:setpoint to LZ:lat.	
	
	set AlngPID to pidloop(AlngP, AlngI, AlngD, -0.1, 0.1).
	set AlngPID:setpoint to LZ:lng .

	lock AlatError to AlatPID:update(time:seconds, ((7 * Trajectories("lat")) + ship:geoposition:lat) / 8).
	lock AlngError to AlngPID:update(time:seconds, ((7 * Trajectories("lng")) + ship:geoposition:lng) / 8).
	
	set HlatPID to pidloop(HlatP, HlatI, HlatD, -0.0005, 0.0005).
	set HlatPID:setpoint to LZ:lat.	
	
	set HlngPID to pidloop(HlngP, HlngI, HlngD, -0.0005, 0.0005).
	set HlngPID:setpoint to LZ:lng.
	
	lock HlatError to HlatPID:update(time:seconds, Trajectories("lat")).
	lock HlngError to HlngPID:update(time:seconds, Trajectories("lng")).
}

// REGISTRY - some parameters are required to be retrieved at the pad
		// this is calculated on AscentScript but data is lost at
		// MECO, solution is to save it at GO call

function SaveEqtrFunc {
	local this0 is lexicon("value", 0).
	set this0["get"] to { return this0:value. }.
	set this0["set"] to { parameter x. set this0:value to x. }.
	return this0.
}

function SaveAzmthFunc {
	local this1 is lexicon("value", 0).
	set this1["get"] to { return this1:value. }.
	set this1["set"] to { parameter x. set this1:value to x. }.
	return this1.
}

until false {wait 0.1.}