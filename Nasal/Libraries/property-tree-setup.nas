# A320 Property Tree Setup
# Copyright (c) 2021 Josh Davidson (Octal450) and Jonathan Redpath
# Nodes organized like property tree, except when lots of identical (example: Gear wow), where vectors are used to make it easier
# Anything that says Temp is set by another file to avoid multiple getValue calls
# Usage Example: pts.Class.SubClass.node.getValue()

var Autopilot = {
	Settings: {
		headingBugDeg: props.globals.getNode("/autopilot/settings/heading-bug-deg",1),
		targetAltitudeFt: props.globals.getNode("/autopilot/settings/target-altitude-ft",1),
	},
};

var Accelerations = {
	pilotGDamped: props.globals.getNode("/accelerations/pilot-gdamped"),
};

var Acconfig = {
	running: props.globals.getNode("/systems/acconfig/autoconfig-running"),
};

var APU = {
	rpm: props.globals.getNode("/engines/engine[2]/n1"),
};

var Consumables = {
	Fuel: {
		totalFuelLbs: props.globals.getNode("/consumables/fuel/total-fuel-lbs"),
	},
};

var Controls = {
	Engines: {
		startSw: props.globals.getNode("/controls/engines/engine-start-switch"),
		Engine: {
			cutoff: [props.globals.getNode("/controls/engines/engine[0]/cutoff"), props.globals.getNode("/controls/engines/engine[1]/cutoff")],
			cutoffSw: [props.globals.getNode("/controls/engines/engine[0]/cutoff-switch"), props.globals.getNode("/controls/engines/engine[1]/cutoff-switch")],
			firePb: [props.globals.getNode("/controls/engines/engine[0]/fire-btn"), props.globals.getNode("/controls/engines/engine[1]/fire-btn")],
			reverseCmd: [props.globals.getNode("/controls/engines/engine[0]/reverse-cmd"), props.globals.getNode("/controls/engines/engine[1]/reverse-cmd")],
			reverseLever: [props.globals.getNode("/controls/engines/engine[0]/reverse-lever"), props.globals.getNode("/controls/engines/engine[1]/reverse-lever")],
			starter: [props.globals.getNode("/controls/engines/engine[0]/starter"), props.globals.getNode("/controls/engines/engine[1]/starter")],
			throttle: [props.globals.getNode("/controls/engines/engine[0]/throttle"), props.globals.getNode("/controls/engines/engine[1]/throttle")],
		},
	},
	Flight: {
		aileron: props.globals.getNode("/controls/flight/aileron"),
		aileronDrivesTiller: props.globals.getNode("/controls/flight/aileron-drives-tiller"),
		autoCoordination: props.globals.getNode("/controls/flight/auto-coordination"),
		elevator: props.globals.getNode("/controls/flight/elevator"),
		elevatorTrim: props.globals.getNode("/controls/flight/elevator-trim"),
		flaps: props.globals.getNode("/controls/flight/flaps"),
		flapsTemp: 0,
		flapsInput: props.globals.getNode("/controls/flight/flaps-input"),
		flapsPos: props.globals.getNode("/controls/flight/flaps-pos"),
		speedbrake: props.globals.getNode("/controls/flight/speedbrake"),
		speedbrakeArm: props.globals.getNode("/controls/flight/speedbrake-arm"),
		speedbrakeTemp: 0,
		rudder: props.globals.getNode("/controls/flight/rudder"),
		rudderTrim: props.globals.getNode("/controls/flight/rudder-trim"),
	},
	Gear: {
		brake: [props.globals.getNode("/controls/gear/brake-left"),props.globals.getNode("/controls/gear/brake-right")],
		gearDown: props.globals.getNode("/controls/gear/gear-down"),
		parkingBrake: props.globals.getNode("/controls/gear/brake-parking"),
		chocks: props.globals.getNode("/services/chocks/enable"),
	},
	Lighting: {
		landingLights: [props.globals.getNode("/controls/lighting/landing-lights[0]"),props.globals.getNode("/controls/lighting/landing-lights[1]"),props.globals.getNode("/controls/lighting/landing-lights[2]")],
	},
	Switches: {
		annunTest: props.globals.getNode("/controls/switches/annun-test"),
	},
};

