# A320 Main Libraries
# Joshua Davidson (Octal450)

# Copyright (c) 2021 Josh Davidson (Octal450)

print("------------------------------------------------");
print("Copyright (c) 2016-2021 Josh Davidson (Octal450)");
print("------------------------------------------------");

# Disable specific menubar items
setprop("/sim/menubar/default/menu[0]/item[0]/enabled", 0);
setprop("/sim/menubar/default/menu[2]/item[0]/enabled", 0);
setprop("/sim/menubar/default/menu[2]/item[2]/enabled", 0);
setprop("/sim/menubar/default/menu[3]/enabled", 0);
setprop("/sim/menubar/default/menu[5]/item[9]/enabled", 0);
setprop("/sim/menubar/default/menu[5]/item[10]/enabled", 0);
setprop("/sim/menubar/default/menu[5]/item[11]/enabled", 0);

# Oil Qty
var qty1 = math.round((rand() * 5 ) + 20, 0.1);
var qty2 = math.round((rand() * 5 ) + 20, 0.1);
setprop("/engines/engine[0]/oil-qt-actual", qty1);
setprop("/engines/engine[1]/oil-qt-actual", qty2);

##########
# Lights #
##########
var beacon = aircraft.light.new("/sim/model/lights/beacon", [0.1, 1], "/controls/lighting/beacon");
var strobe = aircraft.light.new("/sim/model/lights/strobe", [0.05, 0.06, 0.05, 1], "/controls/lighting/strobe");
var tail_strobe = aircraft.light.new("/sim/model/lights/tailstrobe", [0.1, 1], "/controls/lighting/strobe");

###########
# Effects #
###########

var tiresmoke_system = aircraft.tyresmoke_system.new(0, 1, 2);
aircraft.rain.init();

var aero = getprop("/sim/aero");
var defaultFuseLiv = "";
if (aero == "A320-200-CFM") {
	var livery = aircraft.canvas_livery.init("Models/Liveries/CFM");
	elements = ["EngineCFM56L","EngineCFM56R","ReverserLDoor1","ReverserLDoor2","ReverserLDoor3","ReverserLDoor4","ReverserRDoor1","ReverserRDoor2","ReverserRDoor3","ReverserRDoor4","PylonCFM56L","PylonCFM56R","IntakeCFM56L","IntakeCFM56R"];
	livery.createTarget("engines", elements, "sim/model/livery/texture-engine", "Aircraft/A320-family/Models/Liveries/CFM/2k/SWR-engine.png");
	livery.addLayer("engines", "dirt", "Aircraft/A320-family/Models/Liveries/CFM/engine-dirt.png");
	defaultFuseLiv = "Aircraft/A320-family/Models/Liveries/CFM/4k/SWR-fuselage.png";
} else if (aero == "A320-200-IAE") {
	var livery = aircraft.canvas_livery.init("Models/Liveries/IAE");
	elements = ["EngineIAEV2500L","EngineIAEV2500R","ReverserLDoor","ReverserRDoor","PylonIAEV2500L","PylonIAEV2500R","IntakeIAEV2500L","IntakeIAEV2500R"];
	livery.createTarget("engines", elements, "sim/model/livery/texture-engine", "Aircraft/A320-family/Models/Liveries/IAE/2k/QTR-engine.png");
	livery.addLayer("engines", "dirt", "Aircraft/A320-family/Models/Liveries/IAE/engine-dirt.png");
	defaultFuseLiv = "Aircraft/A320-family/Models/Liveries/IAE/4k/QTR-fuselage.png";
} else if (aero == "A320neo-CFM") {
	var livery = aircraft.canvas_livery.init("Models/Liveries/CFM-NEO");
	elements = ["EngineLEAPL", "EngineLEAPL.007", "EngineLEAPL.Inner", "EngineLEAPR", "EngineLEAPR.Inner", "Exhaust2LEAPL", "Exhaust2LEAPR", "Exhaust3LEAPL", "Exhaust3LEAPR", "IntakeLEAPL", "IntakeLEAPR", "PylonLEAPL", "PylonLEAPR", "ReverserLDoorLEAP", "ReverserRDoorLEAP"];
	livery.createTarget("engines", elements, "sim/model/livery/texture-engine", "Aircraft/A320-family/Models/Liveries/CFM-NEO/2k/SAS-engine.png");
#	livery.addLayer("engines", "dirt", "Aircraft/A320-family/Models/Liveries/CFM-NEO/engine-dirt.png");
	defaultFuseLiv = "Aircraft/A320-family/Models/Liveries/CFM-NEO/4k/SAS-fuselage.png";
} else if (aero == "A320neo-PW") {
	var livery = aircraft.canvas_livery.init("Models/Liveries/PW-NEO");
	elements = ["EnginePWPP", "EnginePWPPL.Inner", "EnginePWPPR", "EnginePWPPR.Inner", "Exhaust3PWPPL", "Exhaust3PWPPR", "Exxhaust2PWPPL", "Exxhaust2PWPPR", "IntakePWPPL", "IntakePWPPR", "PylonPWPPL", "PylonPWPPR", "ReverserLDoorLPWPP", "ReverserLDoorRPWPP"];
	livery.createTarget("engines", elements, "sim/model/livery/texture-engine", "Aircraft/A320-family/Models/Liveries/PW-NEO/2k/NKS-engine.png");
#	livery.addLayer("engines", "dirt", "Aircraft/A320-family/Models/Liveries/PW-NEO/engine-dirt.png");
	defaultFuseLiv = "Aircraft/A320-family/Models/Liveries/PW-NEO/4k/NKS-fuselage.png";
}

