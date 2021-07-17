// GOJIRA v0.0.1 -- SECOND STAGE-LAND

on ag10 { reboot. }

clearScreen.
// core:part:getmodule("kOSProcessor"):doEvent("Open Terminal").

StartUp_1(). 
Main_1().

function StartUp_1 {


    // run prerequitistes (load functions to cpu)
    runoncepath("0:/TUNDRA/libParams", 1).
    runoncepath("0:/TUNDRA/libGNC").
    // runoncepath("0:/TUNDRA/launchTimings", "coords", 1).

    // wait until goForLaunch = true.
    
    print "NOW ATTEMPTING TO LAND" at (0, 1).

    // control variables
    set throt to 0.
    lock throttle to throt.

    // initialize variables
    lock trueAltitude to alt:radar - 22.3964.

    // steeringmanager retune
    set steeringmanager:maxstoppingtime to 1.
    set steeringmanager:pitchpid:kd to steeringmanager:pitchpid:kd + 5.
	set steeringmanager:yawpid:kd to steeringmanager:yawpid:kd + 5.

    PIDvalue().
    PIDload().

    wait 1.
}

function Main_1 {
    MatchPlanes("coords", "starship").
    LowerOrbit(atmHeight + 25000).
    Deorbit(-100).
    CtrlPnt("Docking").
    Reentry().
    Land().
}

function LowerOrbit {
    parameter orbitHeight.

    local normVec is vcrs(velocity:orbit, body:position).
    
    if (Ishyness(apoapsis, orbitHeight, 99) = false) {
    
        kuniverse:timewarp:warpto(time:seconds + eta:periapsis - 30).

        // make sure orbit 'touches' target orbit to avoid NaN errors
        if (apoapsis > orbitHeight) {
            lock steering to lookDirUp(retrograde:vector, normVec).
            wait until eta:periapsis < 1.
            set throt to 0.1.
            wait until periapsis <= orbitHeight.
            set throt to 0.
        } else {
            lock steering to lookDirUp(prograde:vector, -normVec).
            wait until eta:periapsis < 1.
            set throt to 0.1.
            wait until apoapsis >= orbitHeight.
            set throt to 0.
        }

        set circNode to VecToNode(Hohmann("circ", orbitHeight), time:seconds + TimeToAltitude(orbitHeight)).
        add circNode.

        ExecNode().
    }
}

function Deorbit {
    parameter deorbitLng.
    
    until false { 
        if (Ishyness(ship:geoposition:lng, deorbitLng, 99.5)) {
            break.
        }
    }

    lock steering to retrograde.

    set burnNode to node(time:seconds + 30, 0, 0, -810).
    add burnNode.
  
    ExecNode().
}

function Reentry {

    // wait 1.
    toggle AG4. 
    steeringManager:resettodefault().
    
    rcs on.
    lock steering to lookDirUp(srfRetrograde:vector, up:vector).

    wait until vang(ship:facing:forevector, srfRetrograde:vector) < 1.

    lock LATvector to vxcl(up:vector, (
		latlng(ship:geoPosition:lat - 0.01, ship:geoPosition:lng):position
		)):normalized.

    lock LNGvector to vxcl(up:vector, (
		latlng(ship:geoPosition:lat, ship:geoPosition:lng + 0.01):position
		)):normalized.

    lock tangentToShip to (Impact("latlng"):position + (vxcl(up:vector, -1 * (ship:position - Impact("latlng"):position)):normalized * max(120, min(alt:radar * 0.045, 1000)))).
    
    lock steering to lookdirup((
		ship:srfretrograde:vector:normalized * 10 +
		LATvector * AlatError * -(AoAlimiter * 2) +
		LNGvector * AlngError * (AoAlimiter * 2)),
		up:vector + LNGvector).

    until altitude < 20000 {
        print OvershootAlt at (0, 15).
    }	

    set steeringManager:maxstoppingtime to steeringManager:maxstoppingtime + 200.
    set steeringManager:rollcontrolanglerange to 180.

    lock tangentToShip to (Impact("latlng"):position + (vxcl(up:vector, -1 * (ship:position - Impact("latlng"):position)):normalized * max(120, min(alt:radar * 0.045, 1000)))).

    // set avd to vecDraw(ship:position, ship:facing:topvector
    //     , red, " ", 2.0, true).
    // set avd:vectorupdater to { return tangentToShip. }.

    lock steering to lookdirup((
		ship:srfretrograde:vector:normalized * 10 +
		LATvector * AlatError * -(AoAlimiter * 3) +
		LNGvector * AlngError * (AoAlimiter * 3)),
		LZ:altitudeposition(alt:radar)).	

    set OvershootAlt to 0.

    until alt:radar < 3000 {
        
        print OvershootAlt at (0, 17).

        print vang(vxcl(up:vector, LZ:position), vxcl(up:vector, Impact("latlng"):position)) at (0, 15).
    }

    lock tangentToShip to (Impact("latlng"):position + (vxcl(up:vector, -1 * (ship:position - LZ:position)):normalized * max(120, min(alt:radar * 0.045, 1000)))).

    lock steering to lookdirup((
            ship:srfretrograde:vector:normalized * 10 +
            LATvector * AlatError * -(AoAlimiter * 2.5) +
            LNGvector * AlngError * (AoAlimiter * 2.5)),
            ship:facing:topvector).	
    
}

