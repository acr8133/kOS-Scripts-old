
//------------------------------------------------------------
//	READ COMMENTS FIRST,put me on the Second Stage CPU :D
//------------------------------------------------------------

clearscreen.

until AG10 {
	wait 1.
}

//--------------------

set targetOrbit to 140000.
set targetApoapsis to 50000.
set targetHeading to 90.
set targetInclination to 25.
set targetHorizontalAltitude to 70000.	//height where the S2 will be completely tangent to Kerbin
set hasFairing to true.					//Rodan has none, set to false

StartUp().

//--------------------

function StartUp {
	//flight variables
	set throt to 0.
	lock throttle to throt.

	set pitchFactor to 0.7.	//higher = steeper
	set targetPitch to 90.
	set fairingLock to false.
	
	Main().
}

function Main {
	
	stage.
	set throt to 0.01.	
	wait 1.5.
	set throt to 1.				//shows TEA-TEB ignition on engine start
	wait 1.5.			
	stage.
	
	Liftoff().
	GravityTurn().
	MECO().
	BurnToApoapsis().
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
		heading(90 - targetInclination, targetPitch):vector, 
		heading(180, 0):vector).

	until ship:apoapsis > targetApoapsis
	{
		set targetPitch to 
			max(
			(90 * (1 - alt:radar / 
			(targetApoapsis * pitchFactor)
			))
			, 40).		//40 is the pitch limit
	}
}

function MECO {
	lock steering to lookdirup(
		heading(90 - targetInclination, 40):vector, //40 is the pitch limit
		heading(180, 0):vector).
	wait 2.
	set throt to 0.			//this mess here is so that FMRS wont eat your
	wait 2.
	stage.					//vessel into pieces.
	wait 4.

}

function BurnToApoapsis {
	lock steering to lookdirup(heading(90 - targetInclination, 25):vector, heading(180, 0):vector).
	rcs on.	
	lock throt to min(max(0.4, (targetOrbit - ship:apoapsis) / 40000), 0.6).

	wait until ship:altitude > 40000.
	lock steering to lookdirup(
		heading(90 - targetInclination, targetPitch):vector, 
		heading(180, 0):vector).
		
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
			
		if (ship:altitude > 60000 and fairingLock = false) {
			if hasFairing = true {
				stage.							//make sure next stage after S2 engines 
				set fairingLock to true.		//is the fairing
			}
		}
		
	}	
	
	set throt to 0.
	lock steering to lookdirup(ship:prograde:vector, heading(180, 0):vector).
}

function Circularize {
	set targetVel to sqrt(ship:body:mu/(ship:orbit:body:radius + ship:orbit:apoapsis)).
	set apVel to sqrt(((1 - ship:orbit:ECCENTRICITY) * ship:orbit:body:mu) / ((1 + ship:orbit:ECCENTRICITY) * ship:orbit:SEMIMAJORAXIS)).
	set dv to targetVel - apVel.
	set mynode to node(time:seconds + eta:apoapsis, 0, 0, dv).
	add mynode.
}

function Execute {
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

until false{
	wait 0.
}





















