// GHIDORAH v1.0 -- FIRST STAGE

clearscreen.
// core:part:getmodule("kOSProcessor"):doEvent("Open Terminal").

// run prerequitistes (load functions to cpu)
runoncepath("0:/TUNDRA/libGNC").

// FROM MISSION PARAMETERS
until false {
	if (core:messages:empty) {
		print "CORE EMPTY" at (0, 3).
	} else {
		set received to core:messages:pop.
		set targetInc to received:content:tgtInc.
		set targetOrb to received:content:tgtOrb.
		set profile to received:content:prf.
		set payloadMass to received:content:pMass.
		set maxPayload to received:content:maxPmass.

		if (profile = "Heavy") {
			if (core:tag = "BBooster") { set LZ to received:content:lzcoords1. }
			else if (core:tag = "ABooster"){ set LZ to received:content:lzcoords. }
			else { set LZ to received:content:lzcoords0. }
		}
		else if (profile = "ASDS") {
			set LZ to received:content:lzcoords0.
		}
		else {
			set LZ to received:content:lzcoords1.
		}
		
		set MECOangle to received:content:mecoAng.
		set reentryHeight to received:content:rntryAlt.
		set reentryVelocity to received:content:rntryVel.
		set AoAlimiter to received:content:aoalim.
		print "First Data Received" at (0, 9).
		break.
	}
	wait 0.
}

// FROM LAUNCH WINDOW
until false {
	if (core:messages:empty) {
		print "CORE EMPTY" at (0, 3).
	} else {
		set received1 to core:messages:pop.
		set goForLaunch to received1:content:GOCall.
		print "Second Data Received" at (0, 10).
		break.
	}
}

// system registrys
until (goForLaunch) { wait 0. }

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
	print "NEW: " + targetAzimuth at (0, 5).
}

StartUp().
Main().

