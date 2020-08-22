set target to vessel("GRDY").
// set target vessel above, comment if none

MissionVariables("ASDS", 6200, 165000, 0, "rodan", true).
// change according to your mission targets
// parameters are as follows:
    // Ascent Profile ("ASDS", "RTLS", "Full")
    // Payload Mass(kg)
    // Target Orbit(m)
    // Target Inclination(deg),
    // Payload Type("gigan", "rodan", "fairing")
    // Wait For Instantaneous Launch Window?(true, false)
// example: MissionVariables(1000, 120000, 30, "gigan", true).

function MissionVariables 
{
    parameter ascProfile, pMass, tOrbit, tInclination, pType, window.

    // PAYLOAD
    if (ascProfile = "RTLS") { global maxPayload is 7000. }
    else { global maxPayload is 9000. }
    global payloadMass is pMass.
    global fairingSepAlt is 60000.
    global payloadType is pType.

    // SUB-ORBITAL
    global profile is ascProfile.
    if (ascProfile = "RTLS" ) { global tangentAltitude is body:atm:height. }
    else { global tangentAltitude is body:atm:height + 12500. }
    global atmHeight is body:atm:height.
    if (ascProfile = "RTLS" ) { global MECOangle is 35. }
    else { global MECOangle is 30. } // [35]

    // ORBITAL
    if (ascProfile = "RTLS") { global targetAp is 53500. }  // [55000]
    else { global targetAp is 63500. }
    if (hasTarget = true) { global targetInc is target:orbit:inclination. }
    else { global targetInc is tInclination. }
    global targetOrb is tOrbit.
    global hasWindow is window.
    global windowOffset is 2.    // [2]

    // VESSEL
    global goForLaunch is false.
    global MaxQ is 0.16.    // set to kPa / 100k  [0.17]
    if (ascProfile = "RTLS") { global pitchGain is 0.87. }
    else { global pitchGain is 0.7. }

    // TRAJECTORY
    if (ascProfile = "RTLS") { global landingOffset is 0.00085. }
    else { global landingOffset is -0.00085. }
    global AoAlimiter is 17.5.

    // RE-ENTRY
    if (ascProfile = "RTLS") { global reentryHeight is 27500. }
    else { global reentryHeight is 30000. } // [27500]
    global reentryVelocity is 485. // [475]

    // LANDING ZONE
    if (ascProfile = "RTLS") 
    {
        global LZ is LATLNG(-0.129700289080028,-74.5531947639297).
    }
    else
    {
        global LZ is LATLNG(-0.0949824364186808,-67.8066569431229).
    }
}