var elements = ["AileronL","AileronR","Antenna1","Antenna2","ApuFlap","AvionicsVentDoor","Cargo1","Cargo2","Cargo3","DoorL1","DoorL4","DoorR1","DoorR4","ElevatorL","ElevatorR","EngineFairingL","EngineFairingR","FairingL1","FairingL2","FairingL3","FairingR1","FairingR2","FairingR3","FlapL1","FlapL2","FlapR1","FlapR2","Fuselage","GPUServiceDoor","Hstabs","MLGGearDoorL","MLGGearDoorR","MLGWingDoorL1","MLGWingDoorL2","MLGWingDoorR1","MLGWingDoorR2","NLGAftDoorL","NLGAftDoorR","NLGFittingPanel","NLGForewardDoorL","NLGForewardDoorR","OutflowValveDoor1","OutflowValveDoor2","RatDoorL","RatDoorR","Rudder","Sharklet","SlatL1","SlatL2","SlatR1","SlatR2","SpoilerL1","SpoilerL2","SpoilerL3","SpoilerL4","SpoilerL5","SpoilerR1","SpoilerR2","SpoilerR3","SpoilerR4","SpoilerR5","Wings","WingtipFence"];
livery.createTarget("fuselage", elements, "sim/model/livery/texture-fuselage", defaultFuseLiv, resolution=16384);
livery.addLayer("fuselage", "dirt", "Aircraft/A320-family/Models/Liveries/fuselage-dirt.png");

#########
# Doors #
#########

# Front doors
var doorl1 = aircraft.door.new("/sim/model/door-positions/doorl1", 5);
var doorr1 = aircraft.door.new("/sim/model/door-positions/doorr1", 5);

# Rear doors
var doorl4 = aircraft.door.new("/sim/model/door-positions/doorl4", 5);
var doorr4 = aircraft.door.new("/sim/model/door-positions/doorr4", 5);

# Cargo holds
var cargobulk = aircraft.door.new("/sim/model/door-positions/cargobulk", 3);
var cargoaft = aircraft.door.new("/sim/model/door-positions/cargoaft", 10);
var cargofwd = aircraft.door.new("/sim/model/door-positions/cargofwd", 10);

# Seat armrests in the flight deck (unused)
var armrests = aircraft.door.new("/sim/model/door-positions/armrests", 2);
var windowLeft = aircraft.door.new("/sim/model/door-positions/windowLeft", 1);
var windowRight = aircraft.door.new("/sim/model/door-positions/windowRight", 1);

# door opener/closer
var triggerDoor = func(door, doorName, doorDesc) {
	if (getprop("/sim/model/door-positions/" ~ doorName ~ "/position-norm") > 0) {
		gui.popupTip("Closing " ~ doorDesc ~ " door");
		door.toggle();
	} else {
		if (getprop("/velocities/groundspeed-kt") > 5) {
			gui.popupTip("You cannot open the doors while the aircraft is moving!");
		} else {
			gui.popupTip("Opening " ~ doorDesc ~ " door");
			door.toggle();
		}
	}
};

###########
# Systems #
###########
var systemsInitialized = 0;
var A320Libraries = nil;