function Main {
	// function calls
	core:part:controlfrom().
	if (profile = "RTLS" or core:tag = "ABooster" or core:tag = "BBooster") {	
		Flip1(0.75, 180, 25).
		Boostback().
		Flip2(60).
		Reentry1(60).
		AtmoGNC().
		Land().
		AG10 off.
		shutdown.
	} else {
		Flip1(0.75, 170, 35).
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
	set steeringmanager:pitchpid:kd to steeringmanager:pitchpid:kd + 5.
	set steeringmanager:yawpid:kd to steeringmanager:yawpid:kd + 5.

    // profile variables
    set landingOvershoot to 0.175.
	set burnOvershoot to 1.25.
	set ctrlOverride to ((maxPayload - payloadMass) / 10000) * 3.125.

    // booster variables
    set coreAltitude to 29.285.
    lock trueAltitude to alt:radar - coreAltitude.

    // init
    set deltaTraj to 0.
    PIDvalue().
    PIDload().
}

function Flip1 {
	parameter flipPower, finalAttitude, unlockAngle.
	// parameters x,y,z -  counter at z, stop at y, at power x

	local tangentVector is heading(targetAzimuth, 0):vector.

    rcs on.
	
    lock steering to lookdirup(
        heading(targetAzimuth, MECOangle):vector,
        heading(90 + targetAzimuth, 0):vector).
    wait 2.5.
    toggle AG1. // switch engine mode to 3
    unlock steering.
    wait 0.1.

	set ship:control:yaw to -1.
    wait 5.
	set ship:control:yaw to -1 * flipPower.

	until (vang(ship:facing:forevector, tangentVector) >= 180 - (unlockAngle * 1.5)) {
		print "TANGENT ANGLE: " + vang(ship:facing:forevector, tangentVector) at (0, 4).
		if (vang(ship:facing:forevector, tangentVector) > 90) {
			set ship:control:roll to (RollAlign()).
		}
	}

    set ship:control:neutralize to true.
	
	EngineSpool(0.1).

    wait until ForwardVec() <= unlockAngle * 0.5.

	lock steering to lookdirup(
        heading(targetAzimuth, finalAttitude):vector,
        heading(90 + targetAzimuth, 0):vector).

    set throt to 1.
    wait 2.
    steeringmanager:resettodefault().
}

function Boostback {
    rcs off.
    lock BBvec to LZ:altitudeposition(ship:altitude + 750).
    lock steering to lookdirup(
        vxcl(up:vector, ship:srfretrograde:vector:normalized):normalized *
		angleAxis(10, ship:facing:topvector),
 		heading(90 + targetAzimuth, 0):vector).
    
	if (profile = "RTLS" or core:tag = "ABooster" or core:tag = "BBooster") {
		wait until vxcl(up:vector, ship:srfretrograde:vector:normalized):mag <= 0.03.
		lock steering to lookdirup(
			BBvec * angleAxis(0, ship:facing:topvector), 
			heading(90 + targetAzimuth, 0):vector).
	}

	EngineSpool(1).

	if (profile = "RTLS" or core:tag = "ABooster" or core:tag = "BBooster") {
		lock throt to max(0.125, Impact("dist") - 0.05).
		until DeltaImpact() > 0 { print "DELTA: " + DeltaImpact() at (0, 5). }
		wait (burnOvershoot). 
	} else {
		local tempLZ is LZ.
		set LZ to latlng(LZ:lat, LZ:lng + landingOvershoot).
		lock throt to max(0.125, Impact("dist") - 0.325). wait 1.
		until DeltaImpact() > 0 { 
			print "DELTA: " + DeltaImpact() at (0, 5). 
			print LZ:lng at (0, 14).
			print Impact("lng") at (0, 15).
			print Impact("dist") at (0, 16). 
		}
		set LZ to tempLZ.
		// ASDS profile needs to work differently
	}
    EngineSpool(0).
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
	
	if (profile = "RTLS" or core:tag = "ABooster" or core:tag = "BBooster") {
		set ship:control:yaw to 1.
		wait 3.5.
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

	sas off.

	// set avd to vecDraw(ship:position, ship:facing:topvector,rgb(1,0,0), "TOPVEC", 1.0, true).
	// set bvd to vecDraw(ship:position, LZ:position,rgb(1,1,0), "lz", 1.0, true).
	// set bvd:vecupdater to { return LZ:position. }.

	lock steering to lookdirup(
		ship:srfretrograde:vector:normalized, 
		heading(180, 0):vector).

	until alt:radar < reentryHeight + 5000 {
		print "TRAJ-LZ: " + (Impact("lng") - ship:geoposition:lng) at (0, 6).
		print "DRAG FORCE: " + DragValue() at (0, 8).
	}
	until alt:radar < reentryHeight {
		print "TRAJ-LZ: " + (Impact("lng") - ship:geoposition:lng) at (0, 6).
		print "DRAG FORCE: " + DragValue() at (0, 8).

	}

	lock steering to lookdirup(
		ship:srfretrograde:vector:normalized * angleaxis(0, ship:facing:topvector), 
		heading(180, 0):vector).

	EngineSpool(1).

	// UN-COMMENT LINE BELOW TO TURN ON SOOT FROM TUNDRA
	// toggle AG2.
	
	wait until ship:airspeed < reentryVelocity.
	EngineSpool(0).
}

function AtmoGNC {
	toggle AG1.
	lock dRange to sqrt((LZ:lng - ship:geoposition:lng)^2 + (LZ:lat - ship:geoposition:lat)^2) * 1000.
	
	lock steering to lookdirup((
		ship:srfretrograde:vector:normalized * 10 +
		ship:facing:topvector:normalized * AlatError * (AoAlimiter) +
		ship:facing:starvector:normalized * AlngError * -(AoAlimiter)),
		heading(180, 0):vector).

	until alt:radar < 5000 {
		wait 0.
		print "TRAJ-LZ: " + (Impact("lng") - ship:geoposition:lng) at (0, 6).
		print "DRAG FORCE: " + DragValue() at (0, 8).
		print "TARGET DISTANCE: " + dRange at (0, 10).

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
		print "TARGET DISTANCE: " + dRange at (0, 10).
		wait 0.
	}

	EngineSpool(0,4).
	lock steering to lookdirup(
		srfretrograde:vector, 
		heading(180, 0):vector).
	wait 1.					// engine spool lol
	EngineSpool(1).
	
	until ship:verticalspeed > -150 { print "TARGET DISTANCE: " + dRange at (0, 10). wait 0. }

	when (trueAltitude < 150) then {
		gear on.
	}

	lock throt to LandThrottle().
	lock steering to lookdirup((
		ship:facing:topvector:normalized * HlatError * -1000 + 
		ship:facing:starvector:normalized * HlngError * 1000 + 
		(-ship:velocity:surface:normalized * 10 + up:vector * 10)), 
		heading(180, 0):vector).

	until ship:verticalspeed > -20 { print "TARGET DISTANCE: " + dRange at (0, 10). wait 0.}
	
	lock steering to lookdirup((
		ship:facing:topvector:normalized * HlatError * -1000 + 
		ship:facing:starvector:normalized * HlngError * 1000 + 
		(up:vector * 100)), 
		heading(180, 0):vector).

	until trueAltitude < 15 { print "TARGET DISTANCE: " + dRange at (0, 10). wait 0. }
	lock steering to lookdirup(heading(90, 90):vector, heading(90 + 90, 0):vector).
	
	until ship:verticalspeed > -3 { print "TARGET DISTANCE: " + dRange at (0, 10). wait 0. }
	lock throt to (0.95 * ship:mass * 9.81 / max(ship:availablethrust, 0.001)).	// vertical velocity hold (avoids bounce too)
	
	rcs on.
	wait until ship:verticalspeed > -1.
	lock throt to (0.25 * ship:mass * 9.81 / max(ship:availablethrust, 0.0001)).
	
	wait 1.
    set ship:control:pilotmainthrottle to 0.
	unlock steering.
	unlock throttle.
	wait 5.
}

function EngineSpool {
    parameter tgt, ullage is false.
    local startTime is time:seconds.
	local throttleStep is 0.0004.

    if (ullage) { 
        rcs on. 
        set ship:control:fore to 0.35.
        
        when (time:seconds > startTime + 2) then { 
            set ship:control:neutralize to true. rcs off. 
        }
    }

    if (throt < tgt) {
        set throt to 0.025. wait 0.5.
        until throt >= tgt { set throt to throt + throttleStep. }
    } else {
        until throt <= tgt { set throt to throt - throttleStep. }
    }

    set throt to tgt.
}

// PID CONTROLLER SETUP

function RollAlign {
	wait 0.
	return rollPID:update(time:seconds, vang(ship:facing:topvector, body:position)).
}

function PIDvalue {
    // atmospheric gridfins
	set atmP to 20.
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
	set hvrP to 10.
	set hvrI to 0.
	set hvrD to 1.7.
	
	set HlatP to hvrP.
	set HlatI to hvrI.
	set HlatD to hvrD.
	set HlatError to 0.
	
	set HlngP to hvrP.
	set HlngI to hvrI.
	set HlngD to hvrD.
	set HlngError to 0.
}

function PIDload {
	set rollPID to pidloop(0.85, 0, 1, -1, 1).
	set rollPID:setpoint to 90.

	set AlatPID to pidloop(AlatP, AlatI, AlatD, -0.1, 0.1).
	set AlatPID:setpoint to LZ:lat.	
	
	set AlngPID to pidloop(AlngP, AlngI, AlngD, -0.1, 0.1).
	set AlngPID:setpoint to LZ:lng .

	lock OvershootAlt to min(0.3, alt:radar * 0.000025).

	lock AlatError to AlatPID:update(time:seconds, (((1 - OvershootAlt) * Impact("lat")) + (OvershootAlt * ship:geoposition:lat))).
	lock AlngError to AlngPID:update(time:seconds, (((1 - OvershootAlt) * Impact("lng")) + (OvershootAlt * ship:geoposition:lng))).

	set HlatPID to pidloop(HlatP, HlatI, HlatD, -0.001, 0.001).
	set HlatPID:setpoint to LZ:lat.	
	
	set HlngPID to pidloop(HlngP, HlngI, HlngD, -0.001, 0.001).
	set HlngPID:setpoint to LZ:lng.
	
	lock HlatError to HlatPID:update(time:seconds, Impact("lat")).
	lock HlngError to HlngPID:update(time:seconds, Impact("lng")).
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

until false {wait 0.}