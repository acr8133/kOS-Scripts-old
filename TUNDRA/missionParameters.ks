set target to vessel("GRDY").
// set target vessel above, comment if none

MissionVariables(7000, 165000, 25, "gigan", true).
// change according to your mission targets
// parameters are as follows:
    // Payload Mass(kg)
    // Target Orbit(m)
    // Target Inclination(deg),
    // Payload Type("gigan", "rodan", "fairing")
    // Wait For Instantaneous Launch Window?(true, false)
// example: MissionVariables(1000, 120000, 30, "gigan", true).

function MissionVariables 
{
    parameter pMass, tOrbit, tInclination, pType, window.

    // PAYLOAD
    global maxPayload is 7000.
    global payloadMass is pMass.
    global fairingSepAlt is 55000.
    global payloadType is pType.

    // SUB-ORBITAL
    global tangentAltitude is body:atm:height.
    global atmHeight is body:atm:height.
    global MECOangle is 35. // [35]

    // ORBITAL
    global targetAp is 52500.   // [55000]
    if (hasTarget = true)
    {
        global targetInc is target:orbit:inclination.
    }
    else
        global targetInc is tInclination.
    global targetOrb is tOrbit.
    global hasWindow is window.
    global windowOffset is 2.    // [0.125]

    // VESSEL
    global goForLaunch is false.
    global MaxQ is 0.17.    // set to kPa / 100k  [0.17]
    global pitchGain is 0.875. // [0.85]

    // TRAJECTORY
    global landingOffset is 0.00085.    // RTLS offset
    global AoAlimiter is 17.5.

    // RE-ENTRY
    global reentryHeight is 27500.  // [27500]
    global reentryVelocity is 475.

    // LANDING ZONE
    global LZ is LATLNG(-0.129700289080028,-74.5531947639297).
}