var systemsInit = func() {
	systemsInitialized = 0;
	fbw.FBW.init();
	effects.lightManager.init();
	systems.ELEC.init();
	systems.PNEU.init();
	systems.HYD.init();
	systems.FUEL.init();
	systems.ADIRS.init();
	systems.eng_init();
	systems.ENGINE.init();
	systems.FADEC.init();
	systems.APUController.init();
	systems.BrakeSys.reset();
	systems.Autobrake.init();
	systems.fire_init();
	fmgc.flightPlanController.reset();
	fmgc.windController.reset();
	fmgc.ITAF.init();
	fmgc.FMGCinit();
	mcdu.MCDU_init(0);
	mcdu.MCDU_init(1);
	mcdu_scratchpad.mcduMsgtimer1.start();
	mcdu_scratchpad.mcduMsgtimer2.start();
	effects.icingInit();
	ecam.ECAM.init();
	libraries.variousReset();
	rmp.init();
	acp.init();
	ecam.ECAM_controller.init();
	atc.init();
	fcu.FCUController.init();
	dmc.DMController.init();
	fmgc.flightPlanController.init();
	fmgc.windController.init();
	atsu.CompanyCall.init();
	systemsInitialized = 1;
}

setlistener("/sim/signals/fdm-initialized", func() {
	systemsInit();
	fmgc.postInit();
	fmgc.flightPlanTimer.start();
	fmgc.WaypointDatabase.read();

	A320Libraries = LibrariesRecipient.new("A320 Libraries");
	emesary.GlobalTransmitter.Register(A320Libraries);
});

var collectorTankL = props.globals.getNode("/fdm/jsbsim/propulsion/tank[5]/contents-lbs");
var collectorTankR = props.globals.getNode("/fdm/jsbsim/propulsion/tank[6]/contents-lbs");
var groundAir = props.globals.getNode("/controls/pneumatics/switches/groundair");
var groundCart = props.globals.getNode("/controls/electrical/ground-cart");
var chocks = props.globals.getNode("/services/chocks/enable");
var groundspeed = 0;
var stateL = 0;
var stateR = 0;

var seatbeltSwitch = props.globals.getNode("/controls/switches/seatbelt-sign");
var noSmokingSwitch = props.globals.getNode("/controls/switches/no-smoking-sign");
var emerLtsSwitch = props.globals.getNode("/controls/switches/emer-lights");
var seatbeltLight = props.globals.getNode("/controls/lighting/seatbelt-sign");
var noSmokingLight = props.globals.getNode("/controls/lighting/no-smoking-sign");

var update_items = [
	props.UpdateManager.FromHashValue("seatbelt", nil, func(val) {
		if (val) {
			if (!seatbeltLight.getBoolValue()) {
				seatbeltLight.setValue(1);
			}
		} else {
			if (seatbeltLight.getBoolValue()) {
				seatbeltLight.setValue(0);
			}
		}
	}),
	props.UpdateManager.FromHashList(["noSmoking","gearPosNorm"], nil, func(val) {
		if (val.noSmoking == 1) {
			if (!noSmokingLight.getBoolValue()) {
				noSmokingLight.setBoolValue(1);
			}
		} elsif (val.noSmoking == 0.5 and val.gearPosNorm != 0) { # todo: should be when uplocks not engaged
			if (!noSmokingLight.getBoolValue()) {
				noSmokingLight.setBoolValue(1);
			}
		} else {
			noSmokingLight.setBoolValue(0); # sign stays on in cabin but sound still occurs
		}
	}),
];

var systemsLoop = func(notification) {
	if (!systemsInitialized and getprop("/systems/acconfig/mismatch-code") != "0x000") { return; }
	systems.PNEU.loop(notification);
	systems.ADIRS.loop(notification);
	systems.BrakeSys.update(notification);
	systems.HFLoop(notification);
	systems.APUController.loop();
	systems.FADEC.loop();
	rmp.rmpUpdate();
	fcu.FCUController.loop(notification);
	atc.Transponders.vector[atc.transponderPanel.atcSel - 1].update(notification);
	dmc.DMController.loop();
	atsu.ATSU.loop();
	libraries.BUTTONS.update();
	
	if ((notification.engine1State == 2 or notification.engine1State == 3) and collectorTankL.getValue() < 1) {
		systems.cutoff_one();
	}
	if ((notification.engine2State == 2 or notification.engine2State == 3) and collectorTankR.getValue() < 1) {
		systems.cutoff_two();
	}
	
	foreach (var update_item; update_items) {
		update_item.update(notification);
	}
}

