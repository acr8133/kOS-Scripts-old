// INSTANTANEOUS LAUNCH WINDOW SEQUENCE
parameter mode, stageNo.

clearScreen.
// core:part:getmodule("kOSProcessor"):doEvent("Open Terminal").

print mode.
set correctInc to true.
if (mode = "ship") {
    if (abs((Azimuth(DirCorr() * targetInc, targetOrb) - (abs(targetInc) + 90))) < 0.1) { 
        set correctInc to false. 
    }
} else {
    global willRendezvous is true.
    if (vAng(OrbitBinormal(), GroundBinormal()) < 0.1) {
        set correctInc to false.
    }
}

if (willRendezvous and 
    goForLaunch = false and 
    correctInc) {
        DirCorr().
        WaitTime(mode).
} else { SendAzimuth(). global goForLaunch is true. }
    
wait until (goForLaunch). print "GO" at (0, 5).

function WaitTime {
    parameter mode.

    if (mode = "ship") {
        if (NodeAngle("AN") > 0) {
            kuniverse:timewarp:warpto(time:seconds + (TMinus("AN", "ground", mode) - 30)).
        } else {
            kuniverse:timewarp:warpto(time:seconds + (TMinus("DN","ground", mode) - 30)).
        }
    } else {
        if (NodeAngle("AN", OrbitBinormal(), GroundBinormal()) > 0) {
            kuniverse:timewarp:warpto(time:seconds + (TMinus("AN", "orbit", mode) - 30)).
        } else {
            kuniverse:timewarp:warpto(time:seconds + (TMinus("DN", "orbit", mode) - 30)).
        }
    }
    
    until (UpcomingNodeAngle(mode) <= windowOffset) {
        print UpcomingNodeAngle(mode) at (0, 3).
        DirCorr().
    }
    wait 1.

    kuniverse:timewarp:cancelwarp().
    wait until kuniverse:timewarp:issettled.

    SendAzimuth().
}

function SendAzimuth {

    // will allow boosters to update their target azimuths
    global goForLaunch is true.             // for S2
    set GOCall to lexicon("gocall", true).  // for S1

    if (stageNo = 2) {
        set recCPU1 to processor("CORE").
        recCPU1:connection:sendmessage(GOCall).
    }

    if (recoveryMode = "Heavy") {
        set ArecCPU to processor("SIDEA").
        ArecCPU:connection:sendmessage(GOCall).

        set BrecCPU to processor("SIDEB").
        BrecCPU:connection:sendmessage(GOCall).
    }
}

function UpcomingNodeAngle {
    parameter mode.

    if (mode = "ship") {
        if (NodeAngle("AN") > 0) { TMinus("AN", mode). return NodeAngle("AN"). }
        else { TMinus("DN", mode). return NodeAngle("DN"). }
    } else {
        if (NodeAngle("AN", OrbitBinormal(), GroundBinormal()) > 0) { TMinus("AN", "orbit", mode). return NodeAngle("AN", OrbitBinormal(), GroundBinormal()). }
        else { TMinus("DN", "orbit", mode). return NodeAngle("DN", OrbitBinormal(), GroundBinormal()). }
    }
    
}

function TMinus {
    parameter node, mode, targettype. // AN, DN - orbit, ground - ship, coords

    if (mode = "orbit") {
        if (node = "AN") {
                if (targettype = "ship") { set TminusAN to TimeToNode("ship"). }
                else { set TminusAN to TimeToNode("coords"). }
            print "T: -" + round(TminusAN) + "   " at (0, 2).
            return TminusAN.
        } else {
                if (targettype = "ship") { set TminusDN to TimeToNode("ship"). }
                else { set TminusDN to TimeToNode("coords"). }
            print "T: -" + round(TminusDN) + "   " at (0, 2).
            return TminusDN.
        }
    } else {
        if (node = "AN") {
            local TminusAN is ((NodeAngle("AN") - windowOffset) / 360 * body:rotationperiod).
            print "T: -" + round(TminusAN) + "   " at (0, 2).
            return TminusAN.
        } else {
            local TminusDN is ((NodeAngle("DN") - windowOffset) / 360 * body:rotationperiod).
            print "T: -" + round(TminusDN) + "   " at (0, 2).
            return TminusDN.
        }
    }
}

// this code looks ugly, i dont know why..
    // but it looks ugly.