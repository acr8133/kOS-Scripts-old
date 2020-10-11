// set target to vessel("GRDY").
// set target vessel above, comment if none

MissionVariables(
    "Full",     // Ascent Profile ("ASDS", "RTLS", "Full")
    15000,       // Payload Mass(kg)
    130000,     // Target Orbit(m)
    15,         // Target Inclination(deg)
    "fairing", // Payload Type("gigan", "rodan", "fairing")
    false).       // Wait For Instantaneous Launch Window?(true, false)

function MissionVariables {
    parameter ascProfile, pMass, tOrbit, tInclination, pType, window.

    // PAYLOAD
    if (ascProfile = "RTLS") { global maxPayload is 7000. }
    else if (ascProfile = "ASDS"){ global maxPayload is 9000. }
    else {global maxPayload is 15000.}
    global payloadMass is pMass.
    global fairingSepAlt is 65000.
    global payloadType is pType.

    // SUB-ORBITAL
    global profile is ascProfile.
    if (ascProfile = "RTLS" ) { global tangentAltitude is body:atm:height - 5000. }
    else { global tangentAltitude is body:atm:height + 5000. }
    global atmHeight is body:atm:height.
    if (ascProfile = "RTLS" ) { global MECOangle is 40. }   // [40]
    else if (ascProfile = "ASDS"){ global MECOangle is 30. } // [35]
    else {global MECOangle is 20.}

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
    global MaxQ is 0.155.    // set to kPa / 100k  [0.15]
    if (ascProfile = "RTLS") { global pitchGain is 0.925. } // [0.925]
    else { global pitchGain is 0.725. }   // [0.7]

    // TRAJECTORY
    if (ascProfile = "RTLS") { global landingOffset is 0.000. } 
    else { global landingOffset is -0.00085. }
    global AoAlimiter is 17.5.

    // RE-ENTRY
    if (ascProfile = "RTLS") { global reentryHeight is 26000. }     // [27500] 
    else { global reentryHeight is 30000. } // [27500]
    if (ascProfile = "RTLS") { global reentryVelocity is 385. }     // [400]
    else { global reentryVelocity is 420. }                         // [485]

    // LANDING ZONE
    if (ascProfile = "RTLS") {
        global LZ is LATLNG(-0.205613225361111,-74.4730953656575).
    } else {
        global LZ is LATLNG(-0.11,-65).
    }
}