function Land {
    global trueAltitude is alt:radar - 22.3964.
    runpath("0:/TUNDRA/libGNC").
    lock trueAltitude to alt:radar - 22.3964.

    lock landApprox to LandHeight1().
    toggle AG2.
    wait until trueAltitude <= (landApprox * 5) or alt:radar < 1000. // 'or' acts as fail-safe condition

    rcs on.
    lock steering to lookDirUp(srfRetrograde:vector, ship:facing:topvector).
    set steeringManager:rollcontrolanglerange to 5.
    wait 5. toggle AG4.
    lock throt to 1. toggle AG5.

    local flipParam is 0.
    lock steering to lookDirUp(heading(90, flipParam):vector, ship:facing:topvector).

    until flipParam >= 90 { wait 0.025.
        set flipParam to flipParam + 10.
    }

    CtrlPnt("Forward").

    HlatPID:reset().
	HlngPID:reset().
	lock steering to lookdirup((
		LATvector * HlatError * -1000 + 
		LNGvector * HlngError * 1000 + 
		(-ship:velocity:surface:normalized * 2 + up:vector * 8)), 
		ship:facing:topvector).

    until ship:verticalspeed > -20 { print Impact("dist") at (0, 5). }    // try to reduce velocity as much as possible to avoid making body lift
	lock throt to 1.125 * ((ship:mass * 9.81) / max(ship:availablethrust, 0.001)).	// vertical velocity hold (avoids bounce too)
    until ship:verticalspeed > -15 { print Impact("dist") at (0, 5). }
    lock throt to max(0.333, LandThrottle()).
    gear on.

    until ship:verticalspeed > -5 { print Impact("dist") at (0, 5). }
	lock throt to 1 * ((ship:mass * 9.81) / max(ship:availablethrust, 0.001)).	// vertical velocity hold (avoids bounce too)
    
	wait until ship:status = "LANDED".
	lock throt to 0.2 * ((ship:mass * 9.81) / max(ship:availablethrust, 0.001))..
	
	wait 1.
    set ship:control:pilotmainthrottle to 0.
	unlock steering.
	unlock throttle.
	wait 5.
}

function PIDvalue {
    // atmospheric gridfins
	set atmP to 17.
	set atmI to 3.
	set atmD to 0.275.
	
	set AlatP to atmP.
	set AlatI to atmI.
	set AlatD to atmD.
	set AlatError to 0.
	
	set AlngP to atmP.
	set AlngI to atmI.
	set AlngD to atmD.
	set AlngError to 0.
	
	// engine gimbal
	set hvrP to 2.25.
	set hvrI to 0.
	set hvrD to 0.1.
	
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
	set AlatPID to pidloop(AlatP, AlatI, AlatD, -0.1, 0.1).
	set AlatPID:setpoint to LZ:lat.	
	
	set AlngPID to pidloop(AlngP, AlngI, AlngD, -0.1, 0.1).
	set AlngPID:setpoint to LZ:lng.

	lock OvershootAlt to min(100, alt:radar * 0.00005).

    lock AlatError to AlatPID:update(time:seconds, ship:body:geoPositionof(tangentToShip):lat).
	lock AlngError to AlngPID:update(time:seconds, ship:body:geoPositionof(tangentToShip):lng).

	set HlatPID to pidloop(HlatP, HlatI, HlatD, -0.001, 0.001).
	set HlatPID:setpoint to LZ:lat.	
	
	set HlngPID to pidloop(HlngP, HlngI, HlngD, -0.001, 0.001).
	set HlngPID:setpoint to LZ:lng.
	
	lock HlatError to HlatPID:update(time:seconds, Impact("lat")).
	lock HlngError to HlngPID:update(time:seconds, Impact("lng")).
}

function Ishyness {
    parameter a, b, threshold.

    local ishyVal is (a/b) * 100.
    
    print ishyVal at (0, 11).
    if ((ishyVal > threshold) and (ishyVal < (200 - threshold))) {
        return true.
    } else {
        return false.
    }
}

function CtrlPnt {
    parameter ctrl.
    
    local ctrlString is "control point: " + ctrl:tostring.
    print ctrlString + "     " at (0, 5).
    local modcom is core:part:getmodule("ModuleCommand").
    
    local eventNames is list(
        "control point: Docking",
        "control point: Forward",
        "control point: Side").
    
    local i is 0.
    until (modcom:HASEVENT(ctrlString)) {
        if (modcom:hasevent(eventNames[i])) {
            modcom:doevent(eventNames[i]).
        }
        set i to mod(i + 1, eventNames:length).
    }
}

until false { wait 0. }