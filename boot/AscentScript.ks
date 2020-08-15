// Ghidorah v0.6 -- Second Stage Script
clearscreen.
until AG10 wait 1.

// core:part:getmodule("kOSProcessor"):doEvent("Open Terminal").

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
    GravityTurn().
    MECO().
    BurnToApoapsis().
    Circularize().
    if ((payloadType = "gigan" or payloadType = "rodan") and hasTarget = true)
    {   
        MatchPlanes().
        Burn1().
        Burn2().
        MainDocking().
        wait 10.
        shutdown.
    }
    else    
        shutdown.
}

function MainDocking
{
    rcs on.
    lock steering to lookdirup(
    ship:prograde:vector,
    vcrs(ship:prograde:vector, body:position)).
    wait 15.

    HaltRendezvous(0.5).
    Rendezvous(500, 20).        // approach the target until inside physics bubble
    Rendezvous(170, 5).         // approach the target until target is unpacked

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

function StartUp 
{
    // run prerequitistes (load functions to cpu)
    runoncepath("0:/TUNDRA/missionParameters").
    runoncepath("0:/TUNDRA/libGNC").
    runoncepath("0:/TUNDRA/launchWindow").

    wait until goForLaunch = true.

    // control variables
    set throt to 0.
    lock throttle to throt.

    // profile variables
    set targetAzimuth to (Azimuth(DirCorr() * targetInc, targetOrb)). 
    print targetAzimuth at (0, 6).
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

    lock steering to lookdirup(
        heading(targetAzimuth, targetPitch):vector,
        heading(180 - (DirCorr() * targetInc), 0):vector).

    lock throt to 1 - (10 * ((-1 * MaxQ) + ship:q)).

    until (ship:apoapsis > targetAp)
    {
        wait 0.

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
        heading(180 - (DirCorr() * targetInc), 0):vector).

    // staging sequence
    set throt to 0.5.
    wait 2.
    set throt to 0.
    wait 1.
    stage.
    rcs on. 
    wait 5.
}

function BurnToApoapsis
{
    // engine sequence
    set throt to 0.025.
    wait 0.5.
    set throt to 1.
    lock steering to lookdirup(
        heading(targetAzimuth, MECOangle + ctrlOverride):vector,
        heading(180 - (DirCorr() * targetInc), 0):vector).
    rcs on.
    
    wait until ship:altitude > 35000.   // will change to prograde angle 
    lock throt to min(max(0.333, (targetOrb - ship:apoapsis) / (targetOrb - atmHeight)), 1).
    lock steering to lookdirup(
        heading(targetAzimuth, targetPitch):vector,
        heading(180 - (DirCorr() * targetInc), 0):vector).

    until (ship:apoapsis > targetOrb)
    {
        wait 0.
        set targetPitch to
            min(max(
            (90 * (1 - ship:apoapsis / tangentAltitude)), 
            0), (MECOangle + ctrlOverride)).
    
        // stage once if the ship has fairings
        if (ship:altitude > fairingSepAlt and fairingLock = false)
        {
            wait 0.
            if (payloadType = "gigan" or payloadType = "fairing" or payloadType = "fairings") 
            {
                stage.
                set fairingLock to true.
                wait 0.
            }
            else
            { stage. }
        }
    }

    set throt to 0.
    lock steering to lookdirup(
        ship:prograde:vector,
        heading(180 - (DirCorr() * targetInc), 0):vector).
    wait 3. rcs off.
    wait until ship:altitude > atmHeight + 700. // do not make maneuvers inside an atmosphere
    steeringmanager:resettodefault().
}

function Circularize
{
    set circNode to node(time:seconds + eta:apoapsis, 0, 0, Hohmann("circ")).
    add circNode.

    ExecNode().
}

function MatchPlanes
{
    // staging sequence
    stage.      // separate to second stage.
    wait 5.
    if (payloadType = "gigan")
    {
        stage.
        wait 3.
        panels on.  rcs off.
    }
    if (hastarget = false)
        wait until hasTarget = true.
    
    wait until TimeToNode() < 30 + BurnLengthRCS(1, NodePlaneChange()).

    set matchNode to node(time:seconds + TimeToNode(), 0, (NodePlaneChange()* PlaneCorr()), 0).
    add matchNode.

    ExecNode(4, true, "top").
}

function PlaneCorr
{
    if (abs(AngToRAN()) > abs(AngToRDN())) { return 1. }
    else { return -1. }
}

function Burn1
{
    wait 10.
    set burn1Node to node(time:seconds + PhaseAngle(), 0, 0, Hohmann("raise")).
    add burn1Node.

    ExecNode(4, true).
}

function Burn2
{
    wait 10.
    set burn1Node to node(time:seconds + eta:apoapsis, 0, 0, Hohmann("circ")).
    add burn1Node.

    ExecNode(4, true).
}

function Rendezvous
{
    parameter tarDist, tarVel.

    local relVel is 0.
    local rendezvousVec is 0.

    lock relVel to ship:velocity:orbit - target:velocity:orbit.
    lock rendezvousVec to target:position - ship:position + (target:retrograde:vector:normalized * tarDist).

    set dockPID to pidloop(0.1, 0.00125, 0.03, 0, tarVel).
    set dockPID:setpoint to 0.
    lock dockOutput to dockPID:update(time:seconds, (-1 * rendezvousVec:mag)).

    until (rendezvousVec:mag < 0.1)
    {
        RCSTranslate((rendezvousVec:normalized * (dockOutput)) - relVel).
    }
    RCSTranslate(v(0,0,0)).
}

function CloseIn
{
    parameter tarDist, tarVel.

    local relVel is 0.
    local dockVec is 0.

    lock relVel to ship:velocity:orbit - targetPort:ship:velocity:orbit.
    lock dockVec to targetPort:nodeposition - shipPort:nodePosition + (targetPort:portfacing:vector * tarDist).

    set dockPID to pidloop(0.1, 0.002, 0.0265, 0, tarVel).
    set dockPID:setpoint to 0.
    lock dockOutput to dockPID:update(time:seconds, (-1 * dockVec:mag)).

    until (dockVec:mag < 0.1)
    {
        RCSTranslate((dockVec:normalized * (dockOutput)) - relVel).
    }
    RCSTranslate(v(0,0,0)).
}

function HaltRendezvous
{
    parameter haltThreshold is 0.1.

    lock relVel to ship:velocity:orbit - target:velocity:orbit.
    until (relVel:mag < haltThreshold)
    {
        RCSTranslate(-1 * relVel).
    }
    RCSTranslate(v(0,0,0)).
}

function HaltDock
{
    parameter haltThreshold is 0.1.

    lock relVel to ship:velocity:orbit - targetPort:ship:velocity:orbit.
    until (relVel:mag < haltThreshold)
    {
        RCSTranslate(-1 * relVel).
    }
    RCSTranslate(v(0,0,0)).
}

until false {wait 0.}

    // TODO:

    // MAKE A CLOSING IN ALGORITHM, VCRS() MIGHT HELP. PORT IS NOT RECOGNIZED 
    // OUTSIDE OF THE PHYSICS RANGE.


    
    