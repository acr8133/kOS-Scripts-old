// set target to vessel("GRDY").
// set target vessel above, comment if none

MissionVariables(
    "ASDS",     // Ascent Profile ("ASDS", "RTLS", "Full")
    9000,       // Payload Mass(kg)
    150000,     // Target Orbit(m)
    0,          // Target Inclination(deg)
    "fairings", // Payload Type("gigan", "rodan", "fairing")
    false).     // Wait For Instantaneous Launch Window?(true, false)

function MissionVariables {
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
    else { global targetAp is 65000. }
    if (hasTarget = true) { global targetInc is target:orbit:inclination. }
    else { global targetInc is tInclination. }
    global targetOrb is tOrbit.
    global hasWindow is window.
    global windowOffset is 2.    // [2]

    // VESSEL
    global goForLaunch is false.
    global MaxQ is 0.16.    // set to kPa / 100k  [0.17]
    if (ascProfile = "RTLS") { global pitchGain is 0.875. }
    else { global pitchGain is 0.7. }

    // TRAJECTORY
    if (ascProfile = "RTLS") { global landingOffset is 0.00085. }
    else { global landingOffset is -0.00085. }
    global AoAlimiter is 17.5.

    // RE-ENTRY
    if (ascProfile = "RTLS") { global reentryHeight is 27500. }
    else { global reentryHeight is 30000. } // [27500]
    if (ascProfile = "RTLS") { global reentryVelocity is 450. }
    else { global reentryVelocity is 485. }

    // LANDING ZONE
    if (ascProfile = "RTLS") {
        global LZ is LATLNG(-0.129700289080028,-74.5531947639297).
    } else {
        global LZ is LATLNG(-0.0950182909358097,-67.8066714727723).
    }
}