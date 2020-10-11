// ORBITAL ELEMENTS CLACULATION

function Azimuth {
    parameter inclination.
    parameter orbit_alt.
    parameter auto_switch is false.

    local shipLat is ship:latitude.
    if abs(inclination) < abs(shipLat) {
        set inclination to shipLat.
    }

    local head is arcsin(cos(inclination) / cos(shipLat)).
    if auto_switch {
        if AngleToBodyDescendingNode(ship) < AngleToBodyAscendingNode(ship) {
            set head to 180 - head.
        }
    }
    else if inclination < 0 {   // this is copied off the KSP-lib, idk how does the else if work here
        set head to 180 - head.
    }
    local vOrbit is sqrt(body:mu / (orbit_alt + body:radius)).
    local vRotX is vOrbit * sin(head) - vdot(ship:velocity:orbit, heading(90, 0):vector).
    local vRotY is vOrbit * cos(head) - vdot(ship:velocity:orbit, heading(0, 0):vector).
    set head to 90 - arctan2(vRotY, vRotX).
    return mod(head + 360, 360).
}

function AngleToBodyAscendingNode {
    parameter ves is ship.

    local joinVector is OrbitLAN(ves).
    local angle is vang((ves:position - ves:body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(OrbitBinormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}

function AngleToBodyDescendingNode {
    parameter ves is ship.

    local joinVector is -OrbitLAN(ves).
    local angle is vang((ves:position - ves:body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(OrbitBinormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}

function OrbitBinormal {
    parameter ves is ship.

    return vcrs((ves:position - ves:body:position):normalized, OrbitTangent(ves)):normalized.
}

function TargetBinormal {
    parameter ves is target.

    return vcrs((ves:position - ves:body:position):normalized, OrbitTangent(ves)):normalized.
}

function OrbitLAN {
    parameter ves is ship.

    return angleAxis(ves:orbit:LAN, ves:body:angularVel:normalized) * solarPrimeVector.
}

function OrbitTangent {
    parameter ves is ship.

    return ves:velocity:orbit:normalized.
}

function RelativeNodalVector {
    parameter OrbitBinormal is OrbitBinormal().
    parameter TargetBinormal is TargetBinormal().

    return vcrs(OrbitBinormal, TargetBinormal):normalized.
}

function AngToRAN {
    parameter OrbitBinormal is OrbitBinormal().
    parameter TargetBinormal is TargetBinormal().

    local joinVector is RelativeNodalVector(OrbitBinormal, TargetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(OrbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}

function AngToRDN {
    parameter OrbitBinormal is OrbitBinormal().
    parameter TargetBinormal is TargetBinormal().

    local joinVector is -RelativeNodalVector(OrbitBinormal, TargetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(OrbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}

function TimeToNode {
	local TA0 is ship:orbit:trueanomaly. 
	local ANTA is mod(360 + TA0 + AngToRAN(), 360).	// TA is True Anomaly
	local DNTA is mod(ANTA + 180, 360).

	// 1 is AN, 2 is DN
	local ecc is ship:orbit:eccentricity.
	local SMA is ship:orbit:semimajoraxis.

	local t0 is time:seconds.
	local MA0 is mod(mod(t0 - ship:orbit:epoch, ship:orbit:period) / ship:orbit:period * 360 + ship:orbit:meananomalyatepoch, 360).

	local EA1 is mod(360 + arctan2(sqrt(1 - ecc^2) * sin(ANTA), ecc + cos(ANTA)), 360).
	local MA1 is EA1 - ecc * constant:radtodeg * sin(EA1).
	local t1 is mod(360 + MA1 - MA0, 360) / sqrt(ship:body:mu / SMA^3) / constant:radtodeg + t0.

	local EA2 is mod(360 + arctan2(sqrt(1 - ecc^2) * sin(DNTA), ecc + cos(DNTA)), 360).
	local MA2 is EA2 - ecc * constant:radtodeg * sin(EA2).
	local t2 is mod(360 + MA2 - MA0, 360) / sqrt(ship:body:mu / SMA^3) / constant:radtodeg + t0.

	return min(t2 - t0, t1 - t0).
}

function NodePlaneChange {
	local TA0 is ship:orbit:trueanomaly. 
	local ANTA is mod(360 + TA0 + AngToRAN(), 360).	// TA is True Anomaly
	local DNTA is mod(ANTA + 180, 360).

	local SMA is ship:orbit:semimajoraxis.
	local ecc is ship:orbit:eccentricity.

	local rad1 is SMA * (1 - ecc * cos(ANTA)).
	local rad2 is SMA * (1 - ecc * cos(DNTA)).

	local Vv1 is sqrt(ship:body:mu * ((2 / rad1) - (1 / SMA))).
	local Vv2 is sqrt(ship:body:mu * ((2 / rad2) - (1 / SMA))).

	local angChange1 is (2 * Vv1 * sin(Trig() / 2)).
	local angChange2 is (2 * Vv2 * sin(Trig() / 2)).

	return min(angChange1, angChange2).
}

function DirCorr {
    wait 0.
    if (hasTarget = true) {
        local dirCorrVal is 1. 

        if (abs(AngToRAN()) > abs(AngToRDN())) { set dirCorrVal to 1. }
        else { set dirCorrVal to -1. }

        return dirCorrVal.
    } else { return 1. }
}

function Trig {
	parameter res is "angChange".	// add parameters as much as you can squeeze out in this trigonometry relations

    local i1 is ship:orbit:inclination.
    local i2 is target:orbit:inclination.
    local o1 is ship:orbit:lan.
    local o2 is target:orbit:lan.

    local a1 is sin(i1) * cos(o1).
    local a2 is sin(i1) * sin(o1).
    local a3 is cos(i1).

    local b1 is sin(i2) * cos(o2).
    local b2 is sin(i2) * sin(o2).
    local b3 is cos(i2).

	local angChange is arccos((a1 * b1) + (a2 * b2) + (a3 * b3)).

	if (res = "angChange") { return angChange. }
}

// HOHMANN TRANSFER TIMING AND DELTAV

function PhaseAngle {
	local transferSMA is (target:orbit:semimajoraxis + ship:orbit:semimajoraxis) / 2.
	local transferTime is (2 * constant:pi * sqrt(transferSMA^3 / ship:body:mu)) / 2.
	local transferAng is 180 - ((transferTime / target:orbit:period) * 360).

	local univRef is ship:orbit:lan + ship:orbit:argumentofperiapsis + ship:orbit:trueanomaly.
	local compareAng is target:orbit:lan + target:orbit:argumentofperiapsis + target:orbit:trueanomaly.
	local phaseAng is (compareAng - univRef) - 360 * floor((compareAng - univRef) / 360).
	
    local DegPerSec is  (360 / ship:orbit:period) - (360 / target:orbit:period).
    local angDiff is transferAng - phaseAng.

    local t is angDiff / DegPerSec.

	return abs(t).
}

function Hohmann {
	parameter burn.

	if (burn = "raise") {
		local targetSMA is ((target:altitude + ship:altitude + (ship:body:radius * 2)) / 2).
		local targetVel is sqrt(ship:body:mu * (2 / (ship:body:radius + ship:altitude) - (1 / targetSMA))).
    	local currentVel is sqrt(ship:body:mu * (2 / (ship:body:radius + ship:altitude) - (1 / ship:orbit:semimajoraxis))).
	
		return (targetVel - currentVel). 
	}
	else if (burn = "circ") {
		local targetVel is sqrt(ship:body:mu / (ship:orbit:body:radius + ship:orbit:apoapsis)).
    	local currentVel is sqrt(ship:body:mu * ((2 / (ship:body:radius + ship:orbit:apoapsis) - (1 / ship:orbit:semimajoraxis)))).
    	
		return (targetVel - currentVel).
	}		
}

function ExecNode {
	parameter 
        maxT is ship:maxthrust, 
        isRCS is false, 
        ctrlfacing is "fore".   // either "fore" or "top"
	rcs off.

	// maneuver timing and preparation
    steeringmanager:resettodefault().
    set steeringmanager:maxstoppingtime to 3.5.
    lock normVec to vcrs(ship:prograde:vector, body:position).
    lock steering to lookdirup(
        ship:prograde:vector,
        normVec).

    local nd is nextnode.
    local maxAcc is maxT / ship:mass.
    local burnDuration is nd:deltav:mag / maxAcc.
    kuniverse:timewarp:warpto(time:seconds + nd:eta - (burnDuration / 2 + 60)).
    wait until nd:eta <= (burnDuration / 2 + 30).
    
	if (isRCS = true) rcs on.
	else rcs off.

    lock nv to nd:deltav:normalized.    //makes sure that the parameter set will update
    set dv0 to nd:deltav.

    if (ctrlfacing = "fore") {
        lock steering to lookdirup(
            nv, 
            normVec).
    } else {
        lock steering to lookdirup(
            ship:prograde:vector, // should always point pro
            normVec). //should always point starboard
    }

    // maneuver execution

    until nd:eta <= (burnDuration + 10) { wait 0. }
	if (isRCS = true) rcs on.
	else rcs off.
    wait until nd:eta <= (burnDuration / 2).

    set burnDone to false.

    until burnDone
    {
        wait 0.
        set maxAcc to maxT / ship:mass.

        if (isRCS = false)
            set throt to min(nd:deltav:mag / maxAcc, 1).
        else
            RCSTranslate(nv).

        if (nd:deltav:mag < 0.1)
        {
            set ship:control:neutralize to true.
            set throt to 0.
            set burnDone to true.
        }   
    }

    remove nextnode.
    set ship:control:neutralize to true.
    set throt to 0. rcs off.
    set ship:control:pilotmainthrottle to 0.
    lock steering to lookdirup(
        ship:prograde:vector,
        normVec).
    wait 5.
}

function RCSTranslate {
    parameter tarVec. // tarDist.
    if tarVec:mag > 1 set tarVec to tarVec:normalized.

    // nullifies redundant controls
    set ship:control:fore to tarVec * ship:facing:forevector.
    set ship:control:starboard to tarVec * ship:facing:starvector.
    set ship:control:top to tarVec * ship:facing:topvector.

    wait 0.
}

function BurnLengthRCS {
    // gets the time for rcs to complete a maneuver
    parameter thrust, dv.

    local rcsship is ship:partstagged("Cmodule")[0].
    local mod is rcsship:getmodule("ModuleRCSFX").
    local isp is mod:getfield("rcs isp").
    local g is constant:g0.
    local dMass is ship:mass / (constant:e^ (dv / (isp * g))).
    local flowRate is thrust / (isp * g).

    local dT is (ship:mass - dMass) / flowRate.

    return dT.
}


// LANDING CALCULATION AND SIMULATION

function LandHeight0 {
	local shipAcc0 is (ship:availablethrust / ship:mass) - (body:mu / body:position:sqrmagnitude).
	local distance0 is ship:verticalspeed^2 / (2 * shipAcc0).
	
	return distance0.
}

function LandThrottle {
	local targetThrot is (LandHeight0() / (trueAltitude - 5)).
	
	return max(targetThrot, 0.6).
}

function SimSpeed {
    local time0 is time:seconds.
	local oldSpeed is ship:airspeed.
	wait 0.1.
    local time1 is time:seconds.
	local newSpeed is ship:airspeed.

    local deltaTime is time1 - time0.
	local deltaSpeed is (newSpeed - oldSpeed) * deltaTime.

	return ship:airspeed - deltaSpeed - DragValue().
}

function LandHeight1 {
	local shipAcc1 is (ship:availablethrust / ship:mass) - (body:mu / body:position:sqrmagnitude).
	local distance1 is SimSpeed()^2 / (2 * shipAcc1).
	
	return distance1.
}

function DragValue {
	local vel0 is ship:velocity:surface.
    local time0 is time:seconds.
    local mass0 is ship:mass.

    wait 0.
    local vel1 is ship:velocity:surface.
    local time1 is time:seconds.
    local grav is (body:mu / body:position:sqrmagnitude) * -up:vector. // * ship:mass.
    local accel is ship:facing:forevector * ship:availablethrust * throttle.
    local mass1 is ship:mass.

    local deltaTime is time1 - time0.
    local drag1 is (vel1 - (vel0 + grav + accel)) * deltaTime.
        
    local dragForce is ((mass0 + mass1) / 2) * vdot(drag1, ship:facing:forevector).
        
    set vel0 to vel1.
    set time0 to time1.
    set mass0 to mass1.

    return dragForce.
}

function Trajectories {
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
	} else {
		if nav = "lat" {
			return ship:geoposition:lat.
		}
		else {
			return ship:geoposition:lng.
		}
	}
}

function DeltaTrajectories {
	set oldTraj to Trajectories("dist").
	wait 0.1.
	
	set newTraj to Trajectories("dist").
	set deltaTraj to (newTraj - oldTraj) / 10.
	set oldTraj to newTraj.
	return deltaTraj.
	//the booster will stop when it detects that its impactpos is getting 
    // farther rather than getting nearer every 0.1 second.
}

// NAV-BALL ANGLES

function ForwardVec {
	local forwardPitch is 90 - vang(ship:up:vector, ship:facing:forevector).
	return forwardPitch.
}

function RetroDiff {
	parameter retMode. // UP = retro angle from radial out, RETRO = AoA from retrograde
	if retMode = "UP" {
		local rtrDiff is 90 - vang(ship:up:vector:normalized, ship:srfretrograde:vector:normalized).
		return rtrDiff.
	} else {
		local rtrDiff is 90 - vang(ship:facing:forevector, ship:srfretrograde:vector:normalized).
		return rtrDiff.
	}
}