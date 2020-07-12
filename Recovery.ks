
//------------------------------------------------------------
//	READ COMMENTS FIRST,put me on the First Stage CPU :D v0.5.1
//	Legend AG1 - Engine Switch, AG2 - Soot, AG4 - Strongback
//------------------------------------------------------------

clearscreen.

local corelist is list().
list processors in corelist.
local startcorecount is corelist:length.
local currentcorecount is startcorecount.

until currentcorecount = 1 {			//waits until Stage 2 is separated
    list processors in corelist.
    set currentcorecount to corelist:length.		
    wait 0.1.
}


Startup().


function Main {
	Flip1().
	Boostback().
	Flip2().
	Reentry().
	AtmoGNC().
	Land().
}

function Startup {
	
	//flight variables ( dont touch, might break stuff :P )
	
	run "boot/Parameter.ks".
	
	if profile = "RTLS" {	
		set landingOffset to 0.00085.
		
		set AoAlimiter to 1.
	}
	
	sas off. rcs off. gear off. brakes off.
	set steeringmanager:rollts to 5.
	set steeringmanager:pitchpid:kd to steeringmanager:pitchpid:kd + 5.
	set steeringmanager:yawpid:kd to steeringmanager:yawpid:kd + 5.
	
	set targetAzimuth to Azimuth(targetInclination, targetOrbit).
	
	set landingOvershoot to ((16000 - payloadMass) / 10000000) * 5.
	set pitchComp to ((16000 - payloadMass) / 10000) * 3.125.
	set burnOveshoot to ((16000 - payloadMass) / 100) * (20).
	set burningLock to false.
	if payloadMass > 8000 {
		set boostbackLimiter to 0.7.
	}
	else {
		set boostbackLimiter to 1.
	}
	
	set throt to 0.
	lock throttle to throt.
	
	set coreAltitude to 29.985.
	lock trueAltitude to alt:radar - coreAltitude.
	
	//PID setup
	PIDvalue().
	PIDload().
	
	Main().
}

function Flip1 {
	rcs on.
	lock steering to lookdirup(
		heading(targetAzimuth, 35 + pitchComp):vector, 
		heading(90 + targetAzimuth, 0):vector).
	wait 2.
	toggle AG1.
	unlock steering.
	
	set ship:control:yaw to -1.
	wait 10.
	set ship:control:yaw to 0.
	
	wait until ForwardVec() <= 20.
	
	lock steering to lookdirup(
		heading(targetAzimuth, 180):vector, 
		heading(90 + targetAzimuth, 0):vector).
	
	set throt to 1.
	
	wait 2.
	steeringmanager:resettodefault().
}

function Boostback {
	rcs off.
	lock BBvec to LZ:altitudeposition(ship:altitude + 1000).		//dont mind the +1000 lol
	
	lock steering to lookdirup(
		vxcl(up:vector, ship:srfretrograde:vector:normalized), 
		heading(90 + targetAzimuth, 0):vector).
	wait until vxcl(up:vector, ship:srfretrograde:vector:normalized):mag <= 0.025.
	lock steering to lookdirup(BBvec, heading(90 + targetAzimuth, 0):vector).
	
	lock throt to min(max(0.2, Trajectories("dist") - 0.35), boostbackLimiter).
	
	wait until DeltaTrajectories > 0.
	
	wait 1.25.	//overshoots the landing zone a little bit
	set throt to 0.
}

function Flip2 {
	set steeringmanager:rollts to 5.
	set steeringmanager:pitchpid:kd to steeringmanager:pitchpid:kd + 5.
	set steeringmanager:yawpid:kd to steeringmanager:yawpid:kd + 5.
	
	rcs on.
	lock steering to lookdirup(
		heading(targetAzimuth, 180):vector, 
		heading(90 + targetAzimuth, 0):vector).
		
	wait 5.
	unlock steering.
	
	set ship:control:yaw to 1.
	wait 3.
	set ship:control:yaw to 0.
		
	wait until ForwardVec() >= 85.
	brakes on.
	wait until ForwardVec() <= 75.
	
	lock steering to lookdirup(
		heading(targetAzimuth, 60):vector, 
		heading(180, 0):vector).
	brakes on.
	
	wait until ForwardVec() <= 60.
	wait 20.
	rcs off.
	unlock steering.
	
	until RetroDiff("UP") >= 60.
	steeringmanager:resettodefault().
}

