
// INSTANTANEOUS AZIMUTH CALCULATION

function Azimuth 
{
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
    else if inclination < 0 {
        set head to 180 - head.
    }
    local vOrbit is sqrt(body:mu / (orbit_alt + body:radius)).
    local vRotX is vOrbit * sin(head) - vdot(ship:velocity:orbit, heading(90, 0):vector).
    local vRotY is vOrbit * cos(head) - vdot(ship:velocity:orbit, heading(0, 0):vector).
    set head to 90 - arctan2(vRotY, vRotX).
    return mod(head + 360, 360).
}

function AngleToBodyAscendingNode 
{
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

function AngleToBodyDescendingNode 
{
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

function OrbitBinormal 
{
    parameter ves is ship.

    return vcrs((ves:position - ves:body:position):normalized, OrbitTangent(ves)):normalized.
}

function OrbitLAN 
{
    parameter ves is ship.

    return angleAxis(ves:orbit:LAN, ves:body:angularVel:normalized) * solarPrimeVector.
}

function orbitTangent 
{
    parameter ves is ship.

    return ves:velocity:orbit:normalized.
}

// LANDING CALCULATION AND SIMULATION

function LandHeight0
{
	local shipAcc0 is (ship:availablethrust / ship:mass) - (body:mu / body:position:sqrmagnitude).
	local distance0 is ship:verticalspeed^2 / (2 * shipAcc0).
	
	return distance0.
}

function LandThrottle
{
	local targetThrot is (LandHeight0() / (trueAltitude - 5)).
	
	return max(targetThrot, 0.6).
}

function SimSpeed
{
	local oldSpeed is ship:airspeed.
	wait 0.1.
	local newSpeed is ship:airspeed.
	local deltaSpeed is (newSpeed - oldSpeed).
	
	return  ship:airspeed + (deltaSpeed * 10) - DragValue().
}

function LandHeight1 
{
	local shipAcc1 is (ship:availablethrust / ship:mass) - (body:mu / body:position:sqrmagnitude).
	local distance1 is SimSpeed()^2 / (2 * shipAcc1).
	
	return distance1.
}

function DragValue 
{
	local v0 is ship:velocity:surface. local t0 is time:seconds.
	wait 0.05.
	local v1 is ship:velocity:surface. local t1 is time:seconds.
	
	local netForce is ((v1 - v0) / (t1 - t0)) * ship:mass.
	local gravityForce is (body:mu / body:position:sqrmagnitude) * -up:vector * ship:mass.
	local throttleForce is ship:facing:forevector * ship:availablethrust * throttle.
	local dragForce is netForce - gravityForce - throttleForce.
	
	return (dragForce:mag / 500).
}

function Trajectories 
{
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

function DeltaTrajectories 
{
	set oldTraj to Trajectories("dist").
	wait 0.1.
	
	set newTraj to Trajectories("dist").
	set deltaTraj to (newTraj - oldTraj) / 10.
	set oldTraj to newTraj.
	return deltaTraj.
	//the booster will stop when it detects that it is getting farther rather
	//than getting nearer every 0.1 second.
}

// NAV-BALL ANGLES

function ForwardVec 
{
	local forwardPitch is 90 - vang(ship:up:vector, ship:facing:forevector).
	return forwardPitch.
}

function RetroDiff 
{
	parameter retMode. // UP = retro angle from radial out, RETRO = AoA from retrograde
	if retMode = "UP" {
		local rtrDiff is 90 - vang(ship:up:vector:normalized, ship:srfretrograde:vector:normalized).
		return rtrDiff.
	} 
	else {
		local rtrDiff is 90 - vang(ship:facing:forevector, ship:srfretrograde:vector:normalized).
		return rtrDiff.
	}
}