# GPWS
var GPWS = {
	inhibitNode: props.globals.getNode("/instrumentation/mk-viii/inputs/discretes/gpws-inhibit"),
	tatcfInhibit: props.globals.getNode("/instrumentation/mk-viii/inputs/discretes/ta-tcf-inhibit"),
	volume: props.globals.getNode("/instrumentation/mk-viii/speaker/volume"),
	flapAllOverride: props.globals.getNode("/instrumentation/mk-viii/inputs/discretes/momentary-flap-all-override"),
	flap3Override: props.globals.getNode("/instrumentation/mk-viii/inputs/discretes/momentary-flap-3-override"),
	flapOverride: props.globals.getNode("/instrumentation/mk-viii/inputs/discretes/momentary-flap-override"),
	alertMode: props.globals.initNode("/instrumentation/mk-viii/outputs/alert-mode",0,"INT"),
};

setlistener("/instrumentation/mk-viii/inputs/discretes/gpws-inhibit", func() {
	if (GPWS.inhibitNode.getBoolValue()) {
		GPWS.volume.setValue(2);
	} else {
		GPWS.volume.setValue(0);
	}
}, 0, 0);

var updateGPWSFlap = func() {
	if (GPWS.flapAllOverride.getBoolValue() or (GPWS.flap3Override.getBoolValue() and pts.Controls.Flight.flapsPos.getValue() >= 4)) {
		GPWS.flapOverride.setBoolValue(1);
	} else {
		GPWS.flapOverride.setBoolValue(0);
	}
}

setlistener("/instrumentation/mk-viii/inputs/discretes/momentary-flap-all-override", func() {
	updateGPWSFlap();
}, 0, 0);

setlistener("/instrumentation/mk-viii/inputs/discretes/momentary-flap-3-override", func() {
	updateGPWSFlap();
}, 0, 0);

# GPWS alert pooling for get mode change - a little esoteric way but it works
var gpws_alert_watch = maketimer(0.8,func {	
	var alert = 0;
	if (getprop("instrumentation/mk-viii/outputs/discretes/gpws-warning")) alert = 2; # MODE2 - warning - RED
	else if (getprop("instrumentation/mk-viii/outputs/discretes/gpws-alert")) alert = 1; # MODE1 - caution - YELLOW
	if (GPWS.alertMode.getValue()!=alert) GPWS.alertMode.setValue(alert);
});

setlistener("/instrumentation/mk-viii/inputs/discretes/ta-tcf-inhibit", func{   # detect GPWS switch status
	var failure = GPWS.tatcfInhibit.getBoolValue();
	if (!failure) gpws_alert_watch.start();
	else gpws_alert_watch.stop();
},1,0);

# Replay
var replayState = props.globals.getNode("/sim/replay/replay-state");
setlistener(replayState, func(v) {
	if (v.getBoolValue()) {
	} else {
		acconfig.colddark();
		gui.popupTip("Replay Ended: Setting Cold and Dark state...");
	}
}, 0, 0);

# Steep ILS
setlistener("/options/steep-ils", func() {
	if (getprop("/options/steep-ils") == 1) {
		setprop("/instrumentation/mk-viii/inputs/discretes/steep-approach", 1);
	} else {
		setprop("/instrumentation/mk-viii/inputs/discretes/steep-approach", 0);
	}
}, 0, 0);

# hackCanvas
canvas.Text._lastText = canvas.Text["_lastText"];
canvas.Text.setText = func(text) {
	if (text == me._lastText and text != nil and size(text) == size(me._lastText)) {return me;}
	me._lastText = text;
	me.set("text", typeof(text) == 'scalar' ? text : "");
};
canvas.Element._lastVisible = nil;
canvas.Element.show = func() {
	if (1 == me._lastVisible) {return me;}
	me._lastVisible = 1;
	me.setBool("visible", 1);
};
canvas.Element.hide = func() {
	if (0 == me._lastVisible) {return me;}
	me._lastVisible = 0;
	me.setBool("visible", 0);
};
canvas.Element.setVisible = func(vis) {
	if (vis == me._lastVisible) {return me;}
	me._lastVisible = vis;
	me.setBool("visible", vis);
};

##########
# Misc   #
##########
var pilotComfortTwoPos = func(prop) {
	var item = getprop(prop);
	if (item < 0.5) {
		interpolate(prop, 0.5, 0.5);
	} elsif (item == 0.5) {
		interpolate(prop, 1.0, 0.5);
	} else {
		interpolate(prop, 0.0, 1.0);
	}
}

var pilotComfortOnePos = func(prop) {
	var item = getprop(prop);
	if (item < 1.0) {
		interpolate(prop, 1.0, 1.0);
	} else {
		interpolate(prop, 0.0, 1.0);
	}
}

var lTray = func() {
	pilotComfortTwoPos("/controls/tray/lefttrayext");
}
var rTray = func() {
	pilotComfortTwoPos("/controls/tray/righttrayext");
}

