
//------------------------------------------------------------
//	READ COMMENTS FIRST,put me on the Second Stage CPU :D
//------------------------------------------------------------

clearscreen.

until AG10 {
	wait 1.
}

//---------EDIT THESE FOR LAUCH PROFILES-----------

set targetOrbit to 85000.
set targetInclination to 0.		//0 - equitorial, 90 - polar

set hasFairing to true.			//Rodan has none, set to false
set fairingSepAlt to 52000.

StartUp().

// everything set is for 7 tons payload

//-------------------------------------------------

function StartUp {
	//flight variables ( dont touch, might break stuff :P )
	set throt to 0.
	lock throttle to throt.

	set pitchFactor to 0.915.	//0.85.
	set targetPitch to 90.
	set fairingLock to false.
	set targetHorizontalAltitude to 55000.
	set targetApoapsis to 47500.
	set targetAzimuth to Azimuth(targetInclination, targetOrbit).
	
	print targetAzimuth at (0, 2).
	
	Main().
}

function Main {
	
	toggle AG3.		//strongback retract
	set throt to 1.
	wait 1.
	stage.
	
	Liftoff().
	GravityTurn().
	MECO().
	BurnToApoapsis().
	wait until ship:altitude > 70100.	//this is needed for calculating deltav requirements
	Circularize().
	Execute().
	remove nextnode.
}

function Liftoff {
	lock steering to lookdirup(heading(90, 90):vector, heading(180, 0):vector).
	until ship:verticalspeed > 25 {		//25 so that it wont pitch kick too hard
		wait 0.
	}
}

function GravityTurn {
	lock steering to lookdirup(
		heading(targetAzimuth, targetPitch):vector, 
		heading(180 - targetInclination, 0):vector).

	until ship:apoapsis > targetApoapsis
	{	
		wait 0.
		set targetPitch to 
			max(
			(90 * (1 - alt:radar / 
			(targetApoapsis * pitchFactor)
			))
			, 35).		//35 is the pitch limit
	}
}

function MECO {
	lock steering to lookdirup(
		heading(targetAzimuth, 35):vector, //35 is the pitch limit
		heading(180 - targetInclination, 0):vector).
	wait 2.
	set throt to 0.			//this mess here is so that FMRS wont eat your
	wait 3.
	stage.					//vessel into pieces.
	wait 4.

}

function BurnToApoapsis {
	lock steering to lookdirup(heading(targetAzimuth, 25):vector, heading(180 - targetInclination, 0):vector).
	rcs on.	
	lock throt to min(max(0.4, (targetOrbit - ship:apoapsis) / (targetOrbit - 70000)), 1).

	wait until ship:altitude > 40000.
	lock steering to lookdirup(
		heading(targetAzimuth, targetPitch):vector, 
		heading(180 - targetInclination, 0):vector).
		
	until ship:apoapsis > targetOrbit {
		wait 0.
		set targetPitch to 
			min(
			max(
			(90 * (1 - alt:radar / 
			(targetHorizontalAltitude)
			))
			, 1)			//1 degree above horizon
			, 25).			
			
		if (ship:altitude > fairingSepAlt and fairingLock = false) {
			wait 0.
			if hasFairing = true {
				stage.							//make sure next stage after S2 engines 
				set fairingLock to true.		//is the fairing
				wait 0.
			}
		}
		
	}	
	
	set throt to 0.
	lock steering to lookdirup(ship:prograde:vector, heading(180 - targetInclination, 0):vector).
}

function Circularize {
	set targetVel to sqrt(ship:body:mu/(ship:orbit:body:radius + ship:orbit:apoapsis)).
	set apVel to sqrt(((1 - ship:orbit:ECCENTRICITY) * ship:orbit:body:mu) / ((1 + ship:orbit:ECCENTRICITY) * ship:orbit:SEMIMAJORAXIS)).
	set dv to targetVel - apVel.
	set mynode to node(time:seconds + eta:apoapsis, 0, 0, dv).
	add mynode.
}

function Execute {
	steeringmanager:resetpids().
	set nd to nextnode.
	set max_acc to ship:maxthrust / ship:mass.
	set burn_duration to nd:deltav:mag/max_acc.
	wait until nd:eta <= (burn_duration/2 + 60).
	
	set np to nd:deltav.
	lock steering to np.
	wait until vang(np, ship:facing:vector) < 0.33.
	
	wait until nd:eta <= (burn_duration/2).
	
	set dv0 to nd:deltav.
	set done to false.
	
	until done {
		wait 0.
		set max_acc to ship:maxthrust / ship:mass.

		set throt to min(nd:deltav:mag/max_acc, 1).
		
		if vdot(dv0, nd:deltav) < 0 {
			set throt to 0.
			break.
		}
		
		if nd:deltav:mag < 0.1 {
			wait until vdot(dv0, nd:deltav) < 0.5.
			set throt to 0.
			set done to true.
		}
	
	}
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
	wait 0.
}





















