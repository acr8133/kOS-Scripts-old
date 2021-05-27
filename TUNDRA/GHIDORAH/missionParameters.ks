// MISSION PARAMETERS

clearScreen.
// core:part:getmodule("kOSProcessor"):doEvent("Open Terminal").

// create GUI
local profileGUI is GUI(300).
local lab0 is profileGUI:addlabel("GHIDORAH LAUNCH PARAMETERS").
set lab0:style:align to "center".
set lab0:style:fontsize to 15.

local lab1 is profileGUI:addlabel("Landing Profile").
set lab1:style:align to "center".
    local hbox1 is profileGUI:addhbox().
        local RTLSrad is hbox1:addradiobutton("RTLS").
        set RTLSrad:style:hstretch to true.
        local ASDSrad is hbox1:addradiobutton("ASDS").
        set ASDSrad:style:hstretch to true.
        local HEAVYrad is hbox1:addradiobutton("Heavy").
        set HEAVYrad:style:hstretch to true.
        local EXPNrad is hbox1:addradiobutton("Expend").
        set EXPNrad:style:hstretch to true.


local lab2 is profileGUI:addlabel("Payload Mass (kg)").
set lab2:style:align to "center".
    local hbox2 is profileGUI:addhbox().
        local massINP is hbox2:addtextfield().

local lab3 is profileGUI:addlabel("Target Orbit (km / deg)").
set lab3:style:align to "center".
    local hbox3 is profileGUI:addhbox().
        local altINP is hbox3:addtextfield().
        local incINP is hbox3:addtextfield().

local lab4 is profileGUI:addlabel("Payload Type").
set lab4:style:align to "center".
    local hbox4 is profileGUI:addhbox().
        local GIGrad is hbox4:addradiobutton("Gigan").
        set GIGrad:style:hstretch to true.
        local RODrad is hbox4:addradiobutton("Rodan").
        set RODrad:style:hstretch to true.
        local FRNGrad is hbox4:addradiobutton("Fairing").
        set FRNGrad:style:hstretch to true.

local lab5 is profileGUI:addlabel("Rendezvous and Docking").
set lab5:style:align to "center".
    local hbox5 is profileGUI:addhbox().
        local dockCHK is hbox5:addcheckbox("Rendezvous?").
        local tgtINP is hbox5:addtextfield.

local launchButton is profileGUI:addbutton("START MISSION").
set launchButton:enabled to false.
profileGUI:show().

// GUI handler
set lay1 to false. set lay2 to false.
set lay3 to false. set lay4 to false.
set lay5 to true.  set lay6 to true.
set hasWindow to false. set tempTarget to "".

set RTLSrad:onclick to RTLSmd@.
set ASDSrad:onclick to ASDSmd@.
set HEAVYrad:onclick to HEAVYmd@.
set EXPNrad:onclick to EXPNmd@.

set massINP:onchange to payloadM@.

set altINP:onchange to orbitA@.
set incINP:onchange to orbitI@.

set GiGrad:onclick to GIGmd@.
set RODrad:onclick to RODmd@.
set FRNGrad:onclick to FRNGmd@.

set dockCHK:ontoggle to DockBool@.
set tgtINP:onchange to DockName@.

function WaitForConfirm {

    if (lay1 and lay2 and lay3 and lay4 and lay5 and lay6) {
        set launchButton:enabled to true.
    } else {
        set launchButton:enabled to false.
    }
}

until launchButton:pressed { WaitForConfirm(). wait 0. }
if (hasWindow) { set target to vessel(tempTarget). }

//-------------------- CHANGE LZ COORDINATES HERE --------------------//
global LZ0 is LATLNG(-0.13,-71). // BARGE
global LZ is LATLNG(-0.132317822427,-74.54941288513). // LZ1
global LZ1 is LATLNG(-0.140425956708956,-74.5495256417959). // LZ2
//--------------------------------------------------------------------//

// GLOBAL VALUES
global fairingSepAlt is 60000.
global atmHeight is body:atm:height.
if (hasTarget = true) { global targetInc is target:orbit:inclination. }
else { global targetInc is targetIncParam. }
global windowOffset is 2.5.    // [2] DN=0.2
global goForLaunch is false.
global MaxQ is 0.155.    // set to kPa / 100k  [0.15]
global AoAlimiter is 20.

// data link on CPUs
set copyVal to lexicon(
    "tgtInc", targetInc,
    "tgtOrb", targetOrb,
    "prf", profile,
    "pMass", payloadMass,
    "maxPmass", maxPayload,
    "lzcoords0", LZ0,
    "lzcoords", LZ,
    "lzcoords1", LZ1,
    "mecoAng", MECOangle,
    "rntryAlt", reentryHeight,
    "rntryVel", reentryVelocity,
    "aoalim", AoAlimiter).