var l1Pedal = func() {
	pilotComfortOnePos("/controls/footrest-cpt[0]");
}
var l2Pedal = func() {
	pilotComfortOnePos("/controls/footrest-cpt[1]");
}

var r1Pedal = func() {
	pilotComfortOnePos("/controls/footrest-fo[0]");
}
var r2Pedal = func() {
	pilotComfortOnePos("/controls/footrest-fo[1]");
}

#####################
# Auto-coordination #
#####################

if (pts.Controls.Flight.autoCoordination.getBoolValue()) {
    pts.Controls.Flight.autoCoordination.setBoolValue(0);
    pts.Controls.Flight.aileronDrivesTiller.setBoolValue(1);
} else {
    pts.Controls.Flight.aileronDrivesTiller.setBoolValue(0);
}

setlistener("/controls/flight/auto-coordination", func() {
    pts.Controls.Flight.autoCoordination.setBoolValue(0);
	print("System: Auto Coordination has been turned off as it is not compatible with the fly-by-wire of this aircraft.");
	screen.log.write("Auto Coordination has been disabled as it is not compatible with the fly-by-wire of this aircraft", 1, 0, 0);
}, 0, 0);

##############
# Legacy FCU #
##############
var APPanel = {
	APDisc: func() {
		fcu.FCUController.APDisc();
	},
	ATDisc: func() {
		fcu.FCUController.ATDisc();
	},
};


# Emesary
var LibrariesRecipient =
{
	new: func(_ident)
	{
		var NewLibrariesRecipient = emesary.Recipient.new(_ident);
		NewLibrariesRecipient.Receive = func(notification)
		{
			if (notification.NotificationType == "FrameNotification")
			{
				if (math.mod(notifications.frameNotification.FrameCount,4) == 0) {
					systemsLoop(notification);
				}
				return emesary.Transmitter.ReceiptStatus_OK;
			}
			return emesary.Transmitter.ReceiptStatus_NotProcessed;
		};
		return NewLibrariesRecipient;
	},
};

var input = {
	# Libraries
	"seatbelt": "/controls/switches/seatbelt-sign",
	"noSmoking": "/controls/switches/no-smoking-sign",
	"gearPosNorm": "/gear/gear[0]/position-norm",
	"gearPosNorm1": "/gear/gear[1]/position-norm",
	"gearPosNorm2": "/gear/gear[2]/position-norm",
	"engine1Running": "/engines/engine[0]/running",
	"engine2Running": "/engines/engine[1]/running",
};

foreach (var name; keys(input)) {
	emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new("A320 Libraries", name, input[name]));
}

var hideCanvas = props.globals.getNode("/options/hide-canvas-outside");
var internal = props.globals.getNode("/sim/current-view/internal");
var toggleScreen = func() {
	if (!internal.getValue() and hideCanvas.getValue()) {
		canvas_nd.nd_update.stop();
		canvas_dcdu.DCDU_update.stop();
		canvas_mcdu.MCDU_update.stop();
	} else {
		canvas_nd.rateApply();
		canvas_dcdu.rateApply();
		canvas_mcdu.MCDU_update.start();
	}
};

setlistener("/options/hide-canvas-outside", func() {
	toggleScreen();
}, 0, 0);

setlistener("/sim/current-view/internal", func() {
	toggleScreen();
}, 0, 0);

# TODO split EFIS altimeters
var newinhg = nil;
setlistener("/instrumentation/altimeter/setting-inhg", func() {
	newinhg = getprop("/instrumentation/altimeter/setting-inhg");
	setprop("/instrumentation/altimeter[1]/setting-inhg", newinhg);
	setprop("/instrumentation/altimeter[2]/setting-inhg", newinhg);
	setprop("/instrumentation/altimeter[3]/setting-inhg", newinhg);
	setprop("/instrumentation/altimeter[4]/setting-inhg", newinhg);
	setprop("/instrumentation/altimeter[5]/setting-inhg", newinhg);
}, 0, 0);

var newhpa = nil;
setlistener("/instrumentation/altimeter/setting-hpa", func() {
	newhpa = getprop("/instrumentation/altimeter/setting-hpa");
	setprop("/instrumentation/altimeter[1]/setting-hpa", newhpa);
	setprop("/instrumentation/altimeter[2]/setting-hpa", newhpa);
	setprop("/instrumentation/altimeter[3]/setting-hpa", newhpa);
	setprop("/instrumentation/altimeter[4]/setting-hpa", newhpa);
	setprop("/instrumentation/altimeter[5]/setting-hpa", newhpa);
}, 0, 0);

setprop("/systems/acconfig/libraries-loaded", 1);