var ECAM = {
	fwcWarningPhase: props.globals.getNode("/ECAM/warning-phase"),
};

var Engines = {
	Engine: {
		egtActual: [props.globals.getNode("/engines/engine[0]/egt-actual"), props.globals.getNode("/engines/engine[1]/egt-actual")],
		eprActual: [props.globals.getNode("/engines/engine[0]/epr-actual"), props.globals.getNode("/engines/engine[1]/epr-actual")],
		fuelFlow: [props.globals.getNode("/engines/engine[0]/ff-actual"), props.globals.getNode("/engines/engine[1]/ff-actual")],
		n1Actual: [props.globals.getNode("/engines/engine[0]/n1-actual"), props.globals.getNode("/engines/engine[1]/n1-actual")],
		n2Actual: [props.globals.getNode("/engines/engine[0]/n2-actual"), props.globals.getNode("/engines/engine[1]/n2-actual")],
		oilPsi: [props.globals.getNode("/engines/engine[0]/oil-psi-actual"), props.globals.getNode("/engines/engine[1]/oil-psi-actual")],
		oilQt: [props.globals.getNode("/engines/engine[0]/oil-qt-actual"), props.globals.getNode("/engines/engine[1]/oil-qt-actual")],
		thrust: [props.globals.getNode("/engines/engine[0]/thrust-lb"), props.globals.getNode("/engines/engine[1]/thrust-lb")],
		reverser: [props.globals.getNode("/engines/engine[0]/reverser-pos-norm"), props.globals.getNode("/engines/engine[1]/reverser-pos-norm")],
		state: [props.globals.getNode("/engines/engine[0]/state"), props.globals.getNode("/engines/engine[1]/state")],
		stateTemp: [0, 0],
	},
};

var Environment = {
	magVar: props.globals.getNode("/environment/magnetic-variation-deg"),
	tempDegC: props.globals.getNode("/environment/temperature-degc"),
	windFromHdg: props.globals.getNode("/environment/wind-from-heading-deg"),
	windSpeedKt: props.globals.getNode("/environment/wind-speed-kt"),
};

var Fdm = {
	JSBsim: {
		Aero: {
			alpha: props.globals.getNode("/fdm/jsbsim/aero/alpha-deg"),
			alphaNorm: props.globals.getNode("/fdm/jsbsim/aero/alpha-deg-norm"),
		},
		Fadec: {
			detent: [props.globals.getNode("/fdm/jsbsim/fadec/control-1/detent"),props.globals.getNode("/fdm/jsbsim/fadec/control-2/detent")],
		},
		Fcs: {
			brake: [props.globals.getNode("/fdm/jsbsim/fcs/left-brake-cmd-norm"),props.globals.getNode("/fdm/jsbsim/fcs/right-brake-cmd-norm")],
			flapDeg: props.globals.getNode("/fdm/jsbsim/fcs/flap-pos-deg"),
			slatDeg: props.globals.getNode("/fdm/jsbsim/fcs/slat-pos-deg"),
			slatLocked: props.globals.getNode("/fdm/jsbsim/fcs/slat-locked"),
		},
		Fbw: {
			aileron: props.globals.getNode("/fdm/jsbsim/fbw/aileron-sidestick"),
			elevator: props.globals.getNode("/fdm/jsbsim/fbw/elevator-sidestick"),
		},
		Hydraulics: {
			Rudder: {
				trimDeg: props.globals.getNode("/fdm/jsbsim/hydraulics/rudder/trim-deg"),
			},
			Stabilizer: {
				cmdDeg: props.globals.getNode("/fdm/jsbsim/hydraulics/stabilizer/cmd-deg"),
			},
		},
		Inertia: {
			weightLbs: props.globals.getNode("/fdm/jsbsim/inertia/weight-lbs"),
		},
		Position: {
			wow: props.globals.getNode("/fdm/jsbsim/position/wow"),
		},
		Propulsion: {
			tatC: props.globals.getNode("/fdm/jsbsim/propulsion/tat-c"),
			Engine: {
				fuelUsed: [props.globals.getNode("/fdm/jsbsim/propulsion/engine[0]/fuel-used-lbs"), props.globals.getNode("/fdm/jsbsim/propulsion/engine[1]/fuel-used-lbs")],
				reverserAngle: [props.globals.getNode("/fdm/jsbsim/propulsion/engine[0]/reverser-angle-rad"), props.globals.getNode("/fdm/jsbsim/propulsion/engine[1]/reverser-angle-rad")],
			},
		},
	},
};

