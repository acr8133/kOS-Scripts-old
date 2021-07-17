// GHIDORAH v2.0.0a -- PAYLOAD

clearScreen.
// core:part:getmodule("kOSProcessor"):doEvent("Open Terminal").

StartUp().
Main().

function StartUp {

    // run prerequitistes (load functions to cpu)
    runoncepath("0:/TUNDRA/libParams.ks", 2).
    runoncepath("0:/TUNDRA/libGNC").
    runoncepath("0:/TUNDRA/launchTimings", "ground", 2).

    wait until goForLaunch.
    if (payloadType = "rodan") { AbortInitialize(). }

    // initialize variables
    set steeringmanager:rollts to 20.
    set targetPitch to 90.
    set fairingLock to false.
    set throt to 0.
    lock throttle to throt.

    // profile variables
    set targetAzimuth to Azimuth(DirCorr() * targetInc, targetOrb). 
    set ctrlOverride to ((maxPayload - payloadMass) / 10000) * 3.125.
}

function Main {

    Liftoff(30).
    GravityTurn(0).
    if (recoveryMode = "Heavy") { BECO(). GravityTurn(1). }
    MECO().
    BurnToApoapsis().
    Circularize().
    SepSequence(). 
    if (hasTarget) {
        Burn1().
        Burn2().
        MatchPlanes().
        MainDocking().
        wait 10. 
        shutdown.
    }
}

function MainDocking {
    
    rcs on. wait 10.
    lock steering to lookdirup(ship:velocity:orbit - target:velocity:orbit, vcrs(ship:prograde:vector, -body:position)).
    
    wait until (vang(ship:facing:forevector, ship:velocity:orbit - target:velocity:orbit) < 2.5).
    HaltRendezvous(0.5).
    lock steering to lookdirup(target:position, vcrs(target:position, -body:position)).
    
    wait until (vang(ship:facing:forevector, target:position) < 1).
    Rendezvous(500, 15, 10).
    Rendezvous(170, 5, 0.5).

    set shipPort to ship:partstagged("APAS")[0].
    set targetPort to target:partstagged("APAS")[0].
    
    CloseIn(50, 2).
    HaltDock().
    CloseIn(15, 1).
    HaltDock().

    lock steering to lookdirup(
        -1 * targetPort:portfacing:vector,
        vcrs(ship:prograde:vector, body:position)).
    CloseIn(0.5, 0.75).    // docking magnet capture
    unlock steering.
    sas on. rcs off.
}

function Liftoff {
    parameter kickAlt.
    
    EngineSpool(1).
    wait 1. stage.

    lock steering to lookdirup(
        heading(90, 90):vector,
        ship:facing:topvector).

    wait until ship:verticalspeed > kickAlt.
}

function GravityTurn {
    parameter mode.

    lock throtLimiter to max(0, ship:airspeed - 450) / 450.
    lock steering to lookdirup(
        heading(targetAzimuth, targetPitch):vector,
        heading(180 - (DirCorr() * targetInc), 0):vector).

    lock throt to max(min(
        1 - (10 * ((-1 * MaxQ) + ship:q)), 1) - 
        throtLimiter, 0.85).

    //NOT HEAVY VARIANT
    if (mode = 0) {
        if (recoveryMode = "Full") {
            until ship:availablethrust <= 0.1 { wait 0.
                set targetPitch to 
                    max(
                    (90 * (1 - alt:radar /
                    (targetAp * pitchGain)
                    ))
                    , MECOangle + ctrlOverride).
            }
        } else {
            until (ship:apoapsis > targetAp) { wait 0.
                set targetPitch to 
                    max(
                    (90 * (1 - alt:radar /
                    (targetAp * pitchGain)
                    ))
                    , MECOangle + ctrlOverride).
                }
        }
    } 
    
    // HEAVY VARIANT
    else {
        until (ship:apoapsis > (targetAp + targetOrb) / 2) { wait 0.
            set targetPitch to 
                min(max(
                (90 * (1 - alt:radar /
                (((targetAp + targetOrb) / 2) * pitchGain)
                ))
                , MECOangle - 10 + ctrlOverride), MECOangle).
        }
    } 
}

function BECO {

    lock steering to lookdirup(
        heading(targetAzimuth, MECOangle + ctrlOverride):vector,
        heading(180 - (DirCorr() * targetInc), 0):vector).

    EngineSpool(0.85).
    toggle AG3. // shutdown booster engines, keep core running
    wait 2. stage. wait 2.
}

