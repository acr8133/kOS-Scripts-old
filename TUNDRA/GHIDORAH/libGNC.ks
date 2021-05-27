// ORBITAL ELEMENTS CLACULATION [crdts: kOSLib]

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
        topOffset is false,
        maxT is ship:maxthrust, 
        isRCS is false, 
        ctrlfacing is "fore".  // either "fore" or "top"
	rcs off.

	// maneuver timing and preparation
    steeringmanager:resettodefault().
    set steeringmanager:maxstoppingtime to 3.5.
    if (topOffset = false) {
        lock normVec to vcrs(ship:prograde:vector, -body:position).
    } else {
        lock normVec to body:position.
    }
    
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

// RENDEZVOUS AND DOCKING

function MatchPlanes {
    local planeCorrection is 1.

    if (hastarget = false) { wait until hasTarget = true. }

    wait until TimeToNode() < 30 + BurnLengthRCS(1, NodePlaneChange()).

    if (abs(AngToRAN()) > abs(AngToRDN())) { set planeCorrection to 1. }
    else { set planeCorrection to -1. }

    set matchNode to node(time:seconds + TimeToNode(), 0, (NodePlaneChange() * planeCorrection), 0).
    add matchNode.

    ExecNode(false, 6, true, "top").
}

function Burn1 {
    wait 10.
    set burn1Node to node(time:seconds + PhaseAngle(), 0, 0, Hohmann("raise")).
    add burn1Node.

    ExecNode(false, 6, true).
}

function Burn2 {
    wait 10.
    set burn1Node to node(time:seconds + eta:apoapsis, 0, 0, Hohmann("circ")).
    add burn1Node.

    ExecNode(false, 6, true).
}

function Rendezvous {
    parameter tarDist, tarVel, vecThreshold is 0.1.

    local relVel is 0.
    local rendezvousVec is 0.

    lock relVel to ship:velocity:orbit - target:velocity:orbit.
    lock rendezvousVec to target:position - ship:position + (target:prograde:vector:normalized * tarDist).

    set dockPID to pidloop(0.075, 0.00035, 0.06, 0.3, tarVel).
    set dockPID:setpoint to 0.
    lock dockOutput to dockPID:update(time:seconds, (-1 * rendezvousVec:mag)).

    until (rendezvousVec:mag < (vecThreshold * 2.5)) {
        RCSTranslate((rendezvousVec:normalized * (dockOutput)) - relVel).
        print rendezvousVec:mag + "          " at (0, 10).
        print "FUNC: REND" at (0, 11).
    }
    RCSTranslate(v(0,0,0)).
}

function HaltRendezvous {
    parameter haltThreshold is 0.1.

    when relVel:mag < 10 then {
        local lockVecFore is ship:facing:forevector.
        local lockVecTop is ship:facing:topvector.
        lock steering to lookDirUp(lockVecFore, lockVecTop).
        // lock steering if relvel is low enough, initial was saved to avoid spin
    } 

    lock relVel to ship:velocity:orbit - target:velocity:orbit.
    until (relVel:mag < haltThreshold) {
        RCSTranslate(-1 * relVel).
        print "FUNC: HTRD" at (0, 11).
    }
    RCSTranslate(v(0,0,0)).
}

function CloseIn {
    parameter tarDist, tarVel.

    local relVel is 0.
    local dockVec is 0.

    lock relVel to ship:velocity:orbit - targetPort:ship:velocity:orbit.
    lock dockVec to targetPort:nodeposition - shipPort:nodePosition + (targetPort:portfacing:vector * tarDist).

    set dockPID to pidloop(0.1, 0.005, 0.0265, 0.3, tarVel).
    set dockPID:setpoint to 0.
    lock dockOutput to dockPID:update(time:seconds, (-1 * dockVec:mag)).

    until (dockVec:mag < 0.1) {
        RCSTranslate((dockVec:normalized * (dockOutput)) - relVel).
        print dockVec:mag + "          " at (0, 10).
        print "FUNC: CLIN" at (0, 11).

    }
    RCSTranslate(v(0,0,0)).
}

function HaltDock {
    parameter haltThreshold is 0.1.

    lock relVel to ship:velocity:orbit - targetPort:ship:velocity:orbit.
    until (relVel:mag < haltThreshold) {
        RCSTranslate(-1 * relVel).
        print "FUNC: HTDK" at (0, 11).

    }
    RCSTranslate(v(0,0,0)).
}

// LANDING CALCULATION AND SIMULATION

function LandHeight0 {
    parameter burnInt is ship:availableThrust.

	local shipAcc0 is (burnInt / ship:mass) - (body:mu / body:position:sqrmagnitude).
	local distance0 is ship:verticalspeed^2 / (2 * shipAcc0).

	return distance0.
}

function LandThrottle {
    parameter mode is 0.

    local targetThrot is 0.

    if (mode = 0) {
	    set targetThrot to (LandHeight0() / trueAltitude).
    } else {
        set targetThrot to (LandHeight0(ship:availablethrust * 0.333) / trueAltitude).
    }

	return targetThrot.
}

function LandHeight1 {
	local massLoss is -0.165.
	local predMass is ship:mass - (1.5 * massLoss * ((alt:radar / ship:verticalspeed))).
	local weighedMass is (0.31 * ship:mass) + (predMass * 0.69).

	local shipAcc1 is (ship:availablethrust / weighedMass) - (body:mu / body:position:sqrmagnitude).
	local distance1 is SimSpeed()^2 / (2 * shipAcc1).
	
	return distance1.
}