var FMGC = {
	CasCompare: {
		casRejectAll: props.globals.getNode("/systems/fmgc/cas-compare/cas-reject-all"),
	},
};

var Gear = {
	compression: [props.globals.getNode("/gear/gear[0]/compression-norm"), props.globals.getNode("/gear/gear[1]/compression-norm"), props.globals.getNode("/gear/gear[2]/compression-norm")],
	position: [props.globals.getNode("/gear/gear[0]/position-norm"), props.globals.getNode("/gear/gear[1]/position-norm"), props.globals.getNode("/gear/gear[2]/position-norm")],
	rollspeed: [props.globals.getNode("/gear/gear[0]/rollspeed-ms"), props.globals.getNode("/gear/gear[1]/rollspeed-ms"), props.globals.getNode("/gear/gear[2]/rollspeed-ms")],
	wow: [props.globals.getNode("/gear/gear[0]/wow"), props.globals.getNode("/gear/gear[1]/wow"), props.globals.getNode("/gear/gear[2]/wow")],
	wowTemp: [0, 0, 0],
};

var Instrumentation = {
	AirspeedIndicator: {
		indicatedSpdKt: props.globals.getNode("/instrumentation/airspeed-indicator/indicated-speed-kt"),
		indicatedMach: props.globals.getNode("/instrumentation/airspeed-indicator/indicated-mach"),
	},
	Altimeter: {
		indicatedFt: props.globals.getNode("/instrumentation/altimeter[0]/indicated-altitude-ft"),
		oldQnh: props.globals.getNode("/instrumentation/altimeter[0]/oldqnh"),
		settingInhg: props.globals.getNode("/instrumentation/altimeter[0]/setting-inhg"),
		std: props.globals.getNode("/instrumentation/altimeter[0]/std"),
	},
	Clock: {
		indicatedString: props.globals.getNode("/instrumentation/clock/indicated-string"),
		indicatedStringShort: props.globals.getNode("/instrumentation/clock/indicated-short-string"),
	},
	Dcdu: {
		lcdOn: props.globals.initNode("/instrumentation/dcdu/lcd-on", 0, "BOOL"),
	},
	Du: {
		du1On: props.globals.initNode("/instrumentation/du/du1-on", 0, "BOOL"),
		du2On: props.globals.initNode("/instrumentation/du/du2-on", 0, "BOOL"),
		du3On: props.globals.initNode("/instrumentation/du/du3-on", 0, "BOOL"),
		du4On: props.globals.initNode("/instrumentation/du/du4-on", 0, "BOOL"),
		du5On: props.globals.initNode("/instrumentation/du/du5-on", 0, "BOOL"),
		du6On: props.globals.initNode("/instrumentation/du/du6-on", 0, "BOOL"),
	},
	Efis: {
		Inputs: {
			arpt: [props.globals.initNode("/instrumentation/efis[0]/inputs/arpt", 0, "BOOL"), props.globals.initNode("/instrumentation/efis[1]/inputs/arpt", 0, "BOOL")],
			cstr: [props.globals.initNode("/instrumentation/efis[0]/inputs/CSTR", 0, "BOOL"), props.globals.initNode("/instrumentation/efis[1]/inputs/CSTR", 0, "BOOL")],
			dme: [props.globals.initNode("/instrumentation/efis[0]/inputs/DME", 0, "BOOL"), props.globals.initNode("/instrumentation/efis[1]/inputs/DME", 0, "BOOL")],
			ndb: [props.globals.initNode("/instrumentation/efis[0]/inputs/NDB", 0, "BOOL"), props.globals.initNode("/instrumentation/efis[1]/inputs/NDB", 0, "BOOL")],
			rangeNm: [props.globals.initNode("/instrumentation/efis[0]/inputs/range-nm", 20, "INT"), props.globals.initNode("/instrumentation/efis[1]/inputs/range-nm", 20, "INT")],
			tfc: [props.globals.initNode("/instrumentation/efis[0]/inputs/tfc", 0, "BOOL"), props.globals.initNode("/instrumentation/efis[1]/inputs/tfc", 0, "BOOL")],
			vord: [props.globals.initNode("/instrumentation/efis[0]/inputs/VORD", 0, "BOOL"), props.globals.initNode("/instrumentation/efis[1]/inputs/VORD", 0, "BOOL")],
			wpt: [props.globals.initNode("/instrumentation/efis[0]/inputs/wpt", 0, "BOOL"), props.globals.initNode("/instrumentation/efis[1]/inputs/wpt", 0, "BOOL")],
		},
		Nd: {
			displayMode: [props.globals.initNode("/instrumentation/efis[0]/nd/display-mode", "NAV", "STRING"), props.globals.initNode("/instrumentation/efis[1]/nd/display-mode", "NAV", "STRING")],
		},
		Mfd: {
			pnlModeNum: [props.globals.initNode("/instrumentation/efis[0]/mfd/pnl_mode-num", 2, "INT"), props.globals.initNode("/instrumentation/efis[1]/mfd/pnl_mode-num", 2, "INT")],
		},
	},
	GPS: {
		altitude: props.globals.getNode("/instrumentation/gps/indicated-altitude-ft"),
		latitude: props.globals.getNode("/instrumentation/gps/indicated-latitude-deg"),
		longitude: props.globals.getNode("/instrumentation/gps/indicated-longitude-deg"),
		trackMag: props.globals.getNode("/instrumentation/gps/indicated-track-magnetic-deg"),
		gs: props.globals.getNode("/instrumentation/gps/indicated-ground-speed-kt"),
	},
	Iesi: {
		lcdOn: props.globals.initNode("/instrumentation/iesi/lcd-on", 0, "BOOL"),
	},
	Mcdu: {
		mcdu1On: props.globals.initNode("/instrumentation/mcdu/mcdu1-on", 0, "BOOL"),
		mcdu2On: props.globals.initNode("/instrumentation/mcdu/mcdu2-on", 0, "BOOL"),
	},
	MKVII: {
		Inputs: {
			Discretes: {
				flap3Override: props.globals.getNode("/instrumentation/mk-viii/inputs/discretes/momentary-flap-3-override"),
			},
		},
	},
	Nav: {
		gsDeflection: props.globals.getNode("/instrumentation/nav[0]/gs-needle-deflection-norm"),
		locDeflection: props.globals.getNode("/instrumentation/nav[0]/heading-needle-deflection-norm"),
	},
	PFD: {
		windDirection: props.globals.getNode("/instrumentation/pfd/wind-direction"),
		windSpeed: props.globals.getNode("/instrumentation/pfd/wind-speed"),
	},
	TCAS: {
		servicable: props.globals.getNode("/instrumentation/tcas/serviceable"),
		Inputs: {
			mode: props.globals.getNode("/instrumentation/tcas/inputs/mode"),
		},
	},
};