// send data to CPUs
set recCPU to processor("VC-13B").
recCPU:connection:sendmessage(copyVal).
if (profile = "Heavy") {
    set ArecCPU to processor("ABooster").
    ArecCPU:connection:sendmessage(copyVal).

    set BrecCPU to processor("BBooster").
    BrecCPU:connection:sendmessage(copyVal).
}
    
wait 1.
profileGUI:hide().

function RTLSmd {
    if (RTLSrad:pressed) { 
        set lay1 to true.
        global maxPayload is 7000.
        global profile is "RTLS".
        global tangentAltitude is body:atm:height - 5000.
        global MECOangle is 45.
        global targetAp is 60000.
        global pitchGain is 1.0815. // 1.0815
        global reentryHeight is 30000.
        global reentryVelocity is 400.
    }
}
    
function ASDSmd {
    if (ASDSrad:pressed) { 
        set lay1 to true.
        global maxPayload is 9000.
        global profile is "ASDS".
        global tangentAltitude is body:atm:height + 5000.
        global MECOangle is 40.
        global targetAp is 62500.
        global pitchGain is 1.0815.
        global reentryHeight is 32500.
        global reentryVelocity is 500.
    }
}

function HEAVYmd {
    if (HEAVYrad:pressed) {
        set lay1 to true.
        global maxPayload is 15000.
        global profile is "Heavy".
        global tangentAltitude is body:atm:height + 10000.
        global MECOangle is 45.
        global targetAp is 65000.
        global pitchGain is 1.0815.
        global reentryHeight is 30000.
        global reentryVelocity is 400.
    }
}

function EXPNmd {
    if (EXPNrad:pressed) { 
        set lay1 to true.
        global maxPayload is 15000.
        global profile is "Full".
        global tangentAltitude is body:atm:height + 5000.
        global MECOangle is 20.
        global targetAp is 65000.
        global pitchGain is 0.725.
        global landingOffset is -0.00085.
        global reentryHeight is 30000.
        global reentryVelocity is 410.
        // recovery parameters are still added to prevent unknown variables errors
    }
}

function payloadM {
    parameter val. 

    if (val:tostring:length > 0) { 
        global payloadMass is val:tonumber. 
        set lay2 to true.
    } else {
        set lay2 to false.
    } 
}

function orbitA {
    parameter val. 
    
    if (val:tostring:length > 0) { 
        global targetOrb is (val:tonumber * 1000). 
        set lay3 to true.
    } else {
        set lay3 to false.
    }
}

function orbitI {
    parameter val. 
    
    if (val:tostring:length > 0) { 
        global targetIncParam is val:tonumber.
        set lay3 to true.
    } else {
        set lay3 to false.
    }
}

function GIGmd {
    if (GIGrad:pressed) {
        global payloadType is "gigan".
        set lay4 to true.
    }
}

function RODmd {
    if (RODrad:pressed) {
        global payloadType is "rodan".
        set lay4 to true.
    }
}

function FRNGmd {
    if (FRNGrad:pressed) {
        global payloadType is "fairing".
        set lay4 to true.
    }
}

function DockBool {
    parameter val is false. global hasWindow is val.

    if (hasWindow and (tempTarget:tostring:length > 0)) { set lay5 to true. }
    else if (hasWindow = false and (tempTarget:tostring:length > 0)) { set lay5 to false. }
    else if (hasWindow = false) { set lay5 to true. }
    else { set lay5 to false. }
}

function DockName {
    parameter val. global tempTarget is val.

    if (hasWindow and (val:tostring:length > 0)) { 
        set lay5 to true. 
        set lay6 to true. 
    }
    else if (hasWindow = false and (val:tostring:length > 0)) { set lay6 to false. }
    else if (hasWindow = false) { set lay6 to true. }
    else { set lay6 to false. }
}

// DEBUG MODE (overwrite GUI input, same stuff as NOGUI)
// global targetIncParam is 0.
// global targetOrb is 120000.
// global payloadMass is 7000.
// global maxPayload is 7000.
// global payloadType is "fairings".
// global profile is "RTLS".
// global tangentAltitude is body:atm:height - 5000.
// global MECOangle is 45.
// global targetAp is 65000. //57500-60000
// global pitchGain is 1.0815. //0.95
// global reentryHeight is 27000.
// global reentryVelocity is 600. // 385