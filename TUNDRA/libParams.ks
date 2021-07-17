// TUNDRA LAUNCH VEHICLE PARAMETERS
parameter stageNo.

global payloadMass is 6000.
global payloadType is "fairing".

global targetOrb is 120000.
global targetInc is 2.

global recoveryMode is "RTLS_SS".

global willRendezvous is false.
global targetName is "".

global LZ0 is LATLNG(-0.11,-71).
global LZ1 is LATLNG(-0.132317822427,-74.54941288513).
global LZ2 is LATLNG(-0.140425956708956,-74.5495256417959).
global LZ is LZ1.

missionConstants().
parameterPass().

function parameterPass {

    if (recoveryMode = "RTLS") { RTLSmode(). }
    if (recoveryMode = "ASDS") { ASDSmode(). }
    if (recoveryMode = "Heavy") { HEAVYmode(). }
    if (recoveryMode = "Full") { EXPENDmode(). }

    if (recoveryMode = "RTLS_SS") { RTLSmode_SS(). }

    set copyVal to lexicon(
    "m_targetInc", targetInc,
    "m_targetOrb", targetOrb,
    "m_recoveryMode", recoveryMode,
    "m_payloadMass", payloadMass,
    "m_maxPayload", maxPayload,
    "m_lzcoords0", LZ0,
    "m_lzcoords1", LZ1,
    "m_lzcoords2", LZ2,
    "m_MECOangle", MECOangle,
    "m_reentryHeight", reentryHeight,
    "m_reentryVelocity", reentryVelocity,
    "m_AoAlimiter", AoAlimiter).

    // send data to CPUs
    if (stageNo = 2) {
        set recCPU to processor("CORE").
        recCPU:connection:sendmessage(copyVal).

        if (recoveryMode = "Heavy") {
            set ArecCPU to processor("SIDEA").
            ArecCPU:connection:sendmessage(copyVal).

            set BrecCPU to processor("SIDEB").
            BrecCPU:connection:sendmessage(copyVal).
        }
    }
}

function missionConstants {
    set target to targetName.
    global fairingSepAlt is 60000.
    global atmHeight is body:atm:height.
    if (hasTarget = true) { global targetInc is target:orbit:inclination. }
    global windowOffset is 2.5.
    global goForLaunch is false.
    global MaxQ is 0.155.
    global AoAlimiter is 22.5. //22.5
}

// GHIDORAH PROFILE

function RTLSmode {
    global maxPayload is 7000.
    global tangentAltitude is body:atm:height - 5000.
    global MECOangle is 45.
    global targetAp is 60000.
    global pitchGain is 1.0815. // 1.0815
    global reentryHeight is 30000.
    global reentryVelocity is 400.
}

function ASDSmode {
    global maxPayload is 9000.
    global tangentAltitude is body:atm:height + 5000.
    global MECOangle is 40.
    global targetAp is 62500.
    global pitchGain is 1.0815.
    global reentryHeight is 32500.
    global reentryVelocity is 500.
}

function HEAVYmode {
    global maxPayload is 15000.
    global tangentAltitude is body:atm:height + 10000.
    global MECOangle is 45.
    global targetAp is 67500.
    global pitchGain is 1.0815.
    global reentryHeight is 30000.
    global reentryVelocity is 400.
}
        
function EXPENDmode {
    global maxPayload is 15000.
    global tangentAltitude is body:atm:height + 5000.
    global MECOangle is 10.
    global targetAp is 65000.
    global pitchGain is 0.725.
    global reentryHeight is 30000.
    global reentryVelocity is 410.
    // recovery parameters are still added to prevent unknown variables errors
}

// GOJIRA PROFILE

function RTLSmode_SS {
    global maxPayload is 15000.
    global tangentAltitude is body:atm:height + 5000.
    global MECOangle is 35.
    global targetAp is 65000.
    global pitchGain is 0.75. // 1.0815
    global reentryHeight is 30000.
    global reentryVelocity is 500.
}