function MECO {
    
    if (recoveryMode = "Heavy") { set MECOangleOffset to 10. }
    else { set MECOangleOffset to 0. }

    lock steering to lookdirup(
        heading(targetAzimuth, MECOangle - MECOangleOffset + ctrlOverride):vector,
        heading(180 - (DirCorr() * targetInc), 0):vector).

    EngineSpool(0).
    wait 2. stage. 
    core:part:controlfrom(). wait 2.
}

function BurnToApoapsis {

    EngineSpool(0.1, true). // dont burn the Interstage
    wait 1.
    EngineSpool(1).
    lock steering to lookdirup(
        heading(targetAzimuth, MECOangle + ctrlOverride):vector,
        heading(180 - (DirCorr() * targetInc), 0):vector).
    
    wait until ship:altitude > 35000.   // will change to prograde angle 
    lock throt to min(
        max(0.333, (targetOrb - ship:apoapsis) / (targetOrb - atmHeight)) + 
        max(0, ((60 - eta:apoapsis) * 0.075))
    , 1).
    lock steering to lookdirup(
        heading(targetAzimuth, targetPitch):vector,
        heading(180 - (DirCorr() * targetInc), 0):vector).

    until (ship:apoapsis > targetOrb) {
        local avoidFireDeath is 5 * max(0, ((30 - eta:apoapsis) * 0.075)).
        set targetPitch to
            min(max(
            (90 * (1 - alt:radar / tangentAltitude)), 
            0) + avoidFireDeath, (MECOangle + ctrlOverride)).

        // stage once if ship has fairings, too lazy to check if code uses 'fairing' or 'fairings'
        if (payloadType = "gigan" or payloadType = "fairing" or payloadType = "fairings") { wait 0.
            if (ship:altitude > fairingSepAlt and fairingLock = false) { wait 0.
                stage.
                set fairingLock to true.

            } else { wait 0. }
        }
    }
    set throt to 0.
    lock steering to lookdirup(
        ship:prograde:vector,
        heading(180 - (DirCorr() * targetInc), 0):vector).
    wait 3.
    wait until ship:altitude > atmHeight + 700. // do not make maneuvers inside an atmosphere
    steeringmanager:resettodefault().
}

function Circularize {
    
    set circNode to VecToNode(Hohmann("circ", targetOrb), time:seconds + TimeToAltitude(targetOrb)).
    add circNode.

    ExecNode().
}

function SepSequence {
    
    stage.      // separate to second stage.
    wait 10.

    if (payloadType = "gigan") { // gigan has extra fairings 
        stage. wait 3. 
        panels on.  rcs off.
    } 
    else if (payloadType = "rodan") { // rodan has a shroud
        lights on. AG4 on. wait 5.
        
        lock steering to lookdirup(     // point panels away from body
            ship:prograde:vector,
            vcrs(ship:prograde:vector, -body:position)).
    }
}

function EngineSpool {
    parameter tgt, ullage is false.
    
    local startTime is time:seconds.
    local throttleStep is 0.0005.

    if (ullage) { 
        rcs on. 
        set ship:control:fore to 0.75.
        
        when (time:seconds > startTime + 2) then { 
            set ship:control:neutralize to true. rcs off. 
        }
    }

    if (throt < tgt) {
        if (ullage) { set throt to 0.025. wait 0.5. }
        until throt >= tgt { set throt to throt + throttleStep. }
    } else {
        until throt <= tgt { set throt to throt - throttleStep. }
    }

    set throt to tgt.
}

function AbortInitialize {
    
    on abort {
        if (ship:airspeed < 5 or ship:altitude < 50000) {
            lock throt to 1.
            lock steering to lookdirup(
                up:vector,
                ship:facing:topvector).
        } else {
            lock steering to lookdirup(
                srfprograde:vector,
                ship:facing:topvector).
        }
        wait 3.
        lock steering to lookdirup(
            srfprograde:vector,
            ship:facing:topvector).

        wait until ship:verticalspeed < 50.
        toggle AG5.     // remove trunk

        wait until ship:verticalspeed < -25.
        unlock steering. unlock throttle.
        stage.  // parachutes
    }
}

until false {wait 0.}