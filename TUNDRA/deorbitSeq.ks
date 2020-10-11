// Rodan and Gigan v0.1 -- Deorbit Script
clearscreen.
// core:part:getmodule("kOSProcessor"):doEvent("Open Terminal").

set shipPort to ship:partstagged("APAS")[0].

// wait 5.
if (shipPort:hasparent) {
    shipPort:undock().
}
lock normVec to vcrs(ship:prograde:vector, -body:position). // solar panels facing away the body
lock steering to lookdirup(
    ship:prograde:vector,
    normVec).
wait 2.

rcs on.
set ship:control:fore to -0.1.  // back away from station
wait 3.
set ship:control:fore to 0.

StartUp().
Main(40000, 7000, 127.5).   // Pe, Chutes, LNG

function StartUp {
    // !! MUN IS SET AS REFERENCE BECAUSE IT HAS 0 REL. INCLINATION TOWARDS THE KSC !!
    set target to mun.
    runoncepath("0:/TUNDRA/missionParameters").
    runoncepath("0:/TUNDRA/libGNC").
    runoncepath("0:/TUNDRA/launchWindow").
}

function Main {
    parameter peAlt, chuteAlt, burnLNG. 
    if (abs(target:orbit:inclination - ship:orbit:inclination) > 1) {
        MatchPlanes().
    } else {
        print "RELATIVE INCLINATION IS TOO CLOSE, SKIPPING PLANE MATCH".
    }

    ag5 on. // trunk decouple

    until ship:geoposition:lng > burnLNG - 10 and ship:geoposition:lng < burnLNG + 1 {
        print round(ship:geoposition:lng, 3) at (0, 1).
    }
    kuniverse:timewarp:cancelwarp().

    until ship:geoposition:lng > burnLNG and ship:geoposition:lng < burnLNG + 1{
        print round(ship:geoposition:lng, 3) at (0, 1).
    }
    
    lock steering to lookdirup(
        ship:prograde:vector,
        normVec).
    rcs on.
    set ship:control:fore to -1. // DEORBIT BURN

    wait until ship:periapsis < peAlt.
    set ship:control:fore to 0.

    wait 10.
    lock steering to lookdirup(
        ship:srfretrograde:vector,
        normVec).
    ag4 off. // shroud close
    when (ship:altitude < chuteAlt) then { rcs off. }

    wait until alt:radar < 7000.
    stage.  // chute deploy

    // splashdown
    set ship:control:neutralize to true.
    unlock steering.
    unlock throttle.
}

function MatchPlanes {
    local planeCorrection is 1.

    wait until TimeToNode() < 30 + BurnLengthRCS(1, NodePlaneChange()).

    // planeCorrection is reversed because we are referencing mun yet targeting kerbin
    if (abs(AngToRAN()) > abs(AngToRDN())) { set planeCorrection to 1. }
    else { set planeCorrection to -1. }

    set matchNode to node(time:seconds + TimeToNode(), 0, (NodePlaneChange() * planeCorrection), 0).
    add matchNode.

    ExecNode(4, true).
}