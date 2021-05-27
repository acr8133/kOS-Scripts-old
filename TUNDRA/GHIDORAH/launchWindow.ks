// INSTANTANEOUS LAUNCH WINDOW SEQUENCE

clearScreen.
// core:part:getmodule("kOSProcessor"):doEvent("Open Terminal").

if abs((Azimuth(DirCorr() * targetInc, targetOrb) - (abs(targetInc) + 90))) < 0.1 {
    set correctInc to false.
} else {
    set correctInc to true.
}

if (hasWindow = true and 
    goForLaunch = false and 
    hasTarget = true and 
    target:orbit:inclination > 1 and 
    correctInc = true) {
        DirCorr().
        WaitTime().
} else { SendAzimuth(). global goForLaunch is true. }
    
wait until (goForLaunch = true).

function WaitTime {
    if (AngToRAN() > 0)
        kuniverse:timewarp:warpto(time:seconds + TMinus("AN") - 30).
    else
        kuniverse:timewarp:warpto(time:seconds + TMinus("DN") - 30).

    until (UpcomingNodeAngle() <= windowOffset) {
        print UpcomingNodeAngle() at (0, 3).
        DirCorr().
    }

    kuniverse:timewarp:cancelwarp().
    wait until kuniverse:timewarp:issettled = true.

    SendAzimuth().
}

function SendAzimuth {

    // will allow boosters to update their target azimuths
    global goForLaunch is true.             // for S2
    set GOCall to lexicon("gocall", true).  // for S1

    set recCPU1 to processor("VC-13B").
    recCPU1:connection:sendmessage(GOCall).

    if (profile = "Heavy") {
        set ArecCPU1 to processor("ABooster").
        ArecCPU1:connection:sendmessage(GOCall).

        set BrecCPU1 to processor("BBooster").
        BrecCPU1:connection:sendmessage(GOCall).
    }
}

// returns angle, whichever is upcoming
function UpcomingNodeAngle {   
    if (AngToRAN() > 0) { TMinus("AN"). return AngToRAN(). }
    else { TMinus("DN"). return AngToRDN(). }
}

// returns seconds (returns a positive value)
function TMinus {
    parameter node. // AN, DN

    if (node = "AN") {
        print "T: -" + round(((AngToRAN() - windowOffset) / 360 * body:rotationperiod)) + "   " at (0, 2).
        return ((AngToRAN() - windowOffset) / 360 * body:rotationperiod).
    } else {
        print "T: -" + round(((AngToRDN() - windowOffset) / 360 * body:rotationperiod)) + "   " at (0, 2).
        return ((AngToRDN() - windowOffset) / 360 * body:rotationperiod).
    }
}