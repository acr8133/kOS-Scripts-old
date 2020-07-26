// Ghidorah v0.6 -- Second Stage Script
clearscreen.

until AG10 wait 1.

StartUp().
Main().

function Main 
{
    toggle AG3. // strongback retract
    set throt to 1.
    wait 1.
    stage.

    // function calls
    Liftoff(25).  // pitch kick altitude
    GravityTurn(0.9).  // maxq throttle
    MECO(). // --
    BurnToApoapsis(). // --
    Circularize(). // --

}

function StartUp 
{
    // run prerequisites
    runoncepath("0:/missionParameters.ks").
    runoncepath("0:/gncFunc").

    // control variables
    set throt to 0.
    lock throttle to throt.

    // profile variables
    set targetAzimuth to Azimuth(targetInc, targetOrb).
    set ctrlOverride to 
        ((maxPayload - payloadMass) / 10000) * 3.125.
    set ctrlMax to 35.

    // init
    set targetPitch to 90.
    set fairingLock to false.
}

function Liftoff
{
    parameter kickAlt.
    
    lock steering to lookdirup(
        heading(90, 90):vector,
        ship:facing:topvector).

    wait until ship:verticalspeed > kickAlt.
}

function GravityTurn 
{
    parameter MaxQThrottle.

    lock steering to lookdirup(
        heading(targetAzimuth, targetPitch):vector,
        heading(180 - targetInc, 0):vector).

    until (ship:apoapsis > targetAp)
    {
        wait 0.

        if (ship:q > MaxQ)
            set throt to (MaxQThrottle - throttleComp).
        else
            set throt to (0.985 - throttleComp).

        set targetPitch to 
            max(
            (90 * (1 - alt:radar /
            (targetAp * pitchGain)
            ))
            , MECOangle + ctrlOverride).
    }
}

function MECO
{
    lock steering to lookdirup(
        heading(targetAzimuth, MECOangle + ctrlOverride):vector,
        heading(180 - targetInc, 0):vector).

    // staging sequence
    wait 2.
    set throt to 0.
    wait 1.
    stage.
    rcs on.
    wait 3 + (BBdelay / 2).
}

function BurnToApoapsis
{
    // engine sequence
    set throt to 0.025.
    wait 0.5.
    set throt to 1.
    lock steering to lookdirup(
        heading(targetAzimuth, MECOangle):vector,
        heading(180 - targetInc, 0):vector).
    rcs on.
    
    wait until ship:altitude > 40000.   // will change to prograde angle
    lock throt to min(max(0.3334, (targetOrb - ship:apoapsis) / (targetOrb - atmHeight)), 1).
    lock steering to lookdirup(
        heading(targetAzimuth, targetPitch):vector,
        heading(180 - targetInc, 0):vector).

    until (ship:apoapsis > targetOrb)
    {
        wait 0.
        set targetPitch to
            min(max(
            (90 * (1 - ship:apoapsis / tangentAltitude)), 
            0), 30).    // nose is always greater than 1
    
        // stage once if the ship has fairings
        if (ship:altitude > fairingSepAlt and fairingLock = false)
        {
            wait 0.
            if (hasFairing = true) 
            {
                stage.
                set fairingLock to true.
                wait 0.
            }
        }
    }

    set throt to 0.
    lock steering to lookdirup(
        ship:prograde:vector,
        heading(180 - targetInc, 0):vector).
    wait until ship:altitude > atmHeight + 100. // do not make maneuvers inside an atmosphere
}

function Circularize
{
    //maneuver planning
    set targetVel to sqrt(ship:body:mu / (ship:orbit:body:radius + ship:orbit:apoapsis)).
    set apVel to sqrt(((1 - ship:orbit:eccentricity) * ship:orbit:body:mu) / ((1 + ship:orbit:eccentricity) * ship:orbit:semimajoraxis)).
    set dv to targetVel - apVel.
    set circNode to node(time:seconds + eta:apoapsis, 0, 0, dv).
    add circNode.

    //maneuver timing and preparation
    steeringmanager:resettodefault().
    set nd to nextnode.
    set maxAcc to ship:maxthrust / ship:mass.
    set burnDuration to nd:deltav:mag / maxAcc.
    wait until nd:eta <= (burnDuration / 2 + 60).

    lock nv to nd:deltav:normalized.
    set dv0 to nd:deltav.
    lock steering to lookdirup(
        nv, 
        heading(180 - targetInc, 0):vector).
    wait until vang(nv, ship:facing:vector) < 0.25.

    // maneuver execution
    wait until nd:eta <= (burnDuration).
    rcs off.
    wait until nd:eta <= (burnDuration / 2).
    set done to false.
    
    until done 
    {
        wait 0.
        set maxAcc to ship:maxthrust / ship:mass.
        set throt to min(nd:deltav:mag / maxAcc, 1).

        if (vdot(nv, nd:deltav) < 0) 
        {
            set throt to 0.
            break.
        }

        if (nd:deltav:mag < 0.1)
        {
            wait until vdot(dv0, nd:deltav) < 0.5.
            set throt to 0.
            set done to true.
        }
    }

    remove nextnode.
    set throt to 0.
    set ship:control:pilotmainthrottle to 0.
    lock steering to lookdirup(
        ship:prograde:vector,
        heading(180 - targetInc, 0):vector).
}

until false {wait 0.}
