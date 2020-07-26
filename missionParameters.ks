HighDrag("39").
// change according to your strongback, can be "39" for LC-39, or "40" for SLC-40

MissionVariables(200, 100000, 0).
// change according to your mission targets
// parameters are Payload Mass(kg), Target Orbit(m), Target Inclination(deg).
// example: MissionVariables(1000, 120000, 30).


function HighDrag 
{   // drag cube chages when switching strongbacks, this function
        //is for compensation.
    parameter strongback.
    set MECOdelay to 0.

    if (strongback = "39")
    {
        set MECOdelay to 5.        // MECO for delay
        set BBdelay to 0.25.        // overshoot for lower vel
        set aoaComp to 4.           // reduce gridfin actuation
        set reentryComp to 100.     // fuel compensation
        set pitchComp to 5.         // steeper ascent
        set apComp to 3000.        // higher apoapsis
        set throttleComp to 0.035.  // lower alt to ap ratio
    }
    else if (strongback = "40")
    {
        set MECOdelay to 0.
        set BBdelay to 0.
        set aoaComp to 0.
        set reentryComp to 0.
        set pitchComp to 0.
        set apComp to 0.
        set throttleComp to 0.
    }
    else
    {
        set MECOdelay to 0.
        set BBdelay to 0.
        set aoaComp to 0.
        set reentryComp to 0.
        set pitchComp to 0.
        set apComp to 0.
        set throttleComp to 0.
    }
}

function MissionVariables 
{
    parameter pMass, tOrbit, tInclination.

    // PAYLOAD
    global maxPayload is 7000.
    global payloadMass is pMass.

    // SUB-ORBITAL
    global tangentAltitude is body:atm:height.
    global atmHeight is body:atm:height.
    global MECOangle is 35.

    // ORBITAL
    global targetAp is 50000 + apComp.
    global targetInc is tInclination.
    global targetOrb is tOrbit.

    // VESSEL
    global MaxQ is 0.17.    //set to 0.kPa
    global pitchGain is 0.9.

    // FAIRINGS
    global hasFairing is true.
    global fairingSepAlt is 50000.

    // TRAJECTORY
    global landingOffset is 0.00085.    //RTLS offset
    global AoAlimiter is 8.5 - aoaComp.

    // RE-ENTRY
    global reentryHeight is 27500.
    global reentryVelocity is 450.

    // LANDING ZONE
    global LZ is LATLNG(-0.129700289080028,-74.5531947639297).
}