var Modes = {
	EcamDuXfr: props.globals.getNode("/modes/ecam-du-xfr"),
};

var Options = {
	eng: props.globals.getNode("/options/eng"),
};

var Orientation = {
	heading: props.globals.getNode("/orientation/heading-deg"),
	pitch: props.globals.getNode("/orientation/pitch-deg"),
	roll: props.globals.getNode("/orientation/roll-deg"),
	yaw: props.globals.getNode("/orientation/yaw-deg"),
};

var Position = {
	altitudeFt: props.globals.getNode("/position/altitude-ft"),
	gearAglFt: props.globals.getNode("/position/gear-agl-ft"),
	latitude: props.globals.getNode("/position/latitude-deg"),
	longitude: props.globals.getNode("/position/longitude-deg"),
};

var Sim = {
	aero: props.globals.getNode("/sim/aero"),
	aircraft: props.globals.getNode("/sim/aircraft"),
	CurrentView: {
		fieldOfView: props.globals.getNode("/sim/current-view/field-of-view", 1),
		headingOffsetDeg: props.globals.getNode("/sim/current-view/heading-offset-deg", 1),
		name: props.globals.getNode("/sim/current-view/name", 1),
		pitchOffsetDeg: props.globals.getNode("/sim/current-view/pitch-offset-deg", 1),
		rollOffsetDeg: props.globals.getNode("/sim/current-view/roll-offset-deg", 1),
		type: props.globals.getNode("/sim/current-view/type", 1),
		viewNumber: props.globals.getNode("/sim/current-view/view-number", 1),
		viewNumberRaw: props.globals.getNode("/sim/current-view/view-number-raw", 1),
		zOffsetDefault: props.globals.getNode("/sim/current-view/z-offset-default", 1),
		xOffsetM: props.globals.getNode("/sim/current-view/x-offset-m", 1),
		yOffsetM: props.globals.getNode("/sim/current-view/y-offset-m", 1),
		zOffsetM: props.globals.getNode("/sim/current-view/z-offset-m", 1),
		zOffsetMaxM: props.globals.getNode("/sim/current-view/z-offset-max-m", 1),
		zOffsetMinM: props.globals.getNode("/sim/current-view/z-offset-min-m", 1),
	},
	fgHome: props.globals.getNode("/sim/fg-home"),
	Input: {
		Selected: {
			engine: [props.globals.getNode("/sim/input/selected/engine[0]", 1),props.globals.getNode("/sim/input/selected/engine[1]", 1)],
		}
	},
	Model: {
		Lights: {
			navLights: props.globals.getNode("/sim/model/lights/nav-lights"),
			noseLights: props.globals.getNode("/sim/model/lights/nose-lights"),
		},
	},
	Multiplay: {
		online: props.globals.getNode("/sim/multiplay/online"),
	},
	pause: props.globals.getNode("/sim/freeze/master"),
	Rendering: {
		Headshake: {
			enabled: props.globals.getNode("/sim/rendering/headshake/enabled"),
		},
		Shaders: {
			skydome: props.globals.getNode("/sim/rendering/shaders/skydome"),
		},
	},
	replayState: props.globals.getNode("/sim/freeze/replay-state"),
	Replay: {
		replayActive: props.globals.getNode("/sim/replay/replay-state"),
	},
	Time: {
		deltaRealtimeSec: props.globals.getNode("/sim/time/delta-realtime-sec"),
		elapsedSec: props.globals.getNode("/sim/time/elapsed-sec"),
		gmtString: props.globals.getNode("/sim/time/gmt-string"),
		Utc: {
			day: props.globals.getNode("/sim/time/utc/day"),
			month: props.globals.getNode("/sim/time/utc/month"),
			year: props.globals.getNode("/sim/time/utc/year"),
		},
	},
	version: props.globals.getNode("/sim/version/flightgear"),
	View: {
		Config: {
			defaultFieldOfViewDeg: props.globals.getNode("/sim/view/config/default-field-of-view-deg", 1),
		},
	},
};

var Systems = {
	Navigation: {
		ADR: {
			Output: {
				overspeed: props.globals.getNode("/systems/navigation/adr/output/overspeed"),
				underspeed: props.globals.getNode("/systems/navigation/adr/output/underspeed"),
			},
		},
	},
	Thrust: {
		engOut: props.globals.getNode("/systems/thrust/eng-out"),
		state: [props.globals.getNode("/systems/thrust/state1"), props.globals.getNode("/systems/thrust/state2")],
	},
};

var Velocities = {
	airspeedKt: props.globals.getNode("/velocities/airspeed-kt"),
	groundspeedKt: props.globals.getNode("/velocities/groundspeed-kt"),
	mach: props.globals.getNode("/velocities/mach"),
};

setprop("/systems/acconfig/property-tree-setup-loaded", 1);