function Reentry {
	lock steering to lookdirup(
		ship:srfretrograde:vector:normalized, 
		heading(180, 0):vector).
	rcs on.

	wait until alt:radar < reentryHeight + 5000 .
	// rcs off.
	
	wait until alt:radar < reentryHeight.
	set throt to 1.
	toggle AG2.
	toggle AG4.
	
	wait until ship:verticalspeed > (reentryVelocity * -1).
	set throt to 0.
}

function AtmoGNC 
{	
	set throt to 0.
	toggle AG1.
	
	lock steering to lookdirup((
		ship:srfretrograde:vector:normalized * 10 +
		ship:facing:topvector:normalized * AlatError * 1.15 +
		ship:facing:starvector:normalized * AlngError * -1.15),
		heading(180, 0):vector).

	// wait until ship:verticalspeed > -300.
	toggle AG4.									//experimental
		
	rcs on.
	wait until alt:radar < 7500.
	rcs off.
}

//LANDINGBURN
function Land
{
	
	// core:part:getmodule("kOSProcessor"):doEvent("Open Terminal").
	// print "LIGMA" at (0, 3).
	
	if ship:verticalspeed < -280 and burningLock = false {
		set burningLock to true.
		wait until trueAltitude <= LandHeight1() and LandHeight1() < 6000 + burnOveshoot.
	}
	else if ship:verticalspeed > -280 and burningLock = false{
		set burningLock to true.
		wait until trueAltitude <= LandHeight0() and LandHeight0() < 6000 + burnOveshoot.
	}
	
	lock steering to lookdirup(
		srfretrograde:vector, 
		heading(180, 0):vector).
	lock throt to LandThrottle().
	
	wait until ship:verticalspeed > -100.
	
	lock steering to lookdirup((
		ship:facing:topvector:normalized * HlatError * -1300 + 
		ship:facing:starvector:normalized * HlngError * 1300 + 
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
	unlock steering.
	unlock throttle.
}


function LandHeight0
{
	set shipAcc0 to (ship:availablethrust / ship:mass) - (body:mu / body:position:sqrmagnitude).
	set distance0 to ship:verticalspeed^2 / (2 * shipAcc0).
	
	return distance0.
}

function LandThrottle
{	
	wait 0.
	set targetThrot to (LandHeight0() / (trueAltitude - 5)).
	
	return max(targetThrot, 0.6).
}

function SimSpeed
{
	set oldSpeed to ship:airspeed.
	wait 0.1.
	set newSpeed to ship:airspeed.
	set deltaSpeed to (newSpeed - oldSpeed).
	
	return  ship:airspeed + (deltaSpeed * 10) - DragValue().
}

function LandHeight1
{
	set shipAcc1 to (ship:availablethrust / ship:mass) - (body:mu / body:position:sqrmagnitude).
	set distance1 to SimSpeed()^2 / (2 * shipAcc1).
	
	return distance1.
}

function DragValue
{
	set v0 to ship:velocity:surface. set t0 to time:seconds.
	wait 0.05.
	set v1 to ship:velocity:surface. set t1 to time:seconds.
	
	set netForce to ((v1 - v0) / (t1 - t0)) * ship:mass.
	set gravityForce to (body:mu / body:position:sqrmagnitude) * -up:vector * ship:mass.
	set throttleForce to ship:facing:forevector * ship:availablethrust * throttle.
	set dragForce to netForce - gravityForce - throttleForce.
	
	return (dragForce:mag / 25). // +5 for safety reasons
}


function ForwardVec {	//returns prograde angle
	set forwardPitch to 90 - vang(ship:up:vector, ship:facing:forevector).
	return forwardPitch.
}

function RetroDiff {	//returns retrograde angle
	parameter retMode. // UP = retro angle from radial out, RETRO = AoA from retrograde
	if retMode = "UP" {
		set rtrDiff to 90 - vang(ship:up:vector:normalized, ship:srfretrograde:vector:normalized).
		return rtrDiff.
	} 
	else {
		set rtrDiff to 90 - vang(ship:facing:forevector, ship:srfretrograde:vector:normalized).
		return rtrDiff.
	}
}

function Trajectories {		//takes parameter 'nav'
	parameter nav.
	if addons:tr:hasImpact {
		if nav = "lat" {
			return addons:tr:impactpos:lat.
		}
		else if nav = "lng" {
			return addons:tr:impactpos:lng.
		}
		else if nav = "dist" {
			return sqrt(((addons:tr:impactpos:lat - LZ:lat)^2) + ((addons:tr:impactpos:lng - LZ:lng)^2)).
			//"dist" returns distance between LZ and impact point
		}
	}
	else {
		if nav = "lat" {
			return ship:geoposition:lat.
		}
		else {
			return ship:geoposition:lng.
		}
	}
}

function PIDvalue {
	//atmospheric gnc pid values
	set atmP to 150.
	set atmI to 3.5.
	set atmD to 7.5.
	
	set AlatP to atmP.
	set AlatI to atmI.
	set AlatD to atmD.
	set AlatError to 0.
	
	set AlngP to atmP.
	set AlngI to atmI.
	set AlngD to atmD.
	set AlngError to 0.
	
	//engine gimbal vector pid values
	set hvrP to 0.1.
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

function PIDload {
	set AlatPID to pidloop(AlatP, AlatI, AlatD, -AoAlimiter, AoAlimiter).
	set AlatPID:setpoint to LZ:lat.	
	
	set AlngPID to pidloop(AlngP, AlngI, AlngD, -AoAlimiter, AoAlimiter).
	set AlngPID:setpoint to (LZ:lng - (landingOffset + landingOvershoot)).
	
	lock AlatError to AlatPID:update(time:seconds, Trajectories("lat")).
	lock AlngError to AlngPID:update(time:seconds, Trajectories("lng")).
	
	set HlatPID to pidloop(HlatP, HlatI, HlatD, -0.0003, 0.0003).
	set HlatPID:setpoint to LZ:lat.	
	
	set HlngPID to pidloop(HlngP, HlngI, HlngD, -0.0003, 0.0003).
	set HlngPID:setpoint to LZ:lng.
	
	lock HlatError to HlatPID:update(time:seconds, Trajectories("lat")).
	lock HlngError to HlngPID:update(time:seconds, Trajectories("lng")).
}

function DeltaTrajectories {	//returns distance delta
	set oldTraj to Trajectories("dist").
	wait 0.1.
	
	set newTraj to Trajectories("dist").
	return (newTraj - oldTraj) / 10.
	set oldTraj to newTraj.
	
	//the booster will stop when it detects that it is getting farther rather
	//than getting nearer every 0.1 second.
}

function Azimuth {
    parameter inclination.
    parameter orbitAlt.
    parameter autoSwitch is false.

    set shipLat to ship:latitude.
    if abs(inclination) < abs(shipLat) {
        set inclination to shipLat.
    }

    set head to arcsin(cos(inclination) / cos(shipLat)).
    if autoSwitch {
        if angleToBodyDescendingNode(ship) < angleToBodyAscendingNode(ship) {
            set head to 180 - head.
        }
    }
    else if inclination < 0 {
        set head to 180 - head.
    }
	
    set velOrbit to sqrt(body:mu / (orbitAlt + body:radius)).
    set velRotX to velOrbit * sin(head) - vdot(ship:velocity:orbit, heading(90, 0):vector).
    set velRotY to velOrbit * cos(head) - vdot(ship:velocity:orbit, heading(0, 0):vector).
    set head to 90 - arctan2(velRotY, velRotX).
    return mod(head + 360, 360).
}

until false {
	wait 0.1.
}

