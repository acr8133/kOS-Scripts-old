// GOJIRA v0.0.1 -- FIRST STAGE

clearScreen.
// core:part:getmodule("kOSProcessor"):doEvent("Open Terminal").

// run prerequitistes (load functions to cpu)
runoncepath("0:/TUNDRA/libGNC").

// FROM MISSION PARAMETERS
until false {
	if (core:messages:empty) {
		print "CORE EMPTY" at (0, 3).
	} else {
		set received to core:messages:pop.
		set targetInc to received:content:m_targetInc.
		set targetOrb to received:content:m_targetOrb.
		set recoveryMode to received:content:m_recoveryMode.
		set payloadMass to received:content:m_payloadMass.
		set maxPayload to received:content:m_maxPayload.
		set LZ to received:content:m_lzcoords2.
		set MECOangle to received:content:m_MECOangle.
		set reentryHeight to received:content:m_reentryHeight.
		set reentryVelocity to received:content:m_reentryVelocity.
		set AoAlimiter to received:content:m_AoAlimiter.
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

if (recoveryMode = "Full") {
	shutdown.
}

until currentcorecount <= 1 {
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
	if (recoveryMode = "RTLS_SS") {	
		Flip1(0.8, 160, 20).
		Boostback(10).
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

    // recoveryMode variables
    set landingOvershoot to 0.175.
	set burnOvershoot to 1.75.
	set ctrlOverride to ((maxPayload - payloadMass) / 10000) * 3.125.

    // booster variables
    lock trueAltitude to ship:bounds:bottomaltradar.

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
    unlock steering.
    wait 0.1.

	set ship:control:yaw to -1.
    wait 10.
	set ship:control:yaw to -1 * flipPower.

	until (vang(ship:facing:forevector, tangentVector) >= 180 - (unlockAngle * 1.5)) {
		print "TANGENT ANGLE: " + vang(ship:facing:forevector, tangentVector) at (0, 4).
		if (vang(ship:facing:forevector, tangentVector) > 90) {
			set ship:control:roll to (RollAlign()).
		}
	}
    set ship:control:neutralize to true.
	
	EngineSpool(0.1).

    wait until ForwardVec() <= unlockAngle * 0.6667.

	lock steering to lookdirup(
        heading(targetAzimuth, finalAttitude):vector,
        heading(90 + targetAzimuth, 0):vector).

    set throt to 1.
    wait 2.
    steeringmanager:resettodefault().
}

function Boostback {
	parameter finalAttitude is 0.
    rcs off.
    lock BBvec to LZ:altitudeposition(ship:altitude + 750).

	lock steering to lookdirup(
        vxcl(up:vector, ship:srfretrograde:vector:normalized):normalized *
		angleAxis(finalAttitude, ship:facing:topvector),
 		heading(90 + targetAzimuth, 0):vector).
	wait until vxcl(up:vector, ship:srfretrograde:vector:normalized):mag <= 0.03.
	toggle AG1.
	lock steering to lookdirup(
		BBvec * angleAxis(finalAttitude, ship:facing:topvector), 
		heading(90 + targetAzimuth, 0):vector).

	EngineSpool(1).

	if (recoveryMode = "RTLS_SS") {
		print "RTLS MODE" at (0, 8).
		lock throt to max(0.15, Impact("dist") - 0.01).
		until DeltaImpact() > 0 { print "DELTA: " + DeltaImpact() at (0, 5). }
		wait (burnOvershoot). 
	} else {
		local tempLZ is LZ.
		set LZ to latlng(LZ:lat, LZ:lng + landingOvershoot).
		lock throt to max(0.15, Impact("dist") - 0.325). wait 1.
		until DeltaImpact() > 0 { 
			print "DELTA: " + DeltaImpact() at (0, 5). 
			print LZ:lng at (0, 14).
			print Impact("lng") at (0, 15).
			print Impact("dist") at (0, 16). 
		}
		set LZ to tempLZ.
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
		heading(90 + targetAzimuth, 0):vector) * 
		angleAxis(-20, ship:facing:topvector).
		
	wait 7.
	unlock steering.
	wait 0.1.
	
	if (recoveryMode = "RTLS_SS") {
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

	sas off.

	// set avd to vecDraw(ship:position, ship:facing:topvector,rgb(1,0,0), "TOPVEC", 1.0, true).
	// set bvd to vecDraw(ship:position, LZ:position,rgb(1,1,0), "lz", 1.0, true).
	// set bvd:vecupdater to { return LZ:position. }.

	lock steering to lookdirup(
		ship:srfretrograde:vector:normalized, 
		heading(180, 0):vector).
}

function AtmoGNC {
	lock dRange to sqrt((LZ:lng - ship:geoposition:lng)^2 + (LZ:lat - ship:geoposition:lat)^2) * 1000.

	until ship:airspeed > 1000 {
		wait 0.
		print "APPROX: " + LandHeight0() at (0, 6).
		print "TARGET DISTANCE: " + dRange at (0, 10).
	}
}

function Land {
	lock landApprox to LandHeight0().

	until trueAltitude <= (landApprox) { DebugPrint(). }

	EngineSpool(0.3333).
	
	until ship:q > 0.11 { DebugPrint(). } // wait for atmosphere to do their work

	lock throt to 0.8.
	until LandThrottle() > 2 { DebugPrint(). }
	lock throt to LandThrottle().

	AlatPID:reset().
	AlngPID:reset().
	HlatPID:reset().
	HlngPID:reset().
	lock steering to lookdirup((
		ship:srfretrograde:vector:normalized * 10 +
		ship:facing:topvector:normalized * AlatError * (AoAlimiter) +
		ship:facing:starvector:normalized * AlngError * -(AoAlimiter)),
		heading(180, 0):vector).

	until ((ship:verticalspeed > -200 and throt < 0.75) or ship:verticalspeed > -100) { DebugPrint(). }

	lock trueAltitude to ship:bounds:bottomaltradar + 103.8.

	lock steering to lookdirup((
		ship:facing:topvector:normalized * HlatError * -1000 + 
		ship:facing:starvector:normalized * HlngError * 1000 + 
		(-ship:velocity:surface:normalized * 20 + up:vector * 20)), 
		heading(180, 0):vector).

	until ship:verticalspeed > -20 { DebugPrint(). }
	
	lock steering to lookdirup((
		ship:facing:topvector:normalized * HlatError * -1000 + 
		ship:facing:starvector:normalized * HlngError * 1000 + 
		(up:vector * 200)), 
		heading(180, 0):vector).

	until trueAltitude < 15 { DebugPrint(). }
	lock steering to lookdirup(heading(90, 90):vector, heading(90 + 90, 0):vector).
	
	until ship:verticalspeed > -3 { DebugPrint(). }
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

function DebugPrint {
	wait 0.
	print ship:q at (0, 12).
	print trueAltitude at (0, 13).
	print LandThrottle() at (0, 14).
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
	set atmP to 50.
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
	set hvrP to 13.
	set hvrI to 0.5.
	set hvrD to 2.5.
	
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

	lock OvershootAlt to min(0.35, alt:radar * 0.000045).

	lock AlatError to AlatPID:update(time:seconds, (((1 - OvershootAlt) * Impact("lat")) + (OvershootAlt * ship:geoposition:lat))).
	lock AlngError to AlngPID:update(time:seconds, (((1 - OvershootAlt) * Impact("lng")) + (OvershootAlt * ship:geoposition:lng))).

	set HlatPID to pidloop(HlatP, HlatI, HlatD, -0.003, 0.003).
	set HlatPID:setpoint to LZ:lat.	
	
	set HlngPID to pidloop(HlngP, HlngI, HlngD, -0.003, 0.003).
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

// MAKE BOOSTBACK BURN GO HIGHER
// TEST CONTROL POINT CHANGE

// STAGE 2 SHOULD FACE TOWARDS BODY ON APOAPSIS RAISE
// THEN ROTATE AWAY FROM BODY FOR CIRCULATION NODE

// ACTION GROUP SETTING