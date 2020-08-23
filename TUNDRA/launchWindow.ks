// INSTANTANEOUS LAUNCH WINDOW SEQUENCE

if (hasWindow = true and goForLaunch = false and hasTarget = true) {
    DirCorr().
    WaitTime().
} else { global goForLaunch is true. }
    
wait until (goForLaunch = true).

function WaitTime {
    if (AngToRAN() > 0)
        kuniverse:timewarp:warpto(time:seconds + TMinus("AN") - 30).
    else
        kuniverse:timewarp:warpto(time:seconds + TMinus("DN") - 30).

    until (UpcomingNodeAngle() < windowOffset) {
        wait 0.
        DirCorr().
    }

    kuniverse:timewarp:cancelwarp().
    wait until kuniverse:timewarp:issettled = true.

    global goForLaunch is true.
}

//returns angle, whichever is upcoming
function UpcomingNodeAngle {   
    wait 0.
    if (AngToRAN() > 0) { TMinus("AN"). return AngToRAN(). }
    else { TMinus("DN"). return AngToRDN(). }
}

//returns seconds (perhaps the name, it returns a positive value)
// real TMinus is time:seconds - time:seconds + TMinus()
function TMinus {
    parameter node.

    if (node = "AN") {  // will only be either AN or DN
        print "T: -" + round(((AngToRAN() - windowOffset) / 360 * body:rotationperiod)) + "   " at (0, 2).
        return ((AngToRAN() - windowOffset) / 360 * body:rotationperiod).
    } else {
        print "T: -" + round(((AngToRDN() - windowOffset) / 360 * body:rotationperiod)) + "   " at (0, 2).
        return ((AngToRDN() - windowOffset) / 360 * body:rotationperiod).
    }
}