function SimSpeed {
    local time0 is time:seconds.
	local oldSpeed is velocity:surface:mag.
	local predTime is abs(alt:radar / ship:verticalspeed).

    local altScale is max(alt:radar * 0.02, 0).
    local velScale is max(abs(ship:verticalspeed * 0.2), 0).
    local totalScale is altScale + velScale.

	wait 0.01.

	local deltaSpeed is min(0, ((velocity:surface:mag - oldSpeed) * (time:seconds - time0))).
	local predSpeed is min(oldSpeed, velocity:surface:mag + (deltaSpeed * predTime * totalScale)).

	return predSpeed.
}

// CALCULATED IMPACT ETA [crdts:Nuggreat]

function ImpactUT {
    PARAMETER minError is 1.
	IF NOT (DEFINED impact_UTs_impactHeight) { GLOBAL impact_UTs_impactHeight is 0. }
	local startTime is TIME:SECONDS.
	local craftOrbit is SHIP:ORBIT.
	local sma is craftOrbit:SEMIMAJORAXIS.
	local ecc is craftOrbit:ECCENTRICITY.
	local craftTA is craftOrbit:TRUEANOMALY.
	local orbitPeriod is craftOrbit:PERIOD.
	local ap is craftOrbit:APOAPSIS.
	local pe is craftOrbit:PERIAPSIS.
	local impactUTs is TimeTwoTA(ecc,orbitPeriod,craftTA,AltToTA(sma,ecc,SHIP:BODY,MAX(MIN(impact_UTs_impactHeight,ap - 1),pe + 1))[1]) + startTime.
	local newImpactHeight is max(0, GroundTrack(POSITIONAT(SHIP,impactUTs),impactUTs):TERRAINHEIGHT).
	SET impact_UTs_impactHeight TO (impact_UTs_impactHeight + newImpactHeight) / 2.
	RETURN LEX("time",impactUTs,//the UTs of the ship's impact
	"impactHeight",impact_UTs_impactHeight,//the aprox altitude of the ship's impact
	"converged",((ABS(impact_UTs_impactHeight - newImpactHeight) * 2) < minError)).//will be true when the change in impactHeight between runs is less than the minError
}

function AltToTA {
    //returns a list of the true anomalies of the 2 points where the craft's orbit passes the given altitude
	PARAMETER sma,ecc,bodyIn,altIn.
	local rad is altIn + bodyIn:RADIUS.
	local taOfAlt is ARCCOS((-sma * ecc^2 + sma - rad) / (ecc * rad)).
	RETURN LIST(taOfAlt,360-taOfAlt).//first true anomaly will be as orbit goes from PE to AP
}

function TimeTwoTA {
    //returns the difference in time between 2 true anomalies, traveling from taDeg1 to taDeg2
	PARAMETER ecc,periodIn,taDeg1,taDeg2.
	
	local maDeg1 is TrueAToMeanA(ecc,taDeg1).
	local maDeg2 is TrueAToMeanA(ecc,taDeg2).
	
	local timeDiff is periodIn * ((maDeg2 - maDeg1) / 360).
	
	RETURN MOD(timeDiff + periodIn, periodIn).
}

function TrueAToMeanA {
    //converts a true anomaly(degrees) to the mean anomaly (degrees) NOTE: only works for non hyperbolic orbits
	PARAMETER ecc,taDeg.
	local eaDeg is ARCTAN2(SQRT(1-ecc^2) * SIN(taDeg), ecc + COS(taDeg)).
	local maDeg is eaDeg - (ecc * SIN(eaDeg) * CONSTANT:RADtoDEG).
	RETURN MOD(maDeg + 360,360).
}

function GroundTrack {	
    //returns the geocoordinates of the ship at a given time(UTs) adjusting for planetary rotation over time, only works for non tilted spin on bodies 
	PARAMETER pos,posTime,localBody is SHIP:BODY.
	local bodyNorth is v(0,1,0).//using this instead of localBody:NORTH:VECTOR because in many cases the non hard coded value is incorrect
	local rotationalDir is VDOT(bodyNorth,localBody:ANGULARVEL) * CONSTANT:RADTODEG. //the number of degrees the body will rotate in one second
	local posLATLNG is localBody:GEOPOSITIONOF(pos).
	local timeDif is posTime - TIME:SECONDS.
	local longitudeShift is rotationalDir * timeDif.
	local newLNG is MOD(posLATLNG:LNG + longitudeShift,360).
	IF newLNG < - 180 { SET newLNG TO newLNG + 360. }
	IF newLNG > 180 { SET newLNG TO newLNG - 360. }
	RETURN LATLNG(posLATLNG:LAT,newLNG).
}

function Impact {
    parameter nav.

    local impData is ImpactUT().
    local impLatLng is GroundTrack(POSITIONAT(SHIP,impData["time"]),impData["time"]).

    if (nav = "lat") { return impLatLng:lat. }
    else if (nav = "lng") { return impLatLng:lng. }
    else { return sqrt(((impLatLng:lat - LZ:lat)^2) + ((impLatLng:lng - LZ:lng)^2)). }
}

function DeltaImpact { 
    local oldTraj is Impact("dist").
    local oldTime is time:seconds.

    wait 0.

    return ((Impact("dist") - oldTraj) / (time:seconds - oldTime)).
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