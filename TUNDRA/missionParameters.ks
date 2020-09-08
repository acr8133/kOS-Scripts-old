// set target to vessel("GRDY").
// set target vessel above, comment if none

MissionVariables(
    "RTLS",     // Ascent Profile ("ASDS", "RTLS", "Full")
    7000,       // Payload Mass(kg)
    350000,     // Target Orbit(m)
    45,          // Target Inclination(deg)
    "fairings", // Payload Type("gigan", "rodan", "fairing")
    true).     // Wait For Instantaneous Launch Window?(true, false)

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
    if (ascProfile = "RTLS" ) { global MECOangle is 40. }
    else { global MECOangle is 30. } // [35]

    // ORBITAL
    if (ascProfile = "RTLS") { global targetAp is 57500. }  // [53500]
    else { global targetAp is 65000. }                      // [65000]
    if (hasTarget = true) { global targetInc is target:orbit:inclination. }
    else { global targetInc is tInclination. }
    global targetOrb is tOrbit.
    global hasWindow is window.
    global windowOffset is 2.    // [2]

    // VESSEL
    global goForLaunch is false.
    global MaxQ is 0.155.    // set to kPa / 100k  [0.17]
    if (ascProfile = "RTLS") { global pitchGain is 0.925. } // [0.875]
    else { global pitchGain is 0.7. }   // [0.7]

    // TRAJECTORY
    if (ascProfile = "RTLS") { global landingOffset is 0.000. }
    else { global landingOffset is -0.00085. }
    global AoAlimiter is 17.5.

    // RE-ENTRY
    if (ascProfile = "RTLS") { global reentryHeight is 26000. }     // [27500] 
    else { global reentryHeight is 30000. } // [27500]
    if (ascProfile = "RTLS") { global reentryVelocity is 400. }     // [450]
    else { global reentryVelocity is 485. }                         // [485]

    // LANDING ZONE
    if (ascProfile = "RTLS") {
        global LZ is LATLNG(-0.205613225361111,-74.4730953656575).
    } else {
        global LZ is LATLNG(-0.0950182909358097,-67.8066714727723).
    }
}