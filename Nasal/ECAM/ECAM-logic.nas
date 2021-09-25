# A3XX Electronic Centralised Aircraft Monitoring System
# Copyright (c) 2021 Jonathan Redpath (legoboyvdlp)

# props.nas:

var dualFailNode = props.globals.initNode("/ECAM/dual-failure-enabled", 0, "BOOL");
var apWarn       = props.globals.getNode("/it-autoflight/output/ap-warning", 1);
var athrWarn     = props.globals.getNode("/it-autoflight/output/athr-warning", 1);
var emerGen      = props.globals.getNode("/controls/electrical/switches/emer-gen", 1);

var acconfig_weight_kgs = props.globals.getNode("/systems/acconfig/options/weight-kgs", 1);
var state1Node = props.globals.getNode("/engines/engine[0]/state", 1);
var state2Node = props.globals.getNode("/engines/engine[1]/state", 1);
var wing_pb    = props.globals.getNode("/controls/ice-protection/wing", 1);
var apu_bleedSw   = props.globals.getNode("/controls/pneumatics/switches/apu", 1);
var gear       = props.globals.getNode("/gear/gear-pos-norm", 1);
var stallVoice = props.globals.initNode("/sim/sound/warnings/stall-voice", 0, "BOOL");
var engOpt     = props.globals.getNode("/options/eng", 1);

var thrustState = [nil, nil];

# local variables
var transmitFlag1 = 0;
var transmitFlag2 = 0;
var phaseVar3 = nil;
var phaseVar2 = nil;
var phaseVar1 = nil;
var phaseVarMemo = nil;
var phaseVarMemo2 = nil;
var phaseVarMemo3 = nil;
var gear_agl_cur = nil;
var numberMinutes = nil;
var timeNow = nil;
var timer10secIRS = nil;
var altAlertInhibit = nil;
var alt200 = nil;
var alt750 = nil;
var bigThree = nil;
var fltCtlLandAsap = 0;

var altAlertSteady = 0;
var altAlertFlash = 0;
var _SATval = nil;


var ecamConfigTest = props.globals.initNode("/ECAM/to-config-test", 0, "BOOL");

var messages_priority_3 = func {
	phaseVar3 = pts.ECAM.fwcWarningPhase.getValue();
	
	# Stall
	# todo - altn law and emer cancel flipflops page 2440
	if (warningNodes.Logic.stallWarn.getValue()) {
		stall.active = 1;
		stallVoice.setValue(1);
	} else {
		ECAM_controller.warningReset(stall);
		stallVoice.setValue(0);
	}
	
	# FCTL FLAPS NOT ZERO
	if (flap_not_zero.clearFlag == 0 and warningNodes.Logic.flapNotZero.getBoolValue()) {
		flap_not_zero.active = 1;
	} else {
		ECAM_controller.warningReset(flap_not_zero);
	}
	
	if (overspeed.clearFlag == 0 and (phaseVar3 == 1 or (phaseVar3 >= 5 and phaseVar3 <= 7)) and pts.Systems.Navigation.ADR.Output.overspeed.getBoolValue()) {
		overspeed.active = 1;
		if (getprop("/systems/navigation/adr/computation/overspeed-vmo") or getprop("/systems/navigation/adr/computation/overspeed-mmo")) {
			overspeedVMO.active = 1;
		} else {
			ECAM_controller.warningReset(overspeedVMO);
		}
		
		if (getprop("/systems/navigation/adr/computation/overspeed-vle")) {
			overspeedGear.active = 1;
		} else {
			ECAM_controller.warningReset(overspeedGear);
		}
		
		if (getprop("/systems/navigation/adr/computation/overspeed-vfe")) {
			overspeedFlap.active = 1;
			overspeedFlap.msg = "-VFE................" ~ (systems.ADIRS.overspeedVFE.getValue() - 4);
		} else {
			ECAM_controller.warningReset(overspeedFlap);
			overspeedFlap.msg = "-VFE................XXX";
		}
	} else {
		ECAM_controller.warningReset(overspeed);
		ECAM_controller.warningReset(overspeedVMO);
		ECAM_controller.warningReset(overspeedGear);
		ECAM_controller.warningReset(overspeedFlap);
		overspeedFlap.msg = "-VFE................XXX";
	}
	
	# ENG ALL ENGINE FAILURE
	
	if (allEngFail.clearFlag == 0 and dualFailNode.getBoolValue()) {
		allEngFail.active = 1;
		
		if (allEngFailElec.clearFlag == 0 and systems.ELEC.Source.EmerGen.relayPos.getValue() == 0) {
			allEngFailElec.active = 1;
		} else {
			ECAM_controller.warningReset(allEngFailElec);
		}
		
		if (allEngFailSPD1.clearFlag == 0 and allEngFailSPD2.clearFlag == 0 and allEngFailSPD3.clearFlag == 0 and allEngFailSPD4.clearFlag == 0) {
			if (find("LEAP", getprop("/options/engine-name"))) {
				allEngFailSPD2.active = 1;
				ECAM_controller.warningReset(allEngFailSPD1);
				ECAM_controller.warningReset(allEngFailSPD3);
				ECAM_controller.warningReset(allEngFailSPD4);
			} elsif (find("V2527", getprop("/options/engine-name"))) {
				allEngFailSPD3.active = 1;
				ECAM_controller.warningReset(allEngFailSPD1);
				ECAM_controller.warningReset(allEngFailSPD2);
				ECAM_controller.warningReset(allEngFailSPD4);
			} elsif (find("PW11", getprop("/options/engine-name"))) {
				allEngFailSPD1.active = 1;
				ECAM_controller.warningReset(allEngFailSPD2);
				ECAM_controller.warningReset(allEngFailSPD3);
				ECAM_controller.warningReset(allEngFailSPD4);
			} else {
				allEngFailSPD4.active = 1;
				ECAM_controller.warningReset(allEngFailSPD1);
				ECAM_controller.warningReset(allEngFailSPD2);
				ECAM_controller.warningReset(allEngFailSPD3);
			}
		} else {
			ECAM_controller.warningReset(allEngFailSPD1);
			ECAM_controller.warningReset(allEngFailSPD2);
			ECAM_controller.warningReset(allEngFailSPD3);
			ECAM_controller.warningReset(allEngFailSPD4);
		}
		
		if (allEngFailAPU.clearFlag == 0 and !systems.APUNodes.Controls.master.getBoolValue() and systems.ELEC.Switch.genApu.getValue() and !systems.APUNodes.Controls.fire.getValue() and !systems.APU.signals.autoshutdown and !systems.APU.signals.emer and pts.Instrumentation.Altimeter.indicatedFt.getValue() < 22500) {
			allEngFailAPU.active = 1;
		} else {
			ECAM_controller.warningReset(allEngFailAPU);
		}
		
		if (allEngFailLevers.clearFlag == 0 and (systems.FADEC.detent[0].getValue() != 0 or systems.FADEC.detent[1].getValue() != 0)) {
			allEngFailLevers.active = 1;
		} else {
			ECAM_controller.warningReset(allEngFailLevers);
		}
		
		if (allEngFailFAC.clearFlag == 0 and fbw.FBW.Computers.fac1.getBoolValue() == 0) {
			allEngFailFAC.active = 1;
		} else {
			ECAM_controller.warningReset(allEngFailFAC);
		}
		
		if (allEngFailGlide.clearFlag == 0) {
			allEngFailGlide.active = 1;
		} else {
			ECAM_controller.warningReset(allEngFailGlide);
		}
		
		if (allEngFailDiversion.clearFlag == 0) {
			allEngFailDiversion.active = 1;
		} else {
			ECAM_controller.warningReset(allEngFailDiversion);
		}
		
		if (allEngFailProc.clearFlag == 0) {
			allEngFailProc.active = 1;
		} else {
			ECAM_controller.warningReset(allEngFailProc);
		}
	} else {
		ECAM_controller.warningReset(allEngFail);
		ECAM_controller.warningReset(allEngFailElec);
		ECAM_controller.warningReset(allEngFailSPD1);
		ECAM_controller.warningReset(allEngFailSPD2);
		ECAM_controller.warningReset(allEngFailSPD3);
		ECAM_controller.warningReset(allEngFailSPD4);
		ECAM_controller.warningReset(allEngFailAPU);
		ECAM_controller.warningReset(allEngFailLevers);
		ECAM_controller.warningReset(allEngFailFAC);
		ECAM_controller.warningReset(allEngFailGlide);
		ECAM_controller.warningReset(allEngFailDiversion);
		ECAM_controller.warningReset(allEngFailProc);
	}
	
	# ENG ABV IDLE
	if (eng1ThrLvrAbvIdle.clearFlag == 0 and ((phaseVar3 >= 2 and phaseVar3 <= 4) or (phaseVar3 >= 6 and phaseVar3 <= 9)) and warningNodes.Flipflops.eng1ThrLvrAbvIdle.getValue()) { # AND NOT RUNWAY TOO SHORT
		eng1ThrLvrAbvIdle.active = 1;
		if (eng1ThrLvrAbvIdle2.clearFlag == 0) {
			eng1ThrLvrAbvIdle2.active = 1;
		} else {
			ECAM_controller.warningReset(eng1ThrLvrAbvIdle2);
		}
	} else {
		ECAM_controller.warningReset(eng1ThrLvrAbvIdle);
		ECAM_controller.warningReset(eng1ThrLvrAbvIdle2);
	}
	
	if (eng2ThrLvrAbvIdle.clearFlag == 0 and ((phaseVar3 >= 2 and phaseVar3 <= 4) or (phaseVar3 >= 6 and phaseVar3 <= 9)) and warningNodes.Flipflops.eng2ThrLvrAbvIdle.getValue()) { # AND NOT RUNWAY TOO SHORT
		eng2ThrLvrAbvIdle.active = 1;
		if (eng2ThrLvrAbvIdle2.clearFlag == 0) {
			eng2ThrLvrAbvIdle2.active = 1;
		} else {
			ECAM_controller.warningReset(eng2ThrLvrAbvIdle2);
		}
	} else {
		ECAM_controller.warningReset(eng2ThrLvrAbvIdle);
		ECAM_controller.warningReset(eng2ThrLvrAbvIdle2);
	}
	
	# ENG FIRE
	if ((eng1Fire.clearFlag == 0 and systems.eng1FireWarn.getValue() == 1 and phaseVar3 >= 5 and phaseVar3 <= 7) or (eng1FireGnEvac.clearFlag == 0 and systems.eng1FireWarn.getValue() == 1 and (phaseVar3 < 5 or phaseVar3 > 7))) {
		eng1Fire.active = 1;
	} else {
		ECAM_controller.warningReset(eng1Fire);
	}
	
	if ((eng2Fire.clearFlag == 0 and systems.eng2FireWarn.getValue() == 1 and phaseVar3 >= 5 and phaseVar3 <= 7) or (eng2FireGnEvac.clearFlag == 0 and systems.eng2FireWarn.getValue() == 1 and (phaseVar3 < 5 or phaseVar3 > 7))) {
		eng2Fire.active = 1;
	} else {
		ECAM_controller.warningReset(eng2Fire);
	}
	
	if (apuFire.clearFlag == 0 and systems.apuFireWarn.getValue() == 1) {
		apuFire.active = 1;
	} else {
		ECAM_controller.warningReset(apuFire);
	}
	
	if (eng1Fire.active == 1) {
		if (phaseVar3 >= 5 and phaseVar3 <= 7) {
			if (eng1FireFllever.clearFlag == 0 and systems.FADEC.detent[0].getValue() != 0) {
				eng1FireFllever.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireFllever);
			}
			
			if (eng1FireFlmaster.clearFlag == 0 and pts.Controls.Engines.Engine.cutoffSw[0].getValue() == 0) {
				eng1FireFlmaster.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireFlmaster);
			}
			
			if (eng1FireFlPB.clearFlag == 0 and systems.fireButtons[0].getValue() == 0) {
				eng1FireFlPB.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireFlPB);
			}
			
			if (systems.eng1AgentTimer.getValue() != 0 and systems.eng1AgentTimer.getValue() != 99) {
				eng1FireFlAgent1Timer.msg = " -AGENT AFT " ~ systems.eng1AgentTimer.getValue() ~ " S...DISCH";
			}
			
			if (eng1FireFlAgent1.clearFlag == 0 and systems.fireButtons[0].getValue() == 1 and !systems.extinguisherBottles.vector[0].lightProp.getValue() and systems.eng1AgentTimer.getValue() != 0 and systems.eng1AgentTimer.getValue() != 99) {
				eng1FireFlAgent1Timer.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireFlAgent1Timer);
			}
			
			if (eng1FireFlAgent1.clearFlag == 0 and !systems.extinguisherBottles.vector[0].lightProp.getValue() and (systems.eng1AgentTimer.getValue() == 0 or systems.eng1AgentTimer.getValue() == 99)) {
				eng1FireFlAgent1.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireFlAgent1);
			}
			
			if (eng1FireFlATC.clearFlag == 0) {
				eng1FireFlATC.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireFlATC);
			}
			
			if (systems.eng1Agent2Timer.getValue() != 0 and systems.eng1Agent2Timer.getValue() != 99) {
				eng1FireFl30Sec.msg = "•IF FIRE AFTER " ~ systems.eng1Agent2Timer.getValue() ~ " S:";
			}
			
			if (eng1FireFlAgent2.clearFlag == 0 and systems.extinguisherBottles.vector[0].lightProp.getValue() and !systems.extinguisherBottles.vector[1].lightProp.getValue() and systems.eng1Agent2Timer.getValue() > 0) {
				eng1FireFl30Sec.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireFl30Sec);
			}
			
			if (eng1FireFlAgent2.clearFlag == 0 and systems.extinguisherBottles.vector[0].lightProp.getValue() and !systems.extinguisherBottles.vector[1].lightProp.getValue()) {
				eng1FireFlAgent2.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireFlAgent2);
			}
		} else {
			ECAM_controller.warningReset(eng1FireFllever);
			ECAM_controller.warningReset(eng1FireFlmaster);
			ECAM_controller.warningReset(eng1FireFlPB);
			ECAM_controller.warningReset(eng1FireFlAgent1);
			ECAM_controller.warningReset(eng1FireFlATC);
			ECAM_controller.warningReset(eng1FireFl30Sec);
			ECAM_controller.warningReset(eng1FireFlAgent2);
		}
		
		if (phaseVar3 < 5 or phaseVar3 > 7) {
			if (eng1FireGnlever.clearFlag == 0 and systems.FADEC.detent[0].getValue() != 0 and systems.FADEC.detent[1].getValue() != 0) {
				eng1FireGnlever.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireGnlever);
			}
			
			if (eng1FireGnparkbrk.clearFlag == 0 and pts.Controls.Gear.parkingBrake.getValue() == 0) { 
				eng1FireGnstopped.active = 1;
				eng1FireGnparkbrk.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireGnstopped);
				ECAM_controller.warningReset(eng1FireGnparkbrk);
			}
			
			if (eng1FireGnATC.clearFlag == 0) {
				eng1FireGnATC.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireGnATC);
			}
			
			if (eng1FireGncrew.clearFlag == 0) {
				eng1FireGncrew.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireGncrew);
			}
			
			if (eng1FireGnmaster.clearFlag == 0 and pts.Controls.Engines.Engine.cutoffSw[0].getValue() == 0) {
				eng1FireGnmaster.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireGnmaster);
			}
			
			if (eng1FireGnPB.clearFlag == 0 and systems.fireButtons[0].getValue() == 0) {
				eng1FireGnPB.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireGnPB);
			}
			
			if (eng1FireGnAgent1.clearFlag == 0 and !systems.extinguisherBottles.vector[0].lightProp.getValue()) {
				eng1FireGnAgent1.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireGnAgent1);
			}
			
			if (eng1FireGnAgent2.clearFlag == 0 and !systems.extinguisherBottles.vector[1].lightProp.getValue()) {
				eng1FireGnAgent2.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireGnAgent2);
			}
			
			if (eng1FireGnEvac.clearFlag == 0) {
				eng1FireGnEvac.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FireGnEvac);
			}
		} else {
			ECAM_controller.warningReset(eng1FireGnlever);
			ECAM_controller.warningReset(eng1FireGnstopped);
			ECAM_controller.warningReset(eng1FireGnparkbrk);
			ECAM_controller.warningReset(eng1FireGnATC);
			ECAM_controller.warningReset(eng1FireGncrew);
			ECAM_controller.warningReset(eng1FireGnmaster);
			ECAM_controller.warningReset(eng1FireGnPB);
			ECAM_controller.warningReset(eng1FireGnAgent1);
			ECAM_controller.warningReset(eng1FireGnAgent2);
			ECAM_controller.warningReset(eng1FireGnEvac);
		}
	} else {
		ECAM_controller.warningReset(eng1FireFllever);
		ECAM_controller.warningReset(eng1FireFlmaster);
		ECAM_controller.warningReset(eng1FireFlPB);
		ECAM_controller.warningReset(eng1FireFlAgent1);
		ECAM_controller.warningReset(eng1FireFlATC);
		ECAM_controller.warningReset(eng1FireFl30Sec);
		ECAM_controller.warningReset(eng1FireFlAgent2);
		ECAM_controller.warningReset(eng1FireGnlever);
		ECAM_controller.warningReset(eng1FireGnstopped);
		ECAM_controller.warningReset(eng1FireGnparkbrk);
		ECAM_controller.warningReset(eng1FireGnATC);
		ECAM_controller.warningReset(eng1FireGncrew);
		ECAM_controller.warningReset(eng1FireGnmaster);
		ECAM_controller.warningReset(eng1FireGnPB);
		ECAM_controller.warningReset(eng1FireGnAgent1);
		ECAM_controller.warningReset(eng1FireGnAgent2);
		ECAM_controller.warningReset(eng1FireGnEvac);
	}
	
	if (eng2Fire.active == 1) {
		if (phaseVar3 >= 5 and phaseVar3 <= 7) {
			if (eng2FireFllever.clearFlag == 0 and systems.FADEC.detent[1].getValue() != 0) {
				eng2FireFllever.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireFllever);
			}
			
			if (eng2FireFlmaster.clearFlag == 0 and pts.Controls.Engines.Engine.cutoffSw[1].getValue() == 0) {
				eng2FireFlmaster.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireFlmaster);
			}
			
			if (eng2FireFlPB.clearFlag == 0 and systems.fireButtons[1].getValue() == 0) {
				eng2FireFlPB.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireFlPB);
			}
			
			if (systems.eng2AgentTimer.getValue() != 0 and systems.eng2AgentTimer.getValue() != 99) {
				eng2FireFlAgent1Timer.msg = " -AGENT AFT " ~ systems.eng2AgentTimer.getValue() ~ " S...DISCH";
			}
			
			if (eng2FireFlAgent1.clearFlag == 0 and systems.fireButtons[1].getValue() == 1 and !systems.extinguisherBottles.vector[2].lightProp.getValue() and getprop("/systems/fire/engine2agent1-timer") != 0 and systems.eng2AgentTimer.getValue() != 99) {
				eng2FireFlAgent1Timer.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireFlAgent1Timer);
			}
			
			if (eng2FireFlAgent1.clearFlag == 0 and !systems.extinguisherBottles.vector[2].lightProp.getValue() and (systems.eng2AgentTimer.getValue() == 0 or systems.eng2AgentTimer.getValue() == 99)) {
				eng2FireFlAgent1.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireFlAgent1);
			}
			
			if (eng2FireFlATC.clearFlag == 0) {
				eng2FireFlATC.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireFlATC);
			}
			
			if (systems.eng2Agent2Timer.getValue() != 0 and systems.eng2Agent2Timer.getValue() != 99) {
				eng2FireFl30Sec.msg = "•IF FIRE AFTER " ~ systems.eng2Agent2Timer.getValue() ~ " S:";
			}
			
			if (eng2FireFlAgent2.clearFlag == 0 and systems.extinguisherBottles.vector[2].lightProp.getValue() and !systems.extinguisherBottles.vector[4].lightProp.getValue() and systems.eng2Agent2Timer.getValue() > 0) {
				eng2FireFl30Sec.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireFl30Sec);
			}
			
			if (eng2FireFlAgent2.clearFlag == 0 and systems.extinguisherBottles.vector[2].lightProp.getValue() and !systems.extinguisherBottles.vector[4].lightProp.getValue()) {
				eng2FireFlAgent2.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireFlAgent2);
			}
		} else {
			ECAM_controller.warningReset(eng2FireFllever);
			ECAM_controller.warningReset(eng2FireFlmaster);
			ECAM_controller.warningReset(eng2FireFlPB);
			ECAM_controller.warningReset(eng2FireFlAgent1);
			ECAM_controller.warningReset(eng2FireFlATC);
			ECAM_controller.warningReset(eng2FireFl30Sec);
			ECAM_controller.warningReset(eng2FireFlAgent2);
		}
		
		if (phaseVar3 < 5 or phaseVar3 > 7) {
			if (eng2FireGnlever.clearFlag == 0 and systems.FADEC.detent[0].getValue() != 0 and systems.FADEC.detent[1].getValue() != 0) {
				eng2FireGnlever.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireGnlever);
			}
			
			if (eng2FireGnparkbrk.clearFlag == 0 and pts.Controls.Gear.parkingBrake.getValue() == 0) { 
				eng2FireGnstopped.active = 1;
				eng2FireGnparkbrk.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireGnstopped);
				ECAM_controller.warningReset(eng2FireGnparkbrk);
			}
			
			if (eng2FireGnATC.clearFlag == 0) {
				eng2FireGnATC.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireGnATC);
			}
			
			if (eng2FireGncrew.clearFlag == 0) {
				eng2FireGncrew.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireGncrew);
			}
			
			if (eng2FireGnmaster.clearFlag == 0 and pts.Controls.Engines.Engine.cutoffSw[1].getValue() == 0) {
				eng2FireGnmaster.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireGnmaster);
			}
			
			if (eng2FireGnPB.clearFlag == 0 and systems.fireButtons[1].getValue() == 0) {
				eng2FireGnPB.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireGnPB);
			}
			
			if (eng2FireGnAgent1.clearFlag == 0 and !systems.extinguisherBottles.vector[2].lightProp.getValue()) {
				eng2FireGnAgent1.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireGnAgent1);
			}
			
			if (eng2FireGnAgent2.clearFlag == 0 and !systems.extinguisherBottles.vector[4].lightProp.getValue()) {
				eng2FireGnAgent2.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireGnAgent2);
			}
			
			if (eng2FireGnEvac.clearFlag == 0) {
				eng2FireGnEvac.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FireGnEvac);
			}
		} else {
			ECAM_controller.warningReset(eng2FireGnlever);
			ECAM_controller.warningReset(eng2FireGnstopped);
			ECAM_controller.warningReset(eng2FireGnparkbrk);
			ECAM_controller.warningReset(eng2FireGnATC);
			ECAM_controller.warningReset(eng2FireGncrew);
			ECAM_controller.warningReset(eng2FireGnmaster);
			ECAM_controller.warningReset(eng2FireGnPB);
			ECAM_controller.warningReset(eng2FireGnAgent1);
			ECAM_controller.warningReset(eng2FireGnAgent2);
			ECAM_controller.warningReset(eng2FireGnEvac);
		}
	} else {
		ECAM_controller.warningReset(eng2FireFllever);
		ECAM_controller.warningReset(eng2FireFlmaster);
		ECAM_controller.warningReset(eng2FireFlPB);
		ECAM_controller.warningReset(eng2FireFlAgent1);
		ECAM_controller.warningReset(eng2FireFlATC);
		ECAM_controller.warningReset(eng2FireFl30Sec);
		ECAM_controller.warningReset(eng2FireFlAgent2);
		ECAM_controller.warningReset(eng2FireGnlever);
		ECAM_controller.warningReset(eng2FireGnstopped);
		ECAM_controller.warningReset(eng2FireGnparkbrk);
		ECAM_controller.warningReset(eng2FireGnATC);
		ECAM_controller.warningReset(eng2FireGncrew);
		ECAM_controller.warningReset(eng2FireGnmaster);
		ECAM_controller.warningReset(eng2FireGnPB);
		ECAM_controller.warningReset(eng2FireGnAgent1);
		ECAM_controller.warningReset(eng2FireGnAgent2);
		ECAM_controller.warningReset(eng2FireGnEvac);
	}
	
	# APU Fire
	if (apuFire.active == 1) {
		if (apuFirePB.clearFlag == 0 and !systems.APUNodes.Controls.fire.getValue()) {
			apuFirePB.active = 1;
		} else {
			ECAM_controller.warningReset(apuFirePB);
		}
		
		if (systems.apuAgentTimer.getValue() != 0 and systems.apuAgentTimer.getValue() != 99) {
			apuFireAgentTimer.msg = " -AGENT AFT " ~ systems.apuAgentTimer.getValue() ~ " S...DISCH";
		}
		
		if (apuFireAgent.clearFlag == 0 and systems.APUNodes.Controls.fire.getValue() and !systems.extinguisherBottles.vector[4].lightProp.getValue() and systems.apuAgentTimer.getValue() != 0) {
			apuFireAgentTimer.active = 1;
		} else {
			ECAM_controller.warningReset(apuFireAgentTimer);
		}
		
		if (apuFireAgent.clearFlag == 0 and systems.APUNodes.Controls.fire.getValue() and !systems.extinguisherBottles.vector[4].lightProp.getValue() and systems.apuAgentTimer.getValue() == 0) {
			apuFireAgent.active = 1;
		} else {
			ECAM_controller.warningReset(apuFireAgent);
		}
		
		if (apuFireMaster.clearFlag == 0 and systems.APUNodes.Controls.master.getBoolValue()) {
			apuFireMaster.active = 1;
		} else {
			ECAM_controller.warningReset(apuFireMaster);
		}
	} else {
		ECAM_controller.warningReset(apuFirePB);
		ECAM_controller.warningReset(apuFireAgentTimer);
		ECAM_controller.warningReset(apuFireAgent);
		ECAM_controller.warningReset(apuFireMaster);
	}
	
	if ((ecamConfigTest.getValue() and (phaseVar3 == 1 or phaseVar3 == 2 or phaseVar3 == 9)) or phaseVar3 == 3 or phaseVar3 == 4) {
		takeoffConfig = 1;
	} else {
		takeoffConfig = 0;
	}
	
	if (slats_config.clearFlag == 0 and (warningNodes.Logic.slatsConfig.getBoolValue() or (takeoffConfig and warningNodes.Logic.slatsConfig2.getBoolValue()))) {
		slats_config.active = 1;
		slats_config_1.active = 1;
	} else {
		ECAM_controller.warningReset(slats_config);
		ECAM_controller.warningReset(slats_config_1);
	}
	
	if (flaps_config.clearFlag == 0 and (warningNodes.Logic.flapsConfig.getBoolValue() or (takeoffConfig and warningNodes.Logic.flapsConfig2.getBoolValue()))) {
		flaps_config.active = 1;
		flaps_config_1.active = 1;
	} else {
		ECAM_controller.warningReset(flaps_config);
		ECAM_controller.warningReset(flaps_config_1);
	}
	
	if (spd_brk_config.clearFlag == 0 and (warningNodes.Logic.spdBrkConfig.getBoolValue() or (takeoffConfig and warningNodes.Logic.spdBrkConfig2.getBoolValue()))) {
		spd_brk_config.active = 1;
		spd_brk_config_1.active = 1;
	} else {
		ECAM_controller.warningReset(spd_brk_config);
		ECAM_controller.warningReset(spd_brk_config_1);
	}
	
	if (pitch_trim_config.clearFlag == 0 and (warningNodes.Logic.pitchTrimConfig.getBoolValue() or (takeoffConfig and warningNodes.Logic.pitchTrimConfig2.getBoolValue()))) {
		pitch_trim_config.active = 1;
		pitch_trim_config_1.active = 1;
	} else {
		ECAM_controller.warningReset(pitch_trim_config);
		ECAM_controller.warningReset(pitch_trim_config_1);
	}
	
	if (rud_trim_config.clearFlag == 0 and (warningNodes.Logic.rudTrimConfig.getBoolValue() or (takeoffConfig and warningNodes.Logic.rudTrimConfig2.getBoolValue()))) {
		rud_trim_config.active = 1;
		rud_trim_config_1.active = 1;
	} else {
		ECAM_controller.warningReset(rud_trim_config);
		ECAM_controller.warningReset(rud_trim_config_1);
	}
	
	if (park_brk_config.clearFlag == 0 and warningNodes.Logic.parkBrkConfig.getValue() and phaseVar3 >= 2 and phaseVar3 <= 3) {
		park_brk_config.active = 1;
	} else {
		ECAM_controller.warningReset(park_brk_config);
	}
	
	if (lrElevFault.clearFlag == 0 and warningNodes.Timers.LRElevFault.getValue()) {
		lrElevFault.active = 1;
		if (lrElevFaultSpeed.clearFlag == 0) {
			lrElevFaultSpeed.active = 1;
		} else {
			ECAM_controller.warningReset(lrElevFaultSpeed);
		}
		if (lrElevFaultTrim.clearFlag == 0) {
			lrElevFaultTrim.active = 1;
		} else {
			ECAM_controller.warningReset(lrElevFaultTrim);
		}
		if (lrElevFaultSpdBrk.clearFlag == 0) {
			lrElevFaultSpdBrk.active = 1;
		} else {
			ECAM_controller.warningReset(lrElevFaultSpdBrk);
		}
	} else {
		ECAM_controller.warningReset(lrElevFault);
		ECAM_controller.warningReset(lrElevFaultSpeed);
		ECAM_controller.warningReset(lrElevFaultTrim);
		ECAM_controller.warningReset(lrElevFaultSpdBrk);
	}
	
	if (gearNotDown.clearFlag == 0 and (warningNodes.Logic.gearNotDown1.getBoolValue() or warningNodes.Logic.gearNotDown2.getBoolValue()) and phaseVar3 != 3 and phaseVar3 != 4 and phaseVar3 != 5) {
		if (!gearNotDown.active) {
			gearWarnLight.setValue(1);
		}
		gearNotDown.active = 1;
	} else {
		if (gearNotDown.active) {
			gearWarnLight.setValue(0);
		}
		ECAM_controller.warningReset(gearNotDown);
	}
	
	if (gearNotDownLocked.clearFlag == 0 and warningNodes.Logic.gearNotDownLocked.getBoolValue() and phaseVar3 != 3 and phaseVar3 != 4 and phaseVar3 != 5 and phaseVar3 != 8) {
		gearNotDownLocked.active = 1;
		
		if (gearNotDownLockedRec.clearFlag == 0 and warningNodes.Logic.gearNotDownLockedFlipflop.getValue() == 0) {
			gearNotDownLockedRec.active = 1;
			gearNotDownLockedWork.active = 1;
		} else {
			ECAM_controller.warningReset(gearNotDownLockedRec);
			ECAM_controller.warningReset(gearNotDownLockedWork);
		}
		
		if (gearNotDownLocked120.clearFlag == 0) {
			gearNotDownLocked120.active = 1;
		} else {
			ECAM_controller.warningReset(gearNotDownLocked120);
		}
		
		if (gearNotDownLockedGrav.clearFlag == 0) {
			gearNotDownLockedGrav.active = 1;
		} else {
			ECAM_controller.warningReset(gearNotDownLockedGrav);
		}
	} else {
		ECAM_controller.warningReset(gearNotDownLocked);
		ECAM_controller.warningReset(gearNotDownLockedRec);
		ECAM_controller.warningReset(gearNotDownLockedWork);
		ECAM_controller.warningReset(gearNotDownLocked120);
		ECAM_controller.warningReset(gearNotDownLockedGrav);
	}
	
	# AUTOFLT
	if ((ap_offw.clearFlag == 0) and apWarn.getValue() == 2) {
		ap_offw.active = 1;
	} else {
		ECAM_controller.warningReset(ap_offw);
	}
	
	# C-Chord
	if (warningNodes.Logic.altitudeAlert.getValue()) {
		if (!getprop("/sim/sound/warnings/cchord-inhibit")) {
			aural[4].setValue(1);
		} else {
			aural[4].setValue(0);
		}
	} else {
		aural[4].setValue(0);
		setprop("/sim/sound/warnings/cchord-inhibit", 0);
	}
	
	if (warningNodes.Logic.altitudeAlertSteady.getValue()) {
		altAlertSteady = 1;
	} else {
		altAlertSteady = 0;
	}
	
	if (warningNodes.Logic.altitudeAlertFlash.getValue()) {
		altAlertFlash = 1;
	} else {
		altAlertFlash = 0;
	}
	
	if (cargoSmokeFwd.clearFlag == 0 and systems.fwdCargoFireWarn.getBoolValue() and (phaseVar3 <= 3 or phaseVar3 >= 9 or phaseVar3 == 6)) {
		cargoSmokeFwd.active = 1;
		
		if (cargoSmokeFwdFans.clearFlag == 0 and systems.PNEU.Switch.cabinFans.getValue()) {
			cargoSmokeFwdFans.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeFwdFans);
		}
		
		if (cargoSmokeFwdGrdClsd.clearFlag == 0 and (phaseVar3 == 1 or phaseVar3 == 10)) {
			cargoSmokeFwdGrdClsd.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeFwdGrdClsd);
		}
		
		if (cargoSmokeFwdAgent.clearFlag == 0 and !systems.cargoExtinguisherBottles.vector[0].lightProp.getValue()) {
			cargoSmokeFwdAgent.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeFwdAgent);
		}
		
		if (FWC.Timer.gnd.getValue() == 0) {
			cargoSmokeFwdGrd.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeFwdGrd);
		}
		
		if (cargoSmokeFwdDoors.clearFlag == 0) {
			cargoSmokeFwdDoors.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeFwdDoors);
		}
		
		if (cargoSmokeFwdDisemb.clearFlag == 0) {
			cargoSmokeFwdDisemb.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeFwdDisemb);
		}
	} else {
		ECAM_controller.warningReset(cargoSmokeFwd);
		ECAM_controller.warningReset(cargoSmokeFwdFans);
		ECAM_controller.warningReset(cargoSmokeFwdGrdClsd);
		ECAM_controller.warningReset(cargoSmokeFwdAgent);
		ECAM_controller.warningReset(cargoSmokeFwdGrd);
		ECAM_controller.warningReset(cargoSmokeFwdDoors);
		ECAM_controller.warningReset(cargoSmokeFwdDisemb);
		systems.cargoTestBtnOff.setBoolValue(0);
	}
	
	if (cargoSmokeAft.clearFlag == 0 and systems.aftCargoFireWarn.getBoolValue() and (phaseVar3 <= 3 or phaseVar3 >= 9 or phaseVar3 == 6)) {
		cargoSmokeAft.active = 1;
		
		if (cargoSmokeAftFans.clearFlag == 0 and systems.PNEU.Switch.cabinFans.getValue()) {
			cargoSmokeAftFans.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeAftFans);
		}
		
		if (cargoSmokeAftGrdClsd.clearFlag == 0 and (phaseVar3 == 1 or phaseVar3 == 10)) {
			cargoSmokeAftGrdClsd.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeAftGrdClsd);
		}
		
		if (cargoSmokeAftAgent.clearFlag == 0 and !systems.cargoExtinguisherBottles.vector[1].lightProp.getValue()) {
			cargoSmokeAftAgent.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeAftAgent);
		}
		
		if (FWC.Timer.gnd.getValue() == 0) {
			cargoSmokeAftGrd.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeAftGrd);
		}
		
		if (cargoSmokeAftDoors.clearFlag == 0) {
			cargoSmokeAftDoors.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeAftDoors);
		}
		
		if (cargoSmokeAftDisemb.clearFlag == 0) {
			cargoSmokeAftDisemb.active = 1;
		} else {
			ECAM_controller.warningReset(cargoSmokeAftDisemb);
		}
	} else {
		ECAM_controller.warningReset(cargoSmokeAft);
		ECAM_controller.warningReset(cargoSmokeAftFans);
		ECAM_controller.warningReset(cargoSmokeAftGrdClsd);
		ECAM_controller.warningReset(cargoSmokeAftAgent);
		ECAM_controller.warningReset(cargoSmokeAftGrd);
		ECAM_controller.warningReset(cargoSmokeAftDoors);
		ECAM_controller.warningReset(cargoSmokeAftDisemb);
		systems.cargoTestBtnOff.setBoolValue(0);
	}
	
	if (lavatorySmoke.clearFlag == 0 and systems.lavatoryFireWarn.getValue() and phaseVar3 != 4 and phaseVar3 != 5 and phaseVar3 != 7 and phaseVar3 != 8) {
		lavatorySmoke.active = 1;
		lavatorySmokeComm.active = 1;
	} else {
		ECAM_controller.warningReset(lavatorySmoke);
		ECAM_controller.warningReset(lavatorySmokeComm);
	}
	
	# ESS on BAT
	# NEW EMER ELEC CONFIG
	if (essBusOnBat.clearFlag == 0 and warningNodes.Timers.staticInverter.getValue() == 1 and phaseVar3 >= 5 and phaseVar3 <= 7) {
		essBusOnBat.active = 1;
		if (essBusOnBatMinSpeed.clearFlag == 0 and systems.HYD.Rat.position.getValue() != 0) {
			essBusOnBatMinSpeed.active = 1;
		} else {
			ECAM_controller.warningReset(essBusOnBatMinSpeed);
		}
	} else {
		ECAM_controller.warningReset(essBusOnBat);
		ECAM_controller.warningReset(essBusOnBatMinSpeed);
	}
	
	# EMER CONFIG
	if (systems.ELEC.EmerElec.getValue() and !dualFailNode.getBoolValue() and phaseVar3 != 4 and phaseVar3 != 8 and emerconfig.clearFlag == 0 and !pts.Acconfig.running.getBoolValue()) {
		emerconfig.active = 1;
		
		if (systems.HYD.Rat.position.getValue() != 0 and emerconfigMinRat.clearFlag == 0 and FWC.Timer.gnd.getValue() == 0) {
			emerconfigMinRat.active = 1;
		} else {
			ECAM_controller.warningReset(emerconfigMinRat);
		}
		
		if ((!getprop("/systems/electrical/some-electric-thingie/generator-1-reset") or !getprop("/systems/electrical/some-electric-thingie/generator-2-reset")) and emerconfigGen.clearFlag == 0) {
			emerconfigGen.active = 1; # EGEN12R TRUE
		} else {
			ECAM_controller.warningReset(emerconfigGen);
		}
		
		if ((!getprop("/systems/electrical/some-electric-thingie/generator-1-reset-bustie") or !getprop("/systems/electrical/some-electric-thingie/generator-2-reset-bustie")) and emerconfigGen2.clearFlag == 0) {
			emerconfigGen2.active = 1;
			if (systems.ELEC.Switch.busTie.getBoolValue()) {
				emerconfigBusTie.active = 1;
			} else {
				ECAM_controller.warningReset(emerconfigBusTie);
			}
			emerconfigGen3.active = 1; #  EGENRESET TRUE
		} else {
			ECAM_controller.warningReset(emerconfigGen2);
			ECAM_controller.warningReset(emerconfigBusTie);
			ECAM_controller.warningReset(emerconfigGen3);
		}
		
		if (systems.ELEC.Source.EmerGen.relayPos.getValue() == 0 and emerconfigManOn.clearFlag == 0) {
			emerconfigManOn.active = 1;
		} else {
			ECAM_controller.warningReset(emerconfigManOn);
		}
		
		if (pts.Controls.Engines.startSw.getValue() != 2 and emerconfigEngMode.clearFlag == 0) {
			emerconfigEngMode.active = 1;
		} else {
			ECAM_controller.warningReset(emerconfigEngMode);
		}
		
		if (emerconfigRadio.clearFlag == 0) {
			emerconfigRadio.active = 1;
		} else {
			ECAM_controller.warningReset(emerconfigRadio);
		}
		
		if (FWC.Timer.gnd.getValue() == 0) {
			if (emerconfigFuelG.clearFlag == 0) {
				emerconfigFuelG.active = 1;
			} else {
				ECAM_controller.warningReset(emerconfigFuelG);
			}
			
			if (emerconfigFuelG2.clearFlag == 0) {
				emerconfigFuelG2.active = 1;
			} else {
				ECAM_controller.warningReset(emerconfigFuelG2);
			}
			
			if (fbw.FBW.Computers.fac1.getBoolValue() == 0 and emerconfigFAC.clearFlag == 0) {
				emerconfigFAC.active = 1;
			} else {
				ECAM_controller.warningReset(emerconfigFAC);
			}
		} else {
			ECAM_controller.warningReset(emerconfigFuelG);
			ECAM_controller.warningReset(emerconfigFuelG2);
			ECAM_controller.warningReset(emerconfigFAC);
		}
		
		if (!systems.ELEC.Switch.busTie.getBoolValue() and emerconfigBusTie2.clearFlag == 0) {
			emerconfigBusTie2.active = 1;
		} else {
			ECAM_controller.warningReset(emerconfigBusTie2);
		}
		
		if (FWC.Timer.gnd.getValue() == 0) {
			if (emerconfigAPU.clearFlag == 0) {
				emerconfigAPU.active = 1;
			} else {
				ECAM_controller.warningReset(emerconfigAPU);
			}
			
			if (emerconfigVent.clearFlag == 0) {
				emerconfigVent.active = 1;
			} else {
				ECAM_controller.warningReset(emerconfigVent);
			}
		} else {
			ECAM_controller.warningReset(emerconfigAPU);
			ECAM_controller.warningReset(emerconfigVent);
		}
		
		if (emerconfigFuelIN.clearFlag == 0 and warningNodes.Logic.dc2FuelConsumptionIncreased.getValue()) {
			emerconfigFuelIN.active = 1;
		} else {
			ECAM_controller.warningReset(emerconfigFuelIN);
		}
		
		if (emerconfigFMSPRD.clearFlag == 0 and warningNodes.Logic.dc2FMSPredictions.getValue()) {
			emerconfigFMSPRD.active = 1;
		} else {
			ECAM_controller.warningReset(emerconfigFMSPRD);
		}
	} else {
		ECAM_controller.warningReset(emerconfig);
		ECAM_controller.warningReset(emerconfigMinRat);
		ECAM_controller.warningReset(emerconfigGen);
		ECAM_controller.warningReset(emerconfigGen2);
		ECAM_controller.warningReset(emerconfigBusTie);
		ECAM_controller.warningReset(emerconfigGen3);
		ECAM_controller.warningReset(emerconfigManOn);
		ECAM_controller.warningReset(emerconfigEngMode);
		ECAM_controller.warningReset(emerconfigRadio);
		ECAM_controller.warningReset(emerconfigFuelG);
		ECAM_controller.warningReset(emerconfigFuelG2);
		ECAM_controller.warningReset(emerconfigFAC);
		ECAM_controller.warningReset(emerconfigBusTie2);
		ECAM_controller.warningReset(emerconfigAPU);
		ECAM_controller.warningReset(emerconfigVent);
		ECAM_controller.warningReset(emerconfigFuelIN);
		ECAM_controller.warningReset(emerconfigFMSPRD);
	}
	
	if (hydBYloPr.clearFlag == 0 and warningNodes.Logic.blueYellow.getValue()) {
		hydBYloPr.active = 1;
		if (hydBYloPrRat.clearFlag == 0 and systems.HYD.Rat.position.getValue() != 0) {
			hydBYloPrRat.active = 1;
		} else {
			ECAM_controller.warningReset(hydBYloPrRat);
		}
		
		if (hydBYloPrYElec.clearFlag == 0 and !systems.HYD.Pump.yellowElec.getValue() and systems.ELEC.Bus.ac2.getValue() >= 110 and systems.HYD.Qty.yellow.getValue() >= 3.5) { 
			hydBYloPrYElec.active = 1;
		} else {
			ECAM_controller.warningReset(hydBYloPrYElec);
		}
		
		if (hydBYloPrRatOn.clearFlag == 0 and systems.HYD.Rat.position.getValue() == 0 and systems.HYD.Qty.blue.getValue() >= 2.4) {
			hydBYloPrRatOn.active = 1;
		} else {
			ECAM_controller.warningReset(hydBYloPrRatOn);
		}
		
		if (hydBYloPrBElec.clearFlag == 0 and systems.HYD.Switch.blueElec.getValue()) {
			hydBYloPrBElec.active = 1;
		} else {
			ECAM_controller.warningReset(hydBYloPrBElec);
		}
		
		if (hydBYloPrYEng.clearFlag == 0 and systems.HYD.Switch.yellowEDP.getValue()) {
			hydBYloPrYEng.active = 1;
		} else {
			ECAM_controller.warningReset(hydBYloPrYEng);
		}
		
		if (hydBYloPrMaxSpd.clearFlag == 0) {
			hydBYloPrMaxSpd.active = 1;
		} else {
			ECAM_controller.warningReset(hydBYloPrMaxSpd);
		}
		
		if (hydBYloPrMnvrCare.clearFlag == 0) {
			hydBYloPrMnvrCare.active = 1;
		} else {
			ECAM_controller.warningReset(hydBYloPrMnvrCare);
		}
		
		if (hydBYloPrGaPitch.clearFlag == 0) {
			hydBYloPrGaPitch.active = 1;
		} else {
			ECAM_controller.warningReset(hydBYloPrGaPitch);
		}
		
		if (hydBYloPrFuelCnsmpt.clearFlag == 0 and warningNodes.Logic.blueYellowFuel.getValue()) {
			hydBYloPrFuelCnsmpt.active = 1;
		} else {
			ECAM_controller.warningReset(hydBYloPrFuelCnsmpt);
		}
		
		if (hydBYloPrFmsPredict.clearFlag == 0 and warningNodes.Logic.blueYellowFuel.getValue()) {
			hydBYloPrFmsPredict.active = 1;
		} else {
			ECAM_controller.warningReset(hydBYloPrFmsPredict);
		}
	} else {
		ECAM_controller.warningReset(hydBYloPr);
		ECAM_controller.warningReset(hydBYloPrRat);
		ECAM_controller.warningReset(hydBYloPrYElec);
		ECAM_controller.warningReset(hydBYloPrRatOn);
		ECAM_controller.warningReset(hydBYloPrBElec);
		ECAM_controller.warningReset(hydBYloPrYEng);
		ECAM_controller.warningReset(hydBYloPrMaxSpd);
		ECAM_controller.warningReset(hydBYloPrMnvrCare);
		ECAM_controller.warningReset(hydBYloPrGaPitch);
		ECAM_controller.warningReset(hydBYloPrFuelCnsmpt);
		ECAM_controller.warningReset(hydBYloPrFmsPredict);
	}
	
	if (hydGBloPr.clearFlag == 0 and warningNodes.Logic.blueGreen.getValue()) {
		hydGBloPr.active = 1;
		if (hydGBloPrRat.clearFlag == 0 and systems.HYD.Rat.position.getValue() != 0) {
			hydGBloPrRat.active = 1;
		} else {
			ECAM_controller.warningReset(hydGBloPrRat);
		}
		
		if (hydGBloPrRatOn.clearFlag == 0 and systems.HYD.Rat.position.getValue() == 0 and systems.HYD.Qty.blue.getValue() >= 2.4) {
			hydGBloPrRatOn.active = 1;
		} else {
			ECAM_controller.warningReset(hydGBloPrRatOn);
		}
		
		if (hydGBloPrBElec.clearFlag == 0 and systems.HYD.Switch.blueElec.getValue()) {
			hydGBloPrBElec.active = 1;
		} else {
			ECAM_controller.warningReset(hydGBloPrBElec);
		}
		
		if (hydGBloPrGEng.clearFlag == 0 and systems.HYD.Switch.greenEDP.getValue()) {
			hydGBloPrGEng.active = 1;
		} else {
			ECAM_controller.warningReset(hydGBloPrGEng);
		}
		
		if (hydGBloPrMnvrCare.clearFlag == 0) {
			hydGBloPrMnvrCare.active = 1;
		} else {
			ECAM_controller.warningReset(hydGBloPrMnvrCare);
		}
		
		if (hydGBloPrGaPitch.clearFlag == 0) {
			hydGBloPrGaPitch.active = 1;
		} else {
			ECAM_controller.warningReset(hydGBloPrGaPitch);
		}
		
		if (hydGBloPrFuelCnsmpt.clearFlag == 0 and warningNodes.Logic.blueGreenFuel.getValue()) {
			hydGBloPrFuelCnsmpt.active = 1;
		} else {
			ECAM_controller.warningReset(hydGBloPrFuelCnsmpt);
		}
		
		if (hydGBloPrFmsPredict.clearFlag == 0 and warningNodes.Logic.blueGreenFuel.getValue()) {
			hydGBloPrFmsPredict.active = 1;
		} else {
			ECAM_controller.warningReset(hydGBloPrFmsPredict);
		}
	} else {
		ECAM_controller.warningReset(hydGBloPr);
		ECAM_controller.warningReset(hydGBloPrRat);
		ECAM_controller.warningReset(hydGBloPrRatOn);
		ECAM_controller.warningReset(hydGBloPrBElec);
		ECAM_controller.warningReset(hydGBloPrGEng);
		ECAM_controller.warningReset(hydGBloPrMnvrCare);
		ECAM_controller.warningReset(hydGBloPrGaPitch);
		ECAM_controller.warningReset(hydGBloPrFuelCnsmpt);
		ECAM_controller.warningReset(hydGBloPrFmsPredict);
	}
	
	if (hydGYloPr.clearFlag == 0 and phaseVar3 != 4 and phaseVar3 != 5 and warningNodes.Logic.greenYellow.getValue()) {
		hydGYloPr.active = 1;
		if (hydGYloPrPtu.clearFlag == 0 and systems.HYD.Switch.ptu.getValue() != 0) {
			hydGYloPrPtu.active = 1;
		} else {
			ECAM_controller.warningReset(hydGYloPrPtu);
		}
		
		if (hydGYloPrGEng.clearFlag == 0 and systems.HYD.Switch.greenEDP.getValue()) {
			hydGYloPrGEng.active = 1;
		} else {
			ECAM_controller.warningReset(hydGYloPrGEng);
		}
		
		if (hydGYloPrYEng.clearFlag == 0 and systems.HYD.Switch.yellowEDP.getValue()) {
			hydGYloPrYEng.active = 1;
		} else {
			ECAM_controller.warningReset(hydGYloPrYEng);
		}
		
		if (hydGYloPrYElec.clearFlag == 0 and !systems.HYD.Pump.yellowElec.getValue() and systems.ELEC.Bus.ac2.getValue() >= 110 and systems.HYD.Qty.yellow.getValue() >= 3.5) { 
			hydGYloPrYElec.active = 1;
		} else {
			ECAM_controller.warningReset(hydGYloPrYElec);
		}
		
		if (hydGYloPrMnvrCare.clearFlag == 0) {
			hydGYloPrMnvrCare.active = 1;
		} else {
			ECAM_controller.warningReset(hydGYloPrMnvrCare);
		}
		
		if (hydGYloPrFuelCnsmpt.clearFlag == 0 and warningNodes.Logic.greenYellowFuel.getValue()) {
			hydGYloPrFuelCnsmpt.active = 1;
		} else {
			ECAM_controller.warningReset(hydGYloPrFuelCnsmpt);
		}
		
		if (hydGYloPrFmsPredict.clearFlag == 0 and warningNodes.Logic.greenYellowFuel.getValue()) {
			hydGYloPrFmsPredict.active = 1;
		} else {
			ECAM_controller.warningReset(hydGYloPrFmsPredict);
		}
	} else {
		ECAM_controller.warningReset(hydGYloPr);
		ECAM_controller.warningReset(hydGYloPrPtu);
		ECAM_controller.warningReset(hydGYloPrGEng);
		ECAM_controller.warningReset(hydGYloPrYEng);
		ECAM_controller.warningReset(hydGYloPrYElec);
		ECAM_controller.warningReset(hydGYloPrMnvrCare);
		ECAM_controller.warningReset(hydGYloPrFuelCnsmpt);
		ECAM_controller.warningReset(hydGYloPrFmsPredict);
	}
}

var messages_priority_2 = func {
	phaseVar2 = pts.ECAM.fwcWarningPhase.getValue();
	
	if ((phaseVar2 == 2 or phaseVar2 == 3 or phaseVar2 == 9) and warningNodes.Logic.thrLeversNotSet.getValue() and engThrustLvrNotSet.clearFlag == 0) {
		engThrustLvrNotSet.active = 1;
		
		if (systems.FADEC.Limit.flexActive.getBoolValue()) {
			engThrustLvrNotSetMCT.active = 1;
			ECAM_controller.warningReset(engThrustLvrNotSetMCT);
		} else {
			engThrustLvrNotSetTO.active = 1;
			ECAM_controller.warningReset(engThrustLvrNotSetTO);
		}
	} else {
		ECAM_controller.warningReset(engThrustLvrNotSet);
		ECAM_controller.warningReset(engThrustLvrNotSetMCT);
		ECAM_controller.warningReset(engThrustLvrNotSetTO);
	}
	
	if ((phaseVar2 >= 5 and phaseVar2 <= 7) and warningNodes.Logic.revSet.getValue() and engRevSet.clearFlag == 0) {
		engRevSet.active = 1;
		
		if (engRevSetLevers.clearFlag == 0) {
			engRevSetLevers.active = 1;
		} else {
			ECAM_controller.warningReset(engRevSetLevers);
		}
	} else {
		ECAM_controller.warningReset(engRevSet);
		ECAM_controller.warningReset(engRevSetLevers);
	}
	
	if (warningNodes.Logic.eng1Fail.getValue() and eng1Fail.clearFlag == 0) {
		eng1Fail.active = 1;
		
		if (0 == 1 and thrustMalfunction1.clearFlag == 0) { # OVER THR PROTECT
			thrustMalfunction1.active = 1;
		} else {
			ECAM_controller.warningReset(thrustMalfunction1);
		}
		
		if (0 == 1 and shaftFailure1.clearFlag == 0) { # PW ONLY
			shaftFailure1.active = 1;
		} else {
			ECAM_controller.warningReset(shaftFailure1);
		}
		
		if (phaseVar2 != 2 and phaseVar2 != 9 and pts.Controls.Engines.startSw.getValue() != 2 and eng1FailModeSel.clearFlag == 0) { # and not stall and not EGT protect
			eng1FailModeSel.active = 1;
		} else {
			ECAM_controller.warningReset(eng1FailModeSel);
		}
		
		if (phaseVar2 != 4 and warningNodes.Logic.phase5Trans.getValue() == 1) {
			if (eng1FailThrLvrIdle.clearFlag == 0 and systems.FADEC.detent[0].getValue() != 0) {
				eng1FailThrLvrIdle.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FailThrLvrIdle);
			}
			
			if (eng1FailNoRelight.clearFlag == 0 and phaseVar2 != 2 and phaseVar2 != 9 and pts.Controls.Engines.Engine.cutoffSw[0].getValue() == 0) {
				eng1FailNoRelight.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FailNoRelight);
			}
			
			if (eng1FailMasterOff.clearFlag == 0 and pts.Controls.Engines.Engine.cutoffSw[0].getValue() == 0) {
				eng1FailMasterOff.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FailMasterOff);
			}
			
			if (eng1FailDamage.clearFlag == 0 and systems.fireButtons[0].getValue() == 0) {
				eng1FailDamage.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FailDamage);
			}
			
			if (eng1FailFirePB.clearFlag == 0 and systems.fireButtons[0].getValue() == 0) {
				eng1FailFirePB.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FailFirePB);
			}
			
			if (eng1FailAgent1DischT.clearFlag == 0 and !systems.extinguisherBottles.vector[0].lightProp.getValue()) {
				eng1FailAgent1DischT.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FailAgent1DischT);
			}
			
			if (eng1FailAgent1Disch.clearFlag == 0 and !systems.extinguisherBottles.vector[0].lightProp.getValue()) {
				eng1FailAgent1Disch.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FailAgent1Disch);
			}
			
			if (eng1FailNoDamage.clearFlag == 0) {
				eng1FailNoDamage.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FailNoDamage);
			}
			
			if (eng1FailRelight.clearFlag == 0) {
				eng1FailRelight.active = 1;
			} else {
				ECAM_controller.warningReset(eng1FailRelight);
			}
		} else {
			ECAM_controller.warningReset(eng1FailThrLvrIdle);
			ECAM_controller.warningReset(eng1FailNoRelight);
			ECAM_controller.warningReset(eng1FailMasterOff);
			ECAM_controller.warningReset(eng1FailDamage);
			ECAM_controller.warningReset(eng1FailFirePB);
			ECAM_controller.warningReset(eng1FailAgent1DischT);
			ECAM_controller.warningReset(eng1FailAgent1Disch);
			ECAM_controller.warningReset(eng1FailNoDamage);
			ECAM_controller.warningReset(eng1FailRelight);
		}
	} else {
		ECAM_controller.warningReset(eng1Fail);
		ECAM_controller.warningReset(thrustMalfunction1);
		ECAM_controller.warningReset(shaftFailure1);
		ECAM_controller.warningReset(eng1FailModeSel);
		ECAM_controller.warningReset(eng1FailThrLvrIdle);
		ECAM_controller.warningReset(eng1FailNoRelight);
		ECAM_controller.warningReset(eng1FailMasterOff);
		ECAM_controller.warningReset(eng1FailDamage);
		ECAM_controller.warningReset(eng1FailFirePB);
		ECAM_controller.warningReset(eng1FailAgent1DischT);
		ECAM_controller.warningReset(eng1FailAgent1Disch);
		ECAM_controller.warningReset(eng1FailNoDamage);
		ECAM_controller.warningReset(eng1FailRelight);
	}
	
	if (warningNodes.Logic.eng1Shutdown.getValue() and eng1ShutDown.clearFlag == 0) {
		eng1ShutDown.active = 1;
		
		if (phaseVar2 != 4 and phaseVar2 != 5 and systems.fireButtons[0].getValue() == 0 and (systems.PNEU.Valves.wingLeft.getValue() or systems.PNEU.Valves.wingRight.getValue())) {
			if (eng1ShutDownPack.clearFlag == 0 and systems.PNEU.Switch.pack1.getValue() and systems.PNEU.Switch.pack2.getValue()) {
				eng1ShutDownPack.active = 1;
			} else {
				ECAM_controller.warningReset(eng1ShutDownPack);
			}
			
			if (eng1ShutDownXBleed.clearFlag == 0 and systems.PNEU.Valves.crossbleed.getValue() == 0) {
				eng1ShutDownXBleed.active = 1;
			} else {
				ECAM_controller.warningReset(eng1ShutDownXBleed);
			}
		} else {
			ECAM_controller.warningReset(eng1ShutDownPack);
			ECAM_controller.warningReset(eng1ShutDownXBleed);
		}
		
		if (FWC.Timer.gnd.getValue() == 0 or systems.fireButtons[0].getValue() == 0) {
			if (eng1ShutDownModeSel.clearFlag == 0 and pts.Controls.Engines.startSw.getValue() != 2) {
				eng1ShutDownModeSel.active = 1;
			} else {
				ECAM_controller.warningReset(eng1ShutDownModeSel);
			}
			
			if (systems.FUEL.Switches.crossfeed.getValue() == 0) {
				if (eng1ShutDownFuelLeak.clearFlag == 0) {
					eng1ShutDownFuelLeak.active = 1;
				} else {
					ECAM_controller.warningReset(eng1ShutDownFuelLeak);
				}
				
				if (eng1ShutDownImbalance.clearFlag == 0) {
					eng1ShutDownImbalance.active = 1;
				} else {
					ECAM_controller.warningReset(eng1ShutDownImbalance);
				}
			} else {
				ECAM_controller.warningReset(eng1ShutDownFuelLeak);
				ECAM_controller.warningReset(eng1ShutDownImbalance);
			}
		} else {
			ECAM_controller.warningReset(eng1ShutDownModeSel);
			ECAM_controller.warningReset(eng1ShutDownFuelLeak);
			ECAM_controller.warningReset(eng1ShutDownImbalance);
		}
		
		if (eng1ShutDownTCAS.clearFlag == 0 and pts.Instrumentation.TCAS.Inputs.mode.getValue() != 2) {
			eng1ShutDownTCAS.active = 1;
		} else {
			ECAM_controller.warningReset(eng1ShutDownTCAS);
		}
		
		if (0 == 1 and eng1ShutDownBuffet.clearFlag == 0) { # reverser unlocked
			eng1ShutDownBuffet.active = 1;
		} else {
			ECAM_controller.warningReset(eng1ShutDownBuffet);
		}
		
		if (0 == 1 and eng1ShutDownSpeed.clearFlag == 0) {
			eng1ShutDownSpeed.active = 1;
		} else {
			ECAM_controller.warningReset(eng1ShutDownSpeed);
		}
		
		if (systems.fireButtons[0].getValue() == 1) {
			if (eng1ShutDownXBleedS.clearFlag == 0 and systems.PNEU.Valves.crossbleed.getValue() != 0) {
				eng1ShutDownXBleedS.active = 1;
			} else {
				ECAM_controller.warningReset(eng1ShutDownXBleedS);
			}
			
			if (eng1ShutDownWingAI.clearFlag == 0 and (systems.PNEU.Valves.wingLeft.getValue() or systems.PNEU.Valves.wingRight.getValue())) {
				eng1ShutDownWingAI.active = 1;
			} else {
				ECAM_controller.warningReset(eng1ShutDownWingAI);
			}
			
			if (eng1ShutDownIcing.clearFlag == 0) {
				eng1ShutDownIcing.active = 1;
			} else {
				ECAM_controller.warningReset(eng1ShutDownIcing);
			}
		} else {
			ECAM_controller.warningReset(eng1ShutDownXBleedS);
			ECAM_controller.warningReset(eng1ShutDownWingAI);
			ECAM_controller.warningReset(eng1ShutDownIcing);
		}
	} else {
		ECAM_controller.warningReset(eng1ShutDown);
		ECAM_controller.warningReset(eng1ShutDownPack);
		ECAM_controller.warningReset(eng1ShutDownXBleed);
		ECAM_controller.warningReset(eng1ShutDownModeSel);
		ECAM_controller.warningReset(eng1ShutDownImbalance);
		ECAM_controller.warningReset(eng1ShutDownTCAS);
		ECAM_controller.warningReset(eng1ShutDownFuelLeak);
		ECAM_controller.warningReset(eng1ShutDownBuffet);
		ECAM_controller.warningReset(eng1ShutDownSpeed);
		ECAM_controller.warningReset(eng1ShutDownXBleedS);
		ECAM_controller.warningReset(eng1ShutDownWingAI);
		ECAM_controller.warningReset(eng1ShutDownIcing);
	}
	
	if (warningNodes.Logic.eng2Fail.getValue() and eng2Fail.clearFlag == 0) {
		eng2Fail.active = 1;
		
		if (0 == 1 and thrustMalfunction2.clearFlag == 0) { # OVER THR PROTECT
			thrustMalfunction2.active = 1;
		} else {
			ECAM_controller.warningReset(thrustMalfunction2);
		}
		
		if (0 == 1 and shaftFailure2.clearFlag == 0) { # PW ONLY
			shaftFailure2.active = 1;
		} else {
			ECAM_controller.warningReset(shaftFailure2);
		}
		
		if (phaseVar2 != 2 and phaseVar2 != 9 and pts.Controls.Engines.startSw.getValue() != 2 and eng2FailModeSel.clearFlag == 0) { # and not stall and not EGT protect
			eng2FailModeSel.active = 1;
		} else {
			ECAM_controller.warningReset(eng2FailModeSel);
		}
		
		if (phaseVar2 != 4 and warningNodes.Logic.phase5Trans.getValue() == 1) {
			if (eng2FailThrLvrIdle.clearFlag == 0 and systems.FADEC.detent[1].getValue() != 0) {
				eng2FailThrLvrIdle.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FailThrLvrIdle);
			}
			
			if (eng2FailNoRelight.clearFlag == 0 and phaseVar2 != 2 and phaseVar2 != 9 and pts.Controls.Engines.Engine.cutoffSw[1].getValue() == 0) {
				eng2FailNoRelight.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FailNoRelight);
			}
			
			if (eng2FailMasterOff.clearFlag == 0 and pts.Controls.Engines.Engine.cutoffSw[1].getValue() == 0) {
				eng2FailMasterOff.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FailMasterOff);
			}
			
			if (eng2FailDamage.clearFlag == 0 and systems.fireButtons[1].getValue() == 0) {
				eng2FailDamage.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FailDamage);
			}
			
			if (eng2FailFirePB.clearFlag == 0 and systems.fireButtons[1].getValue() == 0) {
				eng2FailFirePB.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FailFirePB);
			}
			
			if (eng2FailAgent1DischT.clearFlag == 0 and !systems.extinguisherBottles.vector[2].lightProp.getValue()) {
				eng2FailAgent1DischT.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FailAgent1DischT);
			}
			
			if (eng2FailAgent1Disch.clearFlag == 0 and !systems.extinguisherBottles.vector[2].lightProp.getValue()) {
				eng2FailAgent1Disch.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FailAgent1Disch);
			}
			
			if (eng2FailNoDamage.clearFlag == 0) {
				eng2FailNoDamage.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FailNoDamage);
			}
			
			if (eng2FailRelight.clearFlag == 0) {
				eng2FailRelight.active = 1;
			} else {
				ECAM_controller.warningReset(eng2FailRelight);
			}
		} else {
			ECAM_controller.warningReset(eng2FailThrLvrIdle);
			ECAM_controller.warningReset(eng2FailNoRelight);
			ECAM_controller.warningReset(eng2FailMasterOff);
			ECAM_controller.warningReset(eng2FailDamage);
			ECAM_controller.warningReset(eng2FailFirePB);
			ECAM_controller.warningReset(eng2FailAgent1DischT);
			ECAM_controller.warningReset(eng2FailAgent1Disch);
			ECAM_controller.warningReset(eng2FailNoDamage);
			ECAM_controller.warningReset(eng2FailRelight);
		}
	} else {
		ECAM_controller.warningReset(eng2Fail);
		ECAM_controller.warningReset(thrustMalfunction2);
		ECAM_controller.warningReset(shaftFailure2);
		ECAM_controller.warningReset(eng2FailModeSel);
		ECAM_controller.warningReset(eng2FailThrLvrIdle);
		ECAM_controller.warningReset(eng2FailNoRelight);
		ECAM_controller.warningReset(eng2FailMasterOff);
		ECAM_controller.warningReset(eng2FailDamage);
		ECAM_controller.warningReset(eng2FailFirePB);
		ECAM_controller.warningReset(eng2FailAgent1DischT);
		ECAM_controller.warningReset(eng2FailAgent1Disch);
		ECAM_controller.warningReset(eng2FailNoDamage);
		ECAM_controller.warningReset(eng2FailRelight);
	}
	
	if (warningNodes.Logic.eng2Shutdown.getValue() and eng2ShutDown.clearFlag == 0) {
		eng2ShutDown.active = 1;
		
		if (phaseVar2 != 4 and phaseVar2 != 5 and systems.fireButtons[1].getValue() == 0 and (systems.PNEU.Valves.wingLeft.getValue() or systems.PNEU.Valves.wingRight.getValue())) {
			if (eng2ShutDownPack1.clearFlag == 0 and systems.ELEC.EmerElec.getValue() and systems.PNEU.Switch.pack1.getValue() and systems.PNEU.Switch.pack2.getValue()) {
				eng2ShutDownPack1.active = 1;
			} else {
				ECAM_controller.warningReset(eng2ShutDownPack1);
			}
			
			if (eng2ShutDownPack.clearFlag == 0 and !systems.ELEC.EmerElec.getValue() and systems.PNEU.Switch.pack1.getValue() and systems.PNEU.Switch.pack2.getValue()) {
				eng2ShutDownPack.active = 1;
			} else {
				ECAM_controller.warningReset(eng2ShutDownPack);
			}
			
			if (eng2ShutDownXBleed.clearFlag == 0 and systems.PNEU.Valves.crossbleed.getValue() == 0) {
				eng2ShutDownXBleed.active = 1;
			} else {
				ECAM_controller.warningReset(eng2ShutDownXBleed);
			}
		} else {
			ECAM_controller.warningReset(eng2ShutDownPack);
			ECAM_controller.warningReset(eng2ShutDownXBleed);
		}
		
		if (FWC.Timer.gnd.getValue() == 0 or systems.fireButtons[1].getValue() == 0) {
			if (eng2ShutDownModeSel.clearFlag == 0 and pts.Controls.Engines.startSw.getValue() != 2) {
				eng2ShutDownModeSel.active = 1;
			} else {
				ECAM_controller.warningReset(eng2ShutDownModeSel);
			}
			
			if (systems.FUEL.Switches.crossfeed.getValue() == 0) {
				if (eng2ShutDownFuelLeak.clearFlag == 0) {
					eng2ShutDownFuelLeak.active = 1;
				} else {
					ECAM_controller.warningReset(eng2ShutDownFuelLeak);
				}
				
				if (eng2ShutDownImbalance.clearFlag == 0) {
					eng2ShutDownImbalance.active = 1;
				} else {
					ECAM_controller.warningReset(eng2ShutDownImbalance);
				}
			} else {
				ECAM_controller.warningReset(eng2ShutDownFuelLeak);
				ECAM_controller.warningReset(eng2ShutDownImbalance);
			}
		} else {
			ECAM_controller.warningReset(eng2ShutDownModeSel);
			ECAM_controller.warningReset(eng2ShutDownFuelLeak);
			ECAM_controller.warningReset(eng2ShutDownImbalance);
		}
		
		if (eng2ShutDownTCAS.clearFlag == 0 and pts.Instrumentation.TCAS.Inputs.mode.getValue() != 2) {
			eng2ShutDownTCAS.active = 1;
		} else {
			ECAM_controller.warningReset(eng2ShutDownTCAS);
		}
		
		if (0 == 1 and eng2ShutDownBuffet.clearFlag == 0) { # reverser unlocked
			eng2ShutDownBuffet.active = 1;
		} else {
			ECAM_controller.warningReset(eng2ShutDownBuffet);
		}
		
		if (0 == 1 and eng2ShutDownSpeed.clearFlag == 0) {
			eng2ShutDownSpeed.active = 1;
		} else {
			ECAM_controller.warningReset(eng2ShutDownSpeed);
		}
		
		if (systems.fireButtons[1].getValue() == 1) {
			if (eng2ShutDownXBleedS.clearFlag == 0 and systems.PNEU.Valves.crossbleed.getValue() != 0) {
				eng2ShutDownXBleedS.active = 1;
			} else {
				ECAM_controller.warningReset(eng2ShutDownXBleedS);
			}
			
			if (eng2ShutDownWingAI.clearFlag == 0 and (systems.PNEU.Valves.wingLeft.getValue() or systems.PNEU.Valves.wingRight.getValue())) {
				eng2ShutDownWingAI.active = 1;
			} else {
				ECAM_controller.warningReset(eng2ShutDownWingAI);
			}
			
			if (eng2ShutDownIcing.clearFlag == 0) {
				eng2ShutDownIcing.active = 1;
			} else {
				ECAM_controller.warningReset(eng2ShutDownIcing);
			}
		} else {
			ECAM_controller.warningReset(eng2ShutDownXBleedS);
			ECAM_controller.warningReset(eng2ShutDownWingAI);
			ECAM_controller.warningReset(eng2ShutDownIcing);
		}
	} else {
		ECAM_controller.warningReset(eng2ShutDown);
		ECAM_controller.warningReset(eng2ShutDownPack);
		ECAM_controller.warningReset(eng2ShutDownXBleed);
		ECAM_controller.warningReset(eng2ShutDownModeSel);
		ECAM_controller.warningReset(eng2ShutDownImbalance);
		ECAM_controller.warningReset(eng2ShutDownTCAS);
		ECAM_controller.warningReset(eng2ShutDownFuelLeak);
		ECAM_controller.warningReset(eng2ShutDownBuffet);
		ECAM_controller.warningReset(eng2ShutDownSpeed);
		ECAM_controller.warningReset(eng2ShutDownXBleedS);
		ECAM_controller.warningReset(eng2ShutDownWingAI);
		ECAM_controller.warningReset(eng2ShutDownIcing);
	}
	
	# SAT ABOVE FLEX TEMP
	if (dmc.DMController.DMCs[1] != nil and dmc.DMController.DMCs[1].outputs[4] != nil) {
		_SATval = dmc.DMController.DMCs[1].outputs[4].getValue() or nil;
	} else {
		_SATval = nil;
	}
	if (satAbvFlexTemp.clearFlag == 0 and phaseVar2 == 2 and systems.FADEC.Limit.flexActive.getBoolValue() and _SATval != nil and _SATval > systems.FADEC.Limit.flexTemp.getValue() and !warningNodes.Logic.thrLeversNotSet.getValue()) {
		satAbvFlexTemp.active = 1;
		
		if (satAbvFlexTempCheck.clearFlag == 0) {
			satAbvFlexTempCheck.active = 1;
		} else {
			ECAM_controller.warningReset(satAbvFlexTempCheck);
		}
	} else {
		ECAM_controller.warningReset(satAbvFlexTemp);
		ECAM_controller.warningReset(satAbvFlexTempCheck);
	}
	
	# DC EMER CONFIG
	if (warningNodes.Timers.dcEmerConfig.getValue() == 1 and phaseVar2 != 4 and phaseVar2 != 8 and dcEmerconfig.clearFlag == 0) {
		dcEmerconfig.active = 1;
		if (systems.ELEC.Source.EmerGen.relayPos.getValue() == 0 and dcEmerconfigManOn.clearFlag == 0) {
			dcEmerconfigManOn.active = 1;
		} else {
			ECAM_controller.warningReset(dcEmerconfigManOn);
		}
		
		if ((warningNodes.Logic.dcEssFuelConsumptionIncreased.getValue() or warningNodes.Logic.dc2FuelConsumptionIncreased.getValue()) and dcEmerconfigFuel.clearFlag == 0) {
			dcEmerconfigFuel.active = 1;
		} else {
			ECAM_controller.warningReset(dcEmerconfigFuel);
		}
	} else {
		ECAM_controller.warningReset(dcEmerconfig);
		ECAM_controller.warningReset(dcEmerconfigManOn);
		ECAM_controller.warningReset(dcEmerconfigFuel);
	}
	
	if (warningNodes.Timers.dc12Fault.getValue() == 1 and phaseVar2 != 4 and phaseVar2 != 8 and dcBus12Fault.clearFlag == 0) {
		dcBus12Fault.active = 1;
		
		if (dcBus12FaultBlower.clearFlag == 0) {
			dcBus12FaultBlower.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus12FaultBlower);
		}
		
		if (dcBus12FaultExtract.clearFlag == 0) {
			dcBus12FaultExtract.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus12FaultExtract);
		}
		
		if (dcBus12FaultBaroRef.clearFlag == 0) {
			dcBus12FaultBaroRef.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus12FaultBaroRef);
		}
		
		if (dcBus12FaultFuel.clearFlag == 0 and warningNodes.Logic.dc2FuelConsumptionIncreased.getValue()) {
			dcBus12FaultFuel.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus12FaultFuel);
		}
		
		if (dcBus12FaultPredict.clearFlag == 0 and warningNodes.Logic.dc2FMSPredictions.getValue()) {
			dcBus12FaultPredict.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus12FaultPredict);
		}
		
		if (dcBus12FaultIcing.clearFlag == 0) {
			dcBus12FaultIcing.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus12FaultIcing);
		}
		
		if (dcBus12FaultBrking.clearFlag == 0) {
			dcBus12FaultBrking.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus12FaultBrking);
		}
	} else {
		ECAM_controller.warningReset(dcBus12Fault);
		ECAM_controller.warningReset(dcBus12FaultBlower);
		ECAM_controller.warningReset(dcBus12FaultExtract);
		ECAM_controller.warningReset(dcBus12FaultBaroRef);
		ECAM_controller.warningReset(dcBus12FaultFuel);
		ECAM_controller.warningReset(dcBus12FaultPredict);
		ECAM_controller.warningReset(dcBus12FaultIcing);
		ECAM_controller.warningReset(dcBus12FaultBrking);
	}
	
	if (warningNodes.Timers.acEssFault.getValue() == 1 and phaseVar2 != 4 and phaseVar2 != 8 and AcBusEssFault.clearFlag == 0) {
		AcBusEssFault.active = 1;
		if (!systems.ELEC.Switch.acEssFeed.getBoolValue() and AcBusEssFaultFeed.clearFlag == 0) {
			AcBusEssFaultFeed.active = 1;
		} else {
			ECAM_controller.warningReset(AcBusEssFaultFeed);
		}
		
		if (atc.transponderPanel.atcSel != 2 and AcBusEssFaultAtc.clearFlag == 0) {
			AcBusEssFaultAtc.active = 1;
		} else {
			ECAM_controller.warningReset(AcBusEssFaultAtc);
		}
	} else {
		ECAM_controller.warningReset(AcBusEssFault);
		ECAM_controller.warningReset(AcBusEssFaultFeed);
		ECAM_controller.warningReset(AcBusEssFaultAtc);
	}
	
	if (warningNodes.Timers.ac1Fault.getValue() == 1 and phaseVar2 != 4 and phaseVar2 != 8 and AcBus1Fault.clearFlag == 0) {
		AcBus1Fault.active = 1;
		
		if (AcBus1FaultBlower.clearFlag == 0) {
			AcBus1FaultBlower.active = 1;
		} else {
			ECAM_controller.warningReset(AcBus1FaultBlower);
		}
	} else {
		ECAM_controller.warningReset(AcBus1Fault);
		ECAM_controller.warningReset(AcBus1FaultBlower);
	}
	
	if (warningNodes.Timers.dcEssFault.getValue() == 1 and phaseVar2 != 4 and phaseVar2 != 8 and DcEssBusFault.clearFlag == 0) {
		DcEssBusFault.active = 1;
		if (DcEssBusFaultRadio.clearFlag == 0) {
			DcEssBusFaultRadio.active = 1;
		} else {
			ECAM_controller.warningReset(DcEssBusFaultRadio);
		}
		if (DcEssBusFaultRadio2.clearFlag == 0) {
			DcEssBusFaultRadio2.active = 1;
		} else {
			ECAM_controller.warningReset(DcEssBusFaultRadio2);
		}
		
		if (DcEssBusFaultBaro.clearFlag == 0) {
			DcEssBusFaultBaro.active = 1;
		} else {
			ECAM_controller.warningReset(DcEssBusFaultBaro);
		}
		
		if (0 == 1 and systems.ELEC.Bus.dc2.getValue() < 25 and systems.ELEC.Bus.dcEss.getValue() < 25 and DcEssBusFaultGear.clearFlag == 0) { # LGCIU12 FAULT
			DcEssBusFaultGear.active = 1;
		} else {
			ECAM_controller.warningReset(DcEssBusFaultGear);
		}
		
		if (DcEssBusFaultGPWS.clearFlag == 0) {
			DcEssBusFaultGPWS.active = 1;
		} else {
			ECAM_controller.warningReset(DcEssBusFaultGPWS);
		}
		
		if (DcEssBusFaultFuel.clearFlag == 0 and warningNodes.Logic.dcEssFuelConsumptionIncreased.getValue()) {
			DcEssBusFaultFuel.active = 1;
		} else {
			ECAM_controller.warningReset(DcEssBusFaultFuel);
		}
		
		if (DcEssBusFaultPredict.clearFlag == 0 and warningNodes.Logic.dcEssFMSPredictions.getValue()) {
			DcEssBusFaultPredict.active = 1;
		} else {
			ECAM_controller.warningReset(DcEssBusFaultPredict);
		}
		
		if (DcEssBusFaultIcing.clearFlag == 0) {
			DcEssBusFaultIcing.active = 1;
		} else {
			ECAM_controller.warningReset(DcEssBusFaultIcing);
		}
	} else {
		ECAM_controller.warningReset(DcEssBusFault);
		ECAM_controller.warningReset(DcEssBusFaultRadio);
		ECAM_controller.warningReset(DcEssBusFaultRadio2);
		ECAM_controller.warningReset(DcEssBusFaultBaro);
		ECAM_controller.warningReset(DcEssBusFaultGear);
		ECAM_controller.warningReset(DcEssBusFaultGPWS);
		ECAM_controller.warningReset(DcEssBusFaultFuel);
		ECAM_controller.warningReset(DcEssBusFaultPredict);
		ECAM_controller.warningReset(DcEssBusFaultIcing);
	}
	
	if (warningNodes.Timers.ac2Fault.getValue() == 1 and phaseVar2 != 4 and phaseVar2 != 8 and AcBus2Fault.clearFlag == 0) {
		AcBus2Fault.active = 1;
		if (AcBus2FaultExtract.clearFlag == 0) {
			AcBus2FaultExtract.active = 1;
		} else {
			ECAM_controller.warningReset(AcBus2FaultExtract);
		}
		
		if (atc.transponderPanel.atcSel != 1 and AcBus2FaultAtc.clearFlag == 0) {
			AcBus2FaultAtc.active = 1;
		} else {
			ECAM_controller.warningReset(AcBus2FaultAtc);
		}
	} else {
		ECAM_controller.warningReset(AcBus2Fault);
		ECAM_controller.warningReset(AcBus2FaultExtract);
		ECAM_controller.warningReset(AcBus2FaultAtc);
	}
	
	if (warningNodes.Timers.dc1Fault.getValue() == 1 and phaseVar2 != 4 and phaseVar2 != 8 and dcBus1Fault.clearFlag == 0) {
		dcBus1Fault.active = 1;
		
		if (dcBus1FaultBlower.clearFlag == 0) {
			dcBus1FaultBlower.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus1FaultBlower);
		}
		if (dcBus1FaultExtract.clearFlag == 0) {
			dcBus1FaultExtract.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus1FaultExtract);
		}
		if (dcBus1FaultIcing.clearFlag == 0) {
			dcBus1FaultIcing.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus1FaultIcing);
		}
	} else {
		ECAM_controller.warningReset(dcBus1Fault);
		ECAM_controller.warningReset(dcBus1FaultBlower);
		ECAM_controller.warningReset(dcBus1FaultExtract);
		ECAM_controller.warningReset(dcBus1FaultIcing);
	}
	
	if (warningNodes.Timers.dc2Fault.getValue() == 1 and phaseVar2 != 4 and phaseVar2 != 8 and dcBus2Fault.clearFlag == 0) {
		dcBus2Fault.active = 1;
		
		if (dcBus2FaultAirData.clearFlag == 0 and systems.SwitchingPanel.Switches.airData.getValue() != 1) {
			dcBus2FaultAirData.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus2FaultAirData);
		}
		
		if (dcBus2FaultBaro.clearFlag == 0) {
			dcBus2FaultBaro.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus2FaultBaro);
		}
		
		if (0 == 1 and systems.ELEC.Bus.dc2.getValue() < 25 and systems.ELEC.Bus.dcEss.getValue() < 25 and dcBus2FaultGear.clearFlag == 0) { # LGCIU12 FAULT
			dcBus2FaultGear.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus2FaultGear);
		}
		
		if (dcBus2FaultFuel.clearFlag == 0 and warningNodes.Logic.dc2FuelConsumptionIncreased.getValue()) {
			dcBus2FaultFuel.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus2FaultFuel);
		}
		
		if (dcBus2FaultPredict.clearFlag == 0 and warningNodes.Logic.dc2FMSPredictions.getValue()) {
			dcBus2FaultPredict.active = 1;
		} else {
			ECAM_controller.warningReset(dcBus2FaultPredict);
		}
	} else {
		ECAM_controller.warningReset(dcBus2Fault);
		ECAM_controller.warningReset(dcBus2FaultAirData);
		ECAM_controller.warningReset(dcBus2FaultBaro);
		ECAM_controller.warningReset(dcBus2FaultGear);
		ECAM_controller.warningReset(dcBus2FaultFuel);
		ECAM_controller.warningReset(dcBus2FaultPredict);
	}
	
	if (warningNodes.Timers.dcBatFault.getValue() == 1 and phaseVar2 != 4 and phaseVar2 != 5 and phaseVar2 != 7 and phaseVar2 != 8 and dcBusBatFault.clearFlag == 0) {
		dcBusBatFault.active = 1;
	} else {
		ECAM_controller.warningReset(dcBusBatFault);
	}
	
	if (warningNodes.Timers.dcEssShed.getValue() == 1 and phaseVar2 != 4 and phaseVar2 != 8 and dcBusEssShed.clearFlag == 0) {
		dcBusEssShed.active = 1;
		if (dcBusEssShedExtract.clearFlag == 0) {
			dcBusEssShedExtract.active = 1;
		} else {
			ECAM_controller.warningReset(dcBusEssShedExtract);
		}
		if (dcBusEssShedIcing.clearFlag == 0) {
			dcBusEssShedIcing.active = 1;
		} else {
			ECAM_controller.warningReset(dcBusEssShedIcing);
		}
	} else {
		ECAM_controller.warningReset(dcBusEssShed);
		ECAM_controller.warningReset(dcBusEssShedExtract);
		ECAM_controller.warningReset(dcBusEssShedIcing);
	}
	
	if (warningNodes.Timers.acEssShed.getValue() == 1 and phaseVar2 != 4 and phaseVar2 != 8 and acBusEssShed.clearFlag == 0) {
		acBusEssShed.active = 1;
		if (!systems.ELEC.EmerElec.getValue() and atc.transponderPanel.atcSel != 2 and acBusEssShedAtc.clearFlag == 0) {
			acBusEssShedAtc.active = 1;
		} else {
			ECAM_controller.warningReset(acBusEssShed);
		}
	} else {
		ECAM_controller.warningReset(acBusEssShed);
		ECAM_controller.warningReset(acBusEssShedAtc);
	}
	
	# GEN 1 FAULT
	if (gen1fault.clearFlag == 0 and warningNodes.Flipflops.gen1Fault.getValue() and (phaseVar2 == 2 or phaseVar2 == 3 or phaseVar2 == 6 or phaseVar2 == 9)) {
		gen1fault.active = 1;
		if (!warningNodes.Flipflops.gen1FaultOnOff.getValue()) {
			gen1faultGen.active = 1;
		} else {
			ECAM_controller.warningReset(gen1faultGen);
		}
		
		if (systems.ELEC.Switch.gen1.getBoolValue()) {
			gen1faultGen2.active = 1;
			gen1faultGen3.active = 1;
		} else {
			ECAM_controller.warningReset(gen1faultGen2);
			ECAM_controller.warningReset(gen1faultGen3);
		}
	} else {
		ECAM_controller.warningReset(gen1fault);
		ECAM_controller.warningReset(gen1faultGen);
		ECAM_controller.warningReset(gen1faultGen2);
		ECAM_controller.warningReset(gen1faultGen3);
	}
	
	# ESS TR FAULT
	if (essTRFault.clearFlag == 0 and systems.ELEC.Fail.essTrFault.getValue() and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		essTRFault.active = 1;
	} else {
		ECAM_controller.warningReset(essTRFault);
	}
	
	# GEN 2 FAULT
	if (gen2fault.clearFlag == 0 and warningNodes.Flipflops.gen2Fault.getValue() and (phaseVar2 == 2 or phaseVar2 == 3 or phaseVar2 == 6 or phaseVar2 == 9)) {
		gen2fault.active = 1;
		if (!warningNodes.Flipflops.gen2FaultOnOff.getValue()) {
			gen2faultGen.active = 1;
		} else {
			ECAM_controller.warningReset(gen2faultGen);
		}
		
		if (systems.ELEC.Switch.gen2.getBoolValue()) {
			gen2faultGen2.active = 1;
			gen2faultGen3.active = 1;
		} else {
			ECAM_controller.warningReset(gen2faultGen2);
			ECAM_controller.warningReset(gen2faultGen3);
		}
	} else {
		ECAM_controller.warningReset(gen2fault);
		ECAM_controller.warningReset(gen2faultGen);
		ECAM_controller.warningReset(gen2faultGen2);
		ECAM_controller.warningReset(gen2faultGen3);
	}
	
	if (apuGenfault.clearFlag == 0 and warningNodes.Flipflops.apuGenFault.getValue() and (phaseVar2 <= 3 or phaseVar2 == 6 or phaseVar2 >= 9)) {
		apuGenfault.active = 1;
		if (!warningNodes.Flipflops.apuGenFaultOnOff.getValue()) {
			apuGenfaultGen.active = 1;
		} else {
			ECAM_controller.warningReset(apuGenfaultGen);
		}
		
		if (systems.ELEC.Switch.genApu.getBoolValue()) {
			apuGenfaultGen2.active = 1;
			apuGenfaultGen3.active = 1;
		} else {
			ECAM_controller.warningReset(apuGenfaultGen2);
			ECAM_controller.warningReset(apuGenfaultGen3);
		}
	} else {
		ECAM_controller.warningReset(apuGenfault);
		ECAM_controller.warningReset(apuGenfaultGen);
		ECAM_controller.warningReset(apuGenfaultGen2);
		ECAM_controller.warningReset(apuGenfaultGen3);
	}
	
	# GEN OFF
	if (gen1Off.clearFlag == 0 and warningNodes.Logic.gen1Off.getValue() and (phaseVar2 == 2 or phaseVar2 == 3 or phaseVar2 == 6 or phaseVar2 == 9)) {
		gen1Off.active = 1;
	} else {
		ECAM_controller.warningReset(gen1Off);
	}
	
	if (gen2Off.clearFlag == 0 and warningNodes.Logic.gen2Off.getValue() and (phaseVar2 == 2 or phaseVar2 == 3 or phaseVar2 == 6 or phaseVar2 == 9)) {
		gen2Off.active = 1;
	} else {
		ECAM_controller.warningReset(gen2Off);
	}
	
	# ELEC AC ESS BUS ALTN
	if (acEssBusAltn.clearFlag == 0 and warningNodes.Logic.acEssBusAltn.getValue() and (phaseVar2 >= 9 or phaseVar2 <= 2)) {
		acEssBusAltn.active = 1;
	} else {
		ECAM_controller.warningReset(acEssBusAltn);
	}
	
	# L ELEV FAULT
	if (lElevFault.clearFlag == 0 and warningNodes.Timers.leftElevFail.getValue() and phaseVar2 != 4 and phaseVar2 != 5) {
		lElevFault.active = 1;
		if (lElevFaultCare.clearFlag == 0) {
			lElevFaultCare.active = 1;
		} else {
			ECAM_controller.warningReset(lElevFaultCare);
		}
		if (lElevFaultPitch.clearFlag == 0) {
			lElevFaultPitch.active = 1;
		} else {
			ECAM_controller.warningReset(lElevFaultPitch);
		}
	} else {
		ECAM_controller.warningReset(lElevFault);
		ECAM_controller.warningReset(lElevFaultCare);
		ECAM_controller.warningReset(lElevFaultPitch);
	}
	
	if (rElevFault.clearFlag == 0 and warningNodes.Timers.rightElevFail.getValue() and phaseVar2 != 4 and phaseVar2 != 5) {
		rElevFault.active = 1;
		if (rElevFaultCare.clearFlag == 0) {
			rElevFaultCare.active = 1;
		} else {
			ECAM_controller.warningReset(rElevFaultCare);
		}
		if (rElevFaultPitch.clearFlag == 0) {
			rElevFaultPitch.active = 1;
		} else {
			ECAM_controller.warningReset(rElevFaultPitch);
		}
	} else {
		ECAM_controller.warningReset(rElevFault);
		ECAM_controller.warningReset(rElevFaultCare);
		ECAM_controller.warningReset(rElevFaultPitch);
	}
	
	if (fctlSpdBrkStillOut.clearFlag == 0 and warningNodes.Logic.spdBrkOut.getValue() and (phaseVar2 == 6 or phaseVar2 == 7)) {
		fctlSpdBrkStillOut.active = 1;
	} else {
		ECAM_controller.warningReset(fctlSpdBrkStillOut);
	}
	
	if (directLaw.clearFlag == 0 and warningNodes.Timers.directLaw.getValue() and phaseVar2 != 4 and phaseVar2 != 5 and phaseVar2 != 7 and phaseVar2 != 8) {
		directLaw.active = 1;
		directLawProt.active = 1;
		if (directLawMaxSpeed.clearFlag == 0 and !fbw.tripleADRFail and pts.Gear.position[1].getValue() == 1) {
			directLawMaxSpeed.active = 1;
		} else {
			ECAM_controller.warningReset(directLawMaxSpeed);
		}
		if (directLawTrim.clearFlag == 0 and (systems.HYD.Psi.green.getValue() >= 1500 or systems.HYD.Psi.yellow.getValue() >= 1500) and !fbw.FBW.Failures.ths.getValue()) {
			directLawTrim.active = 1;
		} else {
			ECAM_controller.warningReset(directLawTrim);
		}
		if (directLawCare.clearFlag == 0 and (fbw.tripleADRFail or pts.Gear.position[1].getValue() == 1)) {
			directLawCare.active = 1;
		} else {
			ECAM_controller.warningReset(directLawCare);
		}
		if (directLawSpdBrk.clearFlag == 0 and !fbw.tripleADRFail and pts.Gear.position[1].getValue() == 1) {
			directLawSpdBrk.active = 1;
		} else {
			ECAM_controller.warningReset(directLawSpdBrk);
		}
		if (directLawSpdBrk2.clearFlag == 0 and fbw.tripleADRFail) {
			directLawSpdBrk2.active = 1;
		} else {
			ECAM_controller.warningReset(directLawSpdBrk2);
		}
	} else {
		ECAM_controller.warningReset(directLaw);
		ECAM_controller.warningReset(directLawProt);
		ECAM_controller.warningReset(directLawMaxSpeed);
		ECAM_controller.warningReset(directLawTrim);
		ECAM_controller.warningReset(directLawCare);
		ECAM_controller.warningReset(directLawSpdBrk);
		ECAM_controller.warningReset(directLawSpdBrk2);
	}
	
	if (altnLaw.clearFlag == 0 and warningNodes.Timers.altnLaw.getValue() and phaseVar2 != 4 and phaseVar2 != 5 and phaseVar2 != 7 and phaseVar2 != 8) {
		altnLaw.active = 1;
		altnLawProt.active = 1;
		if (altnLawMaxSpeed.clearFlag == 0 and altnLawMaxSpeed2.clearFlag == 0 and !fbw.tripleADRFail) {
			if (!(systems.HYD.Warnings.greenAbnormLoPr.getValue() and (systems.HYD.Warnings.blueAbnormLoPr.getValue() or systems.HYD.Warnings.yellowAbnormLoPr.getValue()))) {
				altnLawMaxSpeed.active = 1;
				ECAM_controller.warningReset(altnLawMaxSpeed2);
			} else {
				altnLawMaxSpeed2.active = 1;
				ECAM_controller.warningReset(altnLawMaxSpeed);
			}
		} else {
			ECAM_controller.warningReset(altnLawMaxSpeed);
			ECAM_controller.warningReset(altnLawMaxSpeed2);
		}
		
		if (altnLawMaxSpdBrk.clearFlag == 0 and (fbw.tripleADRFail or warningNodes.Logic.leftElevFail.getValue() or warningNodes.Logic.rightElevFail.getValue())) {
			altnLawMaxSpdBrk.active = 1;
		} else {
			ECAM_controller.warningReset(altnLawMaxSpdBrk);
		}
	} else {
		ECAM_controller.warningReset(altnLaw);
		ECAM_controller.warningReset(altnLawProt);
		ECAM_controller.warningReset(altnLawMaxSpeed);
		ECAM_controller.warningReset(altnLawMaxSpeed2);
		ECAM_controller.warningReset(altnLawMaxSpdBrk);
	}
	
	if ((athr_offw.clearFlag == 0) and athrWarn.getValue() == 2 and phaseVar2 != 4 and phaseVar2 != 8 and phaseVar2 != 10) {
		athr_offw.active = 1;
		athr_offw_1.active = 1;
	} else {
		ECAM_controller.warningReset(athr_offw);
		ECAM_controller.warningReset(athr_offw_1);
	}
	
	if ((athr_lock.clearFlag == 0) and phaseVar2 >= 5 and phaseVar2 <= 7 and getprop("/fdm/jsbsim/fadec/thr-locked-alert") == 1) {
		if (getprop("/fdm/jsbsim/fadec/thr-locked-flash") == 0) {
			athr_lock.msg = " ";
		} else {
			athr_lock.msg = msgSave;
		}
		athr_lock.active = 1;
		athr_lock_1.active = 1;
	} else {
		ECAM_controller.warningReset(athr_lock);
		ECAM_controller.warningReset(athr_lock_1);
	}
	
	
	if ((athr_lim.clearFlag == 0) and getprop("it-autoflight/output/athr") == 1 and ((getprop("/fdm/jsbsim/fadec/eng-out") != 1 and (systems.FADEC.detentText[0].getValue() == "MAN" or systems.FADEC.detentText[1].getValue() == "MAN")) or (getprop("/fdm/jsbsim/fadec/eng-out") == 1 and (systems.FADEC.detentText[0].getValue() == "MAN" or systems.FADEC.detentText[1].getValue() == "MAN" or (systems.FADEC.detentText[0].getValue() == "MAN THR" and !systems.FADEC.manThrAboveMct[0]) or (systems.FADEC.detentText[1].getValue() == "MAN THR" and !systems.FADEC.manThrAboveMct[1])))) and (phaseVar2 >= 5 and phaseVar2 <= 7)) {
		athr_lim.active = 1;
		athr_lim_1.active = 1;
	} else {
		ECAM_controller.warningReset(athr_lim);
		ECAM_controller.warningReset(athr_lim_1);
	}
	
	if (pts.Instrumentation.TCAS.servicable.getValue() == 0 and phaseVar2 != 1 and phaseVar2 != 3 and phaseVar2 != 4 and phaseVar2 != 5 and phaseVar2 != 7 and phaseVar2 != 8 and phaseVar2 != 10 and systems.ELEC.Bus.ac1.getValue() >= 110 and pts.Instrumentation.TCAS.Inputs.mode.getValue() != 1 and tcasFault.clearFlag == 0) {
		tcasFault.active = 1;
	} else {
		ECAM_controller.warningReset(tcasFault);
	}
	
	if (phaseVar2 == 6 and pts.Instrumentation.TCAS.Inputs.mode.getValue() == 1 and !tcasFault.active and (atc.Transponders.vector[0].condition != 0 and atc.Transponders.vector[1].condition != 0) and tcasStby.clearFlag == 0) {
		tcasStby.active = 1;
	} else {
		ECAM_controller.warningReset(tcasStby);
	}
	
	if (gpwsTerrFault.clearFlag == 0 and warningNodes.Timers.navTerrFault.getValue() == 1 and (phaseVar2 == 2 or phaseVar2 == 6 or phaseVar2 == 7 or phaseVar2 == 9)) {
		gpwsTerrFault.active = 1;
		
		if (gpwsTerrFaultOff.clearFlag == 0 and !getprop("/instrumentation/mk-viii/inputs/discretes/ta-tcf-inhibit")) {
			gpwsTerrFaultOff.active = 1;
		} else {
			ECAM_controller.warningReset(gpwsTerrFaultOff);
		}
	} else {
		ECAM_controller.warningReset(gpwsTerrFault);
		ECAM_controller.warningReset(gpwsTerrFaultOff);
	}
	
	if (fac12Fault.clearFlag == 0 and phaseVar2 != 4 and phaseVar2 != 5 and phaseVar2 != 7 and phaseVar2 != 8 and warningNodes.Logic.fac12Fault.getBoolValue()) {
		fac12Fault.active = 1;
		fac12FaultRud.active = 1;
		fac12FaultFac.active = 1;
		fac12FaultSuccess.active = 1;
		fac12FaultFacOff.active = 1;
	} else {
		ECAM_controller.warningReset(fac12Fault);
		ECAM_controller.warningReset(fac12FaultRud);
		ECAM_controller.warningReset(fac12FaultFac);
		ECAM_controller.warningReset(fac12FaultSuccess);
		ECAM_controller.warningReset(fac12FaultFacOff);
	}
	
	if (yawDamperSysFault.clearFlag == 0 and phaseVar2 != 4 and phaseVar2 != 5 and phaseVar2 != 7 and phaseVar2 != 8 and phaseVar2 != 10 and warningNodes.Logic.yawDamper12Fault.getBoolValue()) {
		yawDamperSysFault.active = 1;
		yawDamperSysFaultFac1.active = 1;
		yawDamperSysFaultFac2.active = 1;
	} else {
		ECAM_controller.warningReset(yawDamperSysFault);
		ECAM_controller.warningReset(yawDamperSysFaultFac1);
		ECAM_controller.warningReset(yawDamperSysFaultFac2);
	}
	
	if (rudTravLimSysFault.clearFlag == 0 and phaseVar2 != 4 and phaseVar2 != 5 and phaseVar2 != 7 and phaseVar2 != 8 and warningNodes.Logic.rtlu12Fault.getBoolValue()) {
		rudTravLimSysFault.active = 1;
		rudTravLimSysFaultRud.active = 1;
		rudTravLimSysFaultFac.active = 1;
	} else {
		ECAM_controller.warningReset(rudTravLimSysFault);
		ECAM_controller.warningReset(rudTravLimSysFaultRud);
		ECAM_controller.warningReset(rudTravLimSysFaultFac);
	}
	
	if (fac1Fault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Logic.fac1Fault.getBoolValue()) {
		fac1Fault.active = 1;
		fac1FaultFac.active = 1;
		fac1FaultSuccess.active = 1;
		fac1FaultFacOff.active = 1;
	} else {
		ECAM_controller.warningReset(fac1Fault);
		ECAM_controller.warningReset(fac1FaultFac);
		ECAM_controller.warningReset(fac1FaultSuccess);
		ECAM_controller.warningReset(fac1FaultFacOff);
	}
	
	if (fac2Fault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Logic.fac2Fault.getBoolValue()) {
		fac2Fault.active = 1;
		fac2FaultFac.active = 1;
		fac2FaultSuccess.active = 1;
		fac2FaultFacOff.active = 1;
	} else {
		ECAM_controller.warningReset(fac2Fault);
		ECAM_controller.warningReset(fac2FaultFac);
		ECAM_controller.warningReset(fac2FaultSuccess);
		ECAM_controller.warningReset(fac2FaultFacOff);
	}
	
	if (yawDamper1Fault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 == 9 or phaseVar2 == 6) and warningNodes.Timers.yawDamper1Fault.getValue() == 1 and !warningNodes.Logic.yawDamper12Fault.getBoolValue()) {
		yawDamper1Fault.active = 1;
	} else {
		ECAM_controller.warningReset(yawDamper1Fault);
	}
	
	if (yawDamper2Fault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 == 9 or phaseVar2 == 6) and warningNodes.Timers.yawDamper2Fault.getValue() == 1 and !warningNodes.Logic.yawDamper12Fault.getBoolValue()) {
		yawDamper2Fault.active = 1;
	} else {
		ECAM_controller.warningReset(yawDamper2Fault);
	}
	
	if (rudTravLimSys1Fault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Logic.rtlu1Fault.getBoolValue()) {
		rudTravLimSys1Fault.active = 1;
	} else {
		ECAM_controller.warningReset(rudTravLimSys1Fault);
	}
	
	if (rudTravLimSys2Fault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Logic.rtlu2Fault.getBoolValue()) {
		rudTravLimSys2Fault.active = 1;
	} else {
		ECAM_controller.warningReset(rudTravLimSys2Fault);
	}
	
	if (fcu.FCUController.FCU1.failed and fcu.FCUController.FCU2.failed and systems.ELEC.Bus.dcEss.getValue() >= 25 and systems.ELEC.Bus.dcEss.getValue() >= 25 and fcuFault.clearFlag == 0) {
		fcuFault.active = 1;
		fcuFaultBaro.active = 1;
	} else {
		ECAM_controller.warningReset(fcuFault);
		ECAM_controller.warningReset(fcuFaultBaro);
	}
	
	if (fcu.FCUController.FCU1.failed and !fcu.FCUController.FCU2.failed and systems.ELEC.Bus.dcEss.getValue() >= 25 and fcuFault1.clearFlag == 0) {
		fcuFault1.active = 1;
		fcuFault1Baro.active = 1;
	} else {
		ECAM_controller.warningReset(fcuFault1);
		ECAM_controller.warningReset(fcuFault1Baro);
	}
	
	if (fcu.FCUController.FCU2.failed and !fcu.FCUController.FCU1.failed and systems.ELEC.Bus.dc2.getValue() >= 25 and fcuFault2.clearFlag == 0) {
		fcuFault2.active = 1;
		fcuFault2Baro.active = 1;
	} else {
		ECAM_controller.warningReset(fcuFault2);
		ECAM_controller.warningReset(fcuFault2Baro);
	}
	
	# FUEL
	if (wingLoLvl.clearFlag == 0 and warningNodes.Timers.lowLevelBoth.getValue() == 1 and (phaseVar2 <= 2 or phaseVar2 == 6 or phaseVar2 >= 9)) {
		wingLoLvl.active = 1;
		
		if (wingLoLvlManMode.clearFlag == 0 and systems.FUEL.Switches.centerTkMode.getValue() == 0 and systems.FUEL.Quantity.center.getValue() >= 550) {
			wingLoLvlManMode.active = 1;
		} else {
			ECAM_controller.warningReset(wingLoLvlManMode);
		}
		
		if (wingLoLvlPumpL1.clearFlag == 0 and !systems.FUEL.Switches.pumpLeft1.getValue()) {
			wingLoLvlPumpL1.active = 1;
		} else {
			ECAM_controller.warningReset(wingLoLvlPumpL1);
		}
		
		if (wingLoLvlPumpL2.clearFlag == 0 and !systems.FUEL.Switches.pumpLeft2.getValue()) {
			wingLoLvlPumpL2.active = 1;
		} else {
			ECAM_controller.warningReset(wingLoLvlPumpL2);
		}
		
		if (wingLoLvlPumpC1.clearFlag == 0 and !systems.FUEL.Switches.pumpCenter1.getValue()) {
			wingLoLvlPumpC1.active = 1;
		} else {
			ECAM_controller.warningReset(wingLoLvlPumpC1);
		}
		
		if (wingLoLvlPumpR1.clearFlag == 0 and !systems.FUEL.Switches.pumpRight1.getValue()) {
			wingLoLvlPumpR1.active = 1;
		} else {
			ECAM_controller.warningReset(wingLoLvlPumpR1);
		}
		
		if (wingLoLvlPumpR2.clearFlag == 0 and !systems.FUEL.Switches.pumpRight2.getValue()) {
			wingLoLvlPumpR2.active = 1;
		} else {
			ECAM_controller.warningReset(wingLoLvlPumpR2);
		}
		
		if (wingLoLvlPumpC2.clearFlag == 0 and !systems.FUEL.Switches.pumpCenter2.getValue()) {
			wingLoLvlPumpC2.active = 1;
		} else {
			ECAM_controller.warningReset(wingLoLvlPumpC2);
		}
		
		if (systems.FUEL.Switches.crossfeed.getValue() == 0) {
			if (wingLoLvlLeak.clearFlag == 0) {
				wingLoLvlLeak.active = 1;
			} else {
				ECAM_controller.warningReset(wingLoLvlLeak);
			}
			
			if (wingLoLvlXFeed.clearFlag == 0) {
				wingLoLvlXFeed.active = 1;
			} else {
				ECAM_controller.warningReset(wingLoLvlXFeed);
			}
		} else {
			ECAM_controller.warningReset(wingLoLvlLeak);
			ECAM_controller.warningReset(wingLoLvlXFeed);
		}
		
		if (systems.FUEL.Switches.crossfeed.getValue() == 1) {
			if (wingLoLvlGrav.clearFlag == 0) {
				wingLoLvlGrav.active = 1;
			} else {
				ECAM_controller.warningReset(wingLoLvlGrav);
			}
			
			if (wingLoLvlXFeedOff.clearFlag == 0) {
				wingLoLvlXFeedOff.active = 1;
			} else {
				ECAM_controller.warningReset(wingLoLvlXFeedOff);
			}
		} else {
			ECAM_controller.warningReset(wingLoLvlGrav);
			ECAM_controller.warningReset(wingLoLvlXFeedOff);
		}
	} else {
		ECAM_controller.warningReset(wingLoLvl);
		ECAM_controller.warningReset(wingLoLvlManMode);
		ECAM_controller.warningReset(wingLoLvlPumpL1);
		ECAM_controller.warningReset(wingLoLvlPumpL2);
		ECAM_controller.warningReset(wingLoLvlPumpC1);
		ECAM_controller.warningReset(wingLoLvlPumpR1);
		ECAM_controller.warningReset(wingLoLvlPumpR2);
		ECAM_controller.warningReset(wingLoLvlPumpC2);
		ECAM_controller.warningReset(wingLoLvlLeak);
		ECAM_controller.warningReset(wingLoLvlXFeed);
		ECAM_controller.warningReset(wingLoLvlGrav);
		ECAM_controller.warningReset(wingLoLvlXFeedOff);
	}
	
	if (ctrPumpsOff.clearFlag == 0 and warningNodes.Timers.centerPumpsOff.getValue() == 1 and (phaseVar2 == 2 or phaseVar2 == 6)) {
		ctrPumpsOff.active = 1;
		
		if (ctrPumpsOffPump1.clearFlag == 0 and !systems.FUEL.Switches.pumpCenter1.getValue()) {
			ctrPumpsOffPump1.active = 1;
		} else {
			ECAM_controller.warningReset(ctrPumpsOffPump1);
		}
		if (ctrPumpsOffPump2.clearFlag == 0 and !systems.FUEL.Switches.pumpCenter2.getValue()) {
			ctrPumpsOffPump2.active = 1;
		} else {
			ECAM_controller.warningReset(ctrPumpsOffPump2);
		}
	} else {
		ECAM_controller.warningReset(ctrPumpsOff);
		ECAM_controller.warningReset(ctrPumpsOffPump1);
		ECAM_controller.warningReset(ctrPumpsOffPump2);
	}
	
	# APU EMER SHUT DOWN
	if (apuEmerShutdown.clearFlag == 0 and systems.APUController.APU.signals.autoshutdown and systems.APUController.APU.signals.emer and !getprop("/systems/fire/apu/warning-active") and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		apuEmerShutdown.active = 1;
	} elsif (apuEmerShutdown.clearFlag == 1) {
		ECAM_controller.warningReset(apuEmerShutdown);
	}
	
	if (apuEmerShutdownMast.clearFlag == 0 and systems.APUNodes.Controls.master.getBoolValue() and apuEmerShutdown.active == 1) {
		apuEmerShutdownMast.active = 1;
	} else {
		ECAM_controller.warningReset(apuEmerShutdownMast);
	}
	
	# APU AUTO SHUT DOWN
	if (apuAutoShutdown.clearFlag == 0 and systems.APUController.APU.signals.autoshutdown and !systems.APUController.APU.signals.emer and !getprop("/systems/fire/apu/warning-active") and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		apuAutoShutdown.active = 1;
	} elsif (apuAutoShutdown.clearFlag == 1) {
		ECAM_controller.warningReset(apuAutoShutdown);
	}
	
	if (apuAutoShutdownMast.clearFlag == 0 and systems.APUNodes.Controls.master.getValue() and apuAutoShutdown.active == 1) {
		apuAutoShutdownMast.active = 1;
	} else {
		ECAM_controller.warningReset(apuAutoShutdownMast);
	}
	
	# Bleed
	# BLEED 1 FAULT
	if ((FWC.Timer.eng1idleOutput.getBoolValue() == 1 and !pts.Controls.Engines.Engine.cutoffSw[0].getValue()) and (systems.PNEU.Warnings.overpress1.getValue() or systems.PNEU.Warnings.ovht1.getValue())) {
		warningNodes.Timers.bleed1Fault.setValue(1);
	} else {
		warningNodes.Timers.bleed1Fault.setValue(0);
	}
	
	if (bleed1Fault.clearFlag == 0 and (phaseVar2 == 2 or phaseVar2 == 6 or phaseVar2 == 9) and warningNodes.Timers.bleed1FaultOutput.getValue() == 1 and (!systems.PNEU.Switch.pack1.getBoolValue() or !systems.PNEU.Switch.pack2.getBoolValue() or !(getprop("/ECAM/phases/wing-anti-ice-pulse") and wing_pb.getValue()))) { # inverse pulse
		bleed1Fault.active = 1;
	} else {
		ECAM_controller.warningReset(bleed1Fault);
	}
	
	if (bleed1Fault.active) {
		if (bleed1FaultOff.clearFlag == 0 and systems.PNEU.Switch.bleed1.getBoolValue() and systems.PNEU.Warnings.prv1Disag.getValue()) {
			bleed1FaultOff.active = 1;
		} else {
			ECAM_controller.warningReset(bleed1FaultOff);
		}
		
		if (bleed1FaultPack.clearFlag == 0 and systems.PNEU.Switch.pack1.getBoolValue() and systems.PNEU.Switch.pack2.getBoolValue() and getprop("/ECAM/warnings/logic/wai-on")) {
			bleed1FaultPack.active = 1;
		} else {
			ECAM_controller.warningReset(bleed1FaultPack);
		}
		
		if (bleed1FaultXBleed.clearFlag == 0 and systems.PNEU.Valves.crossbleed.getValue() == 0) {
			bleed1FaultXBleed.active = 1;
		} else {
			ECAM_controller.warningReset(bleed1FaultXBleed);
		}
	} else {
		ECAM_controller.warningReset(bleed1FaultOff);
		ECAM_controller.warningReset(bleed1FaultPack);
		ECAM_controller.warningReset(bleed1FaultXBleed);
	}
	
	# BLEED 2 FAULT
	if ((FWC.Timer.eng2idleOutput.getBoolValue() == 1 and !pts.Controls.Engines.Engine.cutoffSw[1].getValue()) and (systems.PNEU.Warnings.overpress2.getValue() or systems.PNEU.Warnings.ovht2.getValue())) {
		warningNodes.Timers.bleed2Fault.setValue(1);
	} else {
		warningNodes.Timers.bleed2Fault.setValue(0);
	}
	
	if (bleed2Fault.clearFlag == 0 and (phaseVar2 == 2 or phaseVar2 == 6 or phaseVar2 == 9) and warningNodes.Timers.bleed2FaultOutput.getValue() == 1 and (!systems.PNEU.Switch.pack1.getBoolValue() or !systems.PNEU.Switch.pack2.getBoolValue() or !(getprop("/ECAM/phases/wing-anti-ice-pulse") and wing_pb.getValue()))) { # inverse pulse
		bleed2Fault.active = 1;
	} else {
		ECAM_controller.warningReset(bleed2Fault);
	}
	
	if (bleed2Fault.active) {
		if (bleed2FaultOff.clearFlag == 0 and systems.PNEU.Switch.bleed2.getBoolValue() and systems.PNEU.Warnings.prv2Disag.getValue()) {
			bleed2FaultOff.active = 1;
		} else {
			ECAM_controller.warningReset(bleed2FaultOff);
		}
		
		if (bleed2FaultPack.clearFlag == 0 and systems.PNEU.Switch.pack1.getValue() and systems.PNEU.Switch.pack2.getValue() and getprop("/ECAM/warnings/logic/wai-on")) {
			bleed2FaultPack.active = 1;
		} else {
			ECAM_controller.warningReset(bleed2FaultPack);
		}
		
		if (bleed2FaultXBleed.clearFlag == 0 and systems.PNEU.Valves.crossbleed.getValue() == 0) {
			bleed2FaultXBleed.active = 1;
		} else {
			ECAM_controller.warningReset(bleed2FaultXBleed);
		}
	} else {
		ECAM_controller.warningReset(bleed2FaultOff);
		ECAM_controller.warningReset(bleed2FaultPack);
		ECAM_controller.warningReset(bleed2FaultXBleed);
	}
	
	if (apuBleedFault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Timers.apuFaultOutput.getValue() == 1) {
		apuBleedFault.active = 1;
	} else {
		ECAM_controller.warningReset(apuBleedFault);
	}
	
	# HP Valves
	if (hpValve1Fault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and systems.PNEU.Fail.hp1Valve.getValue() and systems.ELEC.Bus.dcEssShed.getValue() >= 25) {
		hpValve1Fault.active = 1;
	} else {
		ECAM_controller.warningReset(hpValve1Fault);
	}
	
	if (hpValve2Fault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and systems.PNEU.Fail.hp2Valve.getValue() and systems.ELEC.Bus.dc2.getValue() >= 25) {
		hpValve2Fault.active = 1;
	} else {
		ECAM_controller.warningReset(hpValve2Fault);
	}
	
	# Crossbleed
	if (xBleedFault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Logic.crossbleedFault.getValue()) {
		xBleedFault.active = 1;
		
		if (xBleedFaultMan.clearFlag == 0 and systems.PNEU.Switch.xbleed.getValue() == 1) {
			xBleedFaultMan.active = 1;
		} else {
			ECAM_controller.warningReset(xBleedFaultMan);
		}
		
		if (xBleedFaultWAI.clearFlag == 0 and wing_pb.getValue() and warningNodes.Logic.crossbleedWai.getValue()) {
			xBleedFaultWAI.active = 1;
		} else {
			ECAM_controller.warningReset(xBleedFaultWAI);
		}
		
		if (xBleedFaultICE.clearFlag == 0 and warningNodes.Logic.crossbleedWai.getValue()) {
			xBleedFaultICE.active = 1;
		} else {
			ECAM_controller.warningReset(xBleedFaultICE);
		}
	} else {
		ECAM_controller.warningReset(xBleedFault);
		ECAM_controller.warningReset(xBleedFaultMan);
		ECAM_controller.warningReset(xBleedFaultWAI);
		ECAM_controller.warningReset(xBleedFaultICE);
	}
	
	if (bleed1Off.clearFlag == 0 and (warningNodes.Timers.bleed1Off60Output.getValue() == 1 or warningNodes.Timers.bleed1Off5Output.getValue() == 1) and FWC.Timer.eng1idleOutput.getBoolValue() and (phaseVar2 == 2 or phaseVar2 == 6)) {
		bleed1Off.active = 1;
	} else {
		ECAM_controller.warningReset(bleed1Off);
	}
	
	if (bleed2Off.clearFlag == 0 and (warningNodes.Timers.bleed2Off60Output.getValue() == 1 or warningNodes.Timers.bleed2Off5Output.getValue() == 1) and FWC.Timer.eng2idleOutput.getBoolValue() and (phaseVar2 == 2 or phaseVar2 == 6)) {
		bleed2Off.active = 1;
	} else {
		ECAM_controller.warningReset(bleed2Off);
	}
	
	if (warningNodes.Flipflops.bleed1LowTemp.getValue() and warningNodes.Flipflops.bleed2LowTemp.getValue()) {
		warningNodes.Timers.bleed1And2LoTemp.setValue(1);
	} else {
		warningNodes.Timers.bleed1And2LoTemp.setValue(0);
	}	
	
	if (engBleedLowTemp.clearFlag == 0 and warningNodes.Timers.bleed1And2LoTempOutput.getValue() == 1 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6 or phaseVar2 == 7)) {
		engBleedLowTemp.active = 1;
		
		if (engBleedLowTempAthr.clearFlag == 0 and fmgc.Output.athr.getValue()) {
			engBleedLowTempAthr.active = 1;
		} else {
			ECAM_controller.warningReset(engBleedLowTempAthr);
		}
		
		if (engBleedLowTempAdv.clearFlag == 0) {
			engBleedLowTempAdv.active = 1;
		} else {
			ECAM_controller.warningReset(engBleedLowTempAdv);
		}
		
		if (engBleedLowTempSucc.clearFlag == 0) {
			engBleedLowTempSucc.active = 1;
		} else {
			ECAM_controller.warningReset(engBleedLowTempSucc);
		}
		
		if (engBleedLowTempIce.clearFlag == 0) {
			engBleedLowTempIce.active = 1;
		} else {
			ECAM_controller.warningReset(engBleedLowTempIce);
		}
		
		if (engBleedLowTempIcing.clearFlag == 0) {
			engBleedLowTempIcing.active = 1;
		} else {
			ECAM_controller.warningReset(engBleedLowTempIcing);
		}
	} else {
		ECAM_controller.warningReset(engBleedLowTemp);
		ECAM_controller.warningReset(engBleedLowTempAthr);
		ECAM_controller.warningReset(engBleedLowTempAdv);
		ECAM_controller.warningReset(engBleedLowTempSucc);
		ECAM_controller.warningReset(engBleedLowTempIce);
		ECAM_controller.warningReset(engBleedLowTempIcing);
	}
	
	if (eng1BleedLowTemp.clearFlag == 0 and warningNodes.Flipflops.bleed1LowTemp.getValue() == 1 and warningNodes.Flipflops.bleed2LowTemp.getValue() == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6 or phaseVar2 == 7)) {
		eng1BleedLowTemp.active = 1;
		
		if (eng1BleedLowTempAthr.clearFlag == 0 and fmgc.Output.athr.getValue()) {
			eng1BleedLowTempAthr.active = 1;
		} else {
			ECAM_controller.warningReset(eng1BleedLowTempAthr);
		}
		
		if (eng1BleedLowTempAdv.clearFlag == 0) {
			eng1BleedLowTempAdv.active = 1;
		} else {
			ECAM_controller.warningReset(eng1BleedLowTempAdv);
		}
		
		if (eng1BleedLowTempSucc.clearFlag == 0 and warningNodes.Logic.bleed1LoTempUnsuc.getValue()) {
			eng1BleedLowTempSucc.active = 1;
		} else {	
			ECAM_controller.warningReset(eng1BleedLowTempSucc);
		}
		
		if (eng1BleedLowTempXBld.clearFlag == 0 and warningNodes.Logic.bleed1LoTempXbleed.getValue()) {
			eng1BleedLowTempXBld.active = 1;
		} else {	
			ECAM_controller.warningReset(eng1BleedLowTempXBld);
		}
		
		if (eng1BleedLowTempOff.clearFlag == 0 and warningNodes.Logic.bleed1LoTempBleed.getValue()) {
			eng1BleedLowTempOff.active = 1;
		} else {	
			ECAM_controller.warningReset(eng1BleedLowTempOff);
		}
		
		if (eng1BleedLowTempPack.clearFlag == 0 and warningNodes.Logic.bleed1LoTempPack.getValue()) {
			eng1BleedLowTempPack.active = 1;
		} else {	
			ECAM_controller.warningReset(eng1BleedLowTempPack);
		}
		
		if (eng1BleedLowTempIce.clearFlag == 0 and !warningNodes.Logic.bleed2WaiAvail.getValue()) { # on purpose
			eng1BleedLowTempIce.active = 1;
			eng1BleedLowTempIcing.active = 1;
		} else {
			ECAM_controller.warningReset(eng1BleedLowTempIce);
			ECAM_controller.warningReset(eng1BleedLowTempIcing);
		}
	} else {
		ECAM_controller.warningReset(eng1BleedLowTemp);
		ECAM_controller.warningReset(eng1BleedLowTempAthr);
		ECAM_controller.warningReset(eng1BleedLowTempAdv);
		ECAM_controller.warningReset(eng1BleedLowTempSucc);
		ECAM_controller.warningReset(eng1BleedLowTempXBld);
		ECAM_controller.warningReset(eng1BleedLowTempOff);
		ECAM_controller.warningReset(eng1BleedLowTempPack);
		ECAM_controller.warningReset(eng1BleedLowTempIce);
		ECAM_controller.warningReset(eng1BleedLowTempIcing);
	}
	
	if (eng2BleedLowTemp.clearFlag == 0 and warningNodes.Flipflops.bleed1LowTemp.getValue() == 0 and warningNodes.Flipflops.bleed2LowTemp.getValue() == 1 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6 or phaseVar2 == 7)) {
		eng2BleedLowTemp.active = 1;
		
		if (eng2BleedLowTempAthr.clearFlag == 0 and fmgc.Output.athr.getValue()) {
			eng2BleedLowTempAthr.active = 1;
		} else {
			ECAM_controller.warningReset(eng2BleedLowTempAthr);
		}
		
		if (eng2BleedLowTempAdv.clearFlag == 0) {
			eng2BleedLowTempAdv.active = 1;
		} else {
			ECAM_controller.warningReset(eng2BleedLowTempAdv);
		}
		
		if (eng2BleedLowTempSucc.clearFlag == 0 and warningNodes.Logic.bleed2LoTempUnsuc.getValue()) {
			eng2BleedLowTempSucc.active = 1;
		} else {	
			ECAM_controller.warningReset(eng2BleedLowTempSucc);
		}
		
		if (eng2BleedLowTempXBld.clearFlag == 0 and warningNodes.Logic.bleed2LoTempXbleed.getValue()) {
			eng2BleedLowTempXBld.active = 1;
		} else {	
			ECAM_controller.warningReset(eng2BleedLowTempXBld);
		}
		
		if (eng2BleedLowTempOff.clearFlag == 0 and warningNodes.Logic.bleed2LoTempBleed.getValue()) {
			eng2BleedLowTempOff.active = 1;
		} else {	
			ECAM_controller.warningReset(eng2BleedLowTempOff);
		}
		
		if (eng2BleedLowTempPack.clearFlag == 0 and warningNodes.Logic.bleed2LoTempPack.getValue()) {
			eng2BleedLowTempPack.active = 1;
		} else {	
			ECAM_controller.warningReset(eng2BleedLowTempPack);
		}
		
		if (eng2BleedLowTempIce.clearFlag == 0 and !warningNodes.Logic.bleed1WaiAvail.getValue()) { # on purpose
			eng2BleedLowTempIce.active = 1;
			eng2BleedLowTempIcing.active = 1;
		} else {
			ECAM_controller.warningReset(eng2BleedLowTempIce);
			ECAM_controller.warningReset(eng2BleedLowTempIcing);
		}
	} else {
		ECAM_controller.warningReset(eng2BleedLowTemp);
		ECAM_controller.warningReset(eng2BleedLowTempAthr);
		ECAM_controller.warningReset(eng2BleedLowTempAdv);
		ECAM_controller.warningReset(eng2BleedLowTempSucc);
		ECAM_controller.warningReset(eng2BleedLowTempXBld);
		ECAM_controller.warningReset(eng2BleedLowTempOff);
		ECAM_controller.warningReset(eng2BleedLowTempPack);
		ECAM_controller.warningReset(eng2BleedLowTempIce);
		ECAM_controller.warningReset(eng2BleedLowTempIcing);
	}
	
	if (eng1BleedNotClsd.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Timers.bleed1NotShutOutput.getValue() == 1) {
		eng1BleedNotClsd.active = 1;
		if (systems.PNEU.Switch.bleed1.getBoolValue()) {
			eng1BleedNotClsdOff.active = 1;
		} else {
			ECAM_controller.warningReset(eng1BleedNotClsdOff);
		}
	} else {
		ECAM_controller.warningReset(eng1BleedNotClsd);
		ECAM_controller.warningReset(eng1BleedNotClsdOff);
	}
	
	if (eng2BleedNotClsd.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Timers.bleed2NotShutOutput.getValue() == 1) {
		eng2BleedNotClsd.active = 1;
		if (systems.PNEU.Switch.bleed2.getBoolValue()) {
			eng2BleedNotClsdOff.active = 1;
		} else {
			ECAM_controller.warningReset(eng2BleedNotClsdOff);
		}
	} else {
		ECAM_controller.warningReset(eng2BleedNotClsd);
		ECAM_controller.warningReset(eng2BleedNotClsdOff);
	}
	
	# BMC
	if (bleedMonFault.clearFlag == 0 and systems.PNEU.Fail.bmc1.getValue() and systems.PNEU.Fail.bmc2.getValue() and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6)) {
		bleedMonFault.active = 1;
	} else {
		ECAM_controller.warningReset(bleedMonFault);
	}
	
	if (bleedMon1Fault.clearFlag == 0 and systems.PNEU.Fail.bmc1.getValue() and !systems.PNEU.Fail.bmc2.getValue() and (phaseVar2 <= 2 or phaseVar2 >= 9)) {
		bleedMon1Fault.active = 1;
	} else {
		ECAM_controller.warningReset(bleedMon1Fault);
	}
	
	if (bleedMon2Fault.clearFlag == 0 and !systems.PNEU.Fail.bmc1.getValue() and systems.PNEU.Fail.bmc2.getValue() and (phaseVar2 <= 2 or phaseVar2 >= 9)) {
		bleedMon2Fault.active = 1;
	} else {
		ECAM_controller.warningReset(bleedMon2Fault);
	}
	
	# PACK
	if (pack12Fault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Logic.pack12Fault.getValue()) { # TODO NOT OUTFLOW OR HOT AIR FAULT
		pack12Fault.active = 1;
		
		if (systems.PNEU.Switch.pack1.getBoolValue()) {
			pack12FaultPackOff1.active = 1;
		} else {
			ECAM_controller.warningReset(pack12FaultPackOff1);
		}
		
		if (systems.PNEU.Switch.pack2.getBoolValue()) {
			pack12FaultPackOff2.active = 1;
		} else {
			ECAM_controller.warningReset(pack12FaultPackOff2);
		}
		
		if (!systems.PNEU.Switch.ramAir.getBoolValue() and !FWC.Timer.gnd.getValue() != 1 and pts.Instrumentation.Altimeter.indicatedFt.getValue() >= 16000) {
			pack12FaultDescend.active = 1;
		} else {
			ECAM_controller.warningReset(pack12FaultDescend);
		}
		
		if (!systems.PNEU.Switch.ramAir.getBoolValue() and FWC.Timer.gnd.getValue() != 1) {
			pack12FaultDiffPr.active = 1;
			pack12FaultDiffPr2.active = 1;
			pack12FaultRam.active = 1;
		} else {
			ECAM_controller.warningReset(pack12FaultDiffPr);
			ECAM_controller.warningReset(pack12FaultDiffPr2);
			ECAM_controller.warningReset(pack12FaultRam);
		}
		
		if (FWC.Timer.gnd.getValue() != 1) {
			pack12FaultMax.active = 1;
		} else {
			ECAM_controller.warningReset(pack12FaultMax);
		}
		
		if (warningNodes.Logic.pack1ResetPb.getBoolValue() or warningNodes.Logic.pack2ResetPb.getBoolValue()) {
			pack12FaultOvht.active = 1;
			
			if (warningNodes.Logic.pack1ResetPb.getBoolValue()) {
				pack12FaultPackOn1.active = 1;
			} else {
				ECAM_controller.warningReset(pack12FaultPackOn1);
			}
			
			if (warningNodes.Logic.pack2ResetPb.getBoolValue()) {
				pack12FaultPackOn2.active = 1;
			} else {
				ECAM_controller.warningReset(pack12FaultPackOn2);
			}
		} else {
			ECAM_controller.warningReset(pack12FaultOvht);
			ECAM_controller.warningReset(pack12FaultPackOn1);
			ECAM_controller.warningReset(pack12FaultPackOn2);
		}
	} else {
		ECAM_controller.warningReset(pack12Fault);
		ECAM_controller.warningReset(pack12FaultPackOff1);
		ECAM_controller.warningReset(pack12FaultPackOff2);
		ECAM_controller.warningReset(pack12FaultDescend);
		ECAM_controller.warningReset(pack12FaultDiffPr);
		ECAM_controller.warningReset(pack12FaultDiffPr2);
		ECAM_controller.warningReset(pack12FaultRam);
		ECAM_controller.warningReset(pack12FaultMax);
		ECAM_controller.warningReset(pack12FaultOvht);
		ECAM_controller.warningReset(pack12FaultPackOn1);
		ECAM_controller.warningReset(pack12FaultPackOn2);
	}
	
	if (pack1Ovht.clearFlag == 0 and (phaseVar2 <= 2  or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Flipflops.pack1Ovht.getValue()) {
		pack1Ovht.active = 1;
		
		if (systems.PNEU.Switch.pack1.getBoolValue()) {
			pack1OvhtOff.active = 1;
		} else {
			ECAM_controller.warningReset(pack1OvhtOff);
		}
		
		pack1OvhtOut.active = 1;
		pack1OvhtPack.active = 1;
	} else {
		ECAM_controller.warningReset(pack1Ovht);
		ECAM_controller.warningReset(pack1OvhtOff);
		ECAM_controller.warningReset(pack1OvhtOut);
		ECAM_controller.warningReset(pack1OvhtPack);
	}
	
	if (pack2Ovht.clearFlag == 0 and (phaseVar2 <= 2  or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Flipflops.pack2Ovht.getValue()) {
		pack2Ovht.active = 1;
		
		if (systems.PNEU.Switch.pack2.getBoolValue()) {
			pack2OvhtOff.active = 1;
		} else {
			ECAM_controller.warningReset(pack2OvhtOff);
		}
		
		pack2OvhtOut.active = 1;
		pack2OvhtPack.active = 1;
	} else {
		ECAM_controller.warningReset(pack2Ovht);
		ECAM_controller.warningReset(pack2OvhtOff);
		ECAM_controller.warningReset(pack2OvhtOut);
		ECAM_controller.warningReset(pack2OvhtPack);
	}
	
	if (pack1Fault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Timers.pack1Fault.getValue() == 1) {
		pack1Fault.active = 1;
		
		if (systems.PNEU.Switch.pack1.getBoolValue()) {
			pack1FaultOff.active = 1;
		} else {
			ECAM_controller.warningReset(pack1FaultOff);
		}
	} else {
		ECAM_controller.warningReset(pack1Fault);
		ECAM_controller.warningReset(pack1FaultOff);
	}
	
	if (pack2Fault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Timers.pack2Fault.getValue() == 1) {
		pack2Fault.active = 1;
		
		if (systems.PNEU.Switch.pack2.getBoolValue()) {
			pack2FaultOff.active = 1;
		} else {
			ECAM_controller.warningReset(pack2FaultOff);
		}
	} else {
		ECAM_controller.warningReset(pack2Fault);
		ECAM_controller.warningReset(pack2FaultOff);
	}
	
	if (pack1Off.clearFlag == 0 and phaseVar2 == 6 and warningNodes.Timers.pack1Off.getValue() == 1) {
		pack1Off.active = 1;
	} else {
		ECAM_controller.warningReset(pack1Off);
	}
	
	if (pack2Off.clearFlag == 0 and phaseVar2 == 6 and warningNodes.Timers.pack2Off.getValue() == 1) {
		pack2Off.active = 1;
	} else {
		ECAM_controller.warningReset(pack2Off);
	}
	
	# COND
	if (cabFanFault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Logic.cabinFans.getBoolValue()) {
		cabFanFault.active = 1;
		cabFanFaultFlow.active = 1;
	} else {
		ECAM_controller.warningReset(cabFanFault);
		ECAM_controller.warningReset(cabFanFaultFlow);
	}
	
	if (trimAirFault.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Timers.trimAirFault.getValue() == 1) {
		trimAirFault.active = 1;
		
		if (systems.PNEU.Fail.trimValveAft.getBoolValue()) {
			trimAirFaultAft.active = 1; 
		} else {
			ECAM_controller.warningReset(trimAirFaultAft);
		}
		
		if (systems.PNEU.Fail.trimValveFwd.getBoolValue()) {
			trimAirFaultFwd.active = 1; 
		} else {
			ECAM_controller.warningReset(trimAirFaultFwd);
		}
		
		if (systems.PNEU.Fail.trimValveCockpit.getBoolValue()) {
			trimAirFaultCkpt.active = 1; 
		} else {
			ECAM_controller.warningReset(trimAirFaultCkpt);
		}
	} else {
		ECAM_controller.warningReset(trimAirFault);
		ECAM_controller.warningReset(trimAirFaultAft);
		ECAM_controller.warningReset(trimAirFaultFwd);
		ECAM_controller.warningReset(trimAirFaultCkpt);
	}
	
	# ENG AICE
	if (eng1IceClosed.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Timers.eng1AiceNotOpen.getValue() == 1) {
		eng1IceClosed.active = 1;
		eng1IceClosedIcing.active = 1;
	} else {
		ECAM_controller.warningReset(eng1IceClosed);
		ECAM_controller.warningReset(eng1IceClosedIcing);
	}
	
	if (eng2IceClosed.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Timers.eng2AiceNotOpen.getValue() == 1) {
		eng2IceClosed.active = 1;
		eng2IceClosedIcing.active = 1;
	} else {
		ECAM_controller.warningReset(eng2IceClosed);
		ECAM_controller.warningReset(eng2IceClosedIcing);
	}
	
	if (eng1IceOpen.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Timers.eng1AiceNotClsd.getValue() == 1) {
		eng1IceOpen.active = 1;
		eng1IceOpenThrust.active = 1;
	} else {
		ECAM_controller.warningReset(eng1IceOpen);
		ECAM_controller.warningReset(eng1IceOpenThrust);
	}
	
	if (eng2IceOpen.clearFlag == 0 and (phaseVar2 <= 2 or phaseVar2 >= 9 or phaseVar2 == 6) and warningNodes.Timers.eng2AiceNotClsd.getValue() == 1) {
		eng2IceOpen.active = 1;
		eng2IceOpenThrust.active = 1;
	} else {
		ECAM_controller.warningReset(eng2IceOpen);
		ECAM_controller.warningReset(eng2IceOpenThrust);
	}
	
	# Wing anti ice
	if (wingIceSysFault.clearFlag == 0 and warningNodes.Logic.waiSysfault.getBoolValue() and (phaseVar2 <= 2  or phaseVar2 >= 9 or phaseVar2 == 6)) {
		wingIceSysFault.active = 1;
		
		if ((warningNodes.Logic.waiLclosed.getValue() or warningNodes.Logic.waiRclosed.getValue()) and warningNodes.Logic.procWaiShutdown.getValue() == 1) {
			wingIceSysFaultXbld.active = 1;
		} else {
			ECAM_controller.warningReset(wingIceSysFaultXbld);
		}
		if ((warningNodes.Logic.waiLclosed.getValue() or warningNodes.Logic.waiRclosed.getValue()) and wing_pb.getValue()) {
			wingIceSysFaultOff.active = 1;
		} else {
			ECAM_controller.warningReset(wingIceSysFaultOff);
		}
		
		if (warningNodes.Logic.waiLclosed.getValue() or warningNodes.Logic.waiRclosed.getValue()) {
			wingIceSysFaultIcing.active = 1;
		} else {
			ECAM_controller.warningReset(wingIceSysFaultIcing);
		}
	} else {
		ECAM_controller.warningReset(wingIceSysFault);
		ECAM_controller.warningReset(wingIceSysFaultXbld);
		ECAM_controller.warningReset(wingIceSysFaultOff);
		ECAM_controller.warningReset(wingIceSysFaultIcing);
	}
	
	if (wingIceOpenGnd.clearFlag == 0 and warningNodes.Logic.waiGndFlight.getValue() and (phaseVar2 <= 2  or phaseVar2 >= 9)) {
		wingIceOpenGnd.active = 1;
		
		if (pts.Gear.wow[1].getValue() and wing_pb.getValue()) {
			wingIceOpenGndShut.active = 1;
		} else {
			ECAM_controller.warningReset(wingIceOpenGndShut);
		}
	} else {
		ECAM_controller.warningReset(wingIceOpenGnd);
		ECAM_controller.warningReset(wingIceOpenGndShut);
	}
	
	if (wingIceLHiPr.clearFlag == 0 and warningNodes.Timers.waiLhiPr.getValue() == 1 and (phaseVar2 <= 2  or phaseVar2 >= 9 or phaseVar2 == 6)) {
		wingIceLHiPr.active = 1;
		wingIceLHiPrThrust.active = 1;
	} else {
		ECAM_controller.warningReset(wingIceLHiPr);
		ECAM_controller.warningReset(wingIceLHiPrThrust);
	}
	
	if (wingIceRHiPr.clearFlag == 0 and warningNodes.Timers.waiRhiPr.getValue() == 1 and (phaseVar2 <= 2  or phaseVar2 >= 9 or phaseVar2 == 6)) {
		wingIceRHiPr.active = 1;
		wingIceRHiPrThrust.active = 1;
	} else {
		ECAM_controller.warningReset(wingIceRHiPr);
		ECAM_controller.warningReset(wingIceRHiPrThrust);
	}
	
	# Eng fire
	if (eng1FireDetFault.clearFlag == 0 and (systems.engFireDetectorUnits.vector[0].condition == 0 or (systems.engFireDetectorUnits.vector[0].loopOne == 9 and systems.engFireDetectorUnits.vector[0].loopTwo == 9 and systems.eng1Inop.getBoolValue())) and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		eng1FireDetFault.active = 1;
	} else {
		ECAM_controller.warningReset(eng1FireDetFault);
	}
	
	if (eng1LoopAFault.clearFlag == 0 and systems.engFireDetectorUnits.vector[0].loopOne == 9 and systems.engFireDetectorUnits.vector[0].loopTwo != 9 and !systems.eng1Inop.getBoolValue() and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		eng1LoopAFault.active = 1;
	} else {
		ECAM_controller.warningReset(eng1LoopAFault);
	}
	
	if (eng1LoopBFault.clearFlag == 0 and systems.engFireDetectorUnits.vector[0].loopOne != 9 and systems.engFireDetectorUnits.vector[0].loopTwo == 9 and !systems.eng1Inop.getBoolValue() and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		eng1LoopBFault.active = 1;
	} else {
		ECAM_controller.warningReset(eng1LoopBFault);
	}
	
	if (eng2FireDetFault.clearFlag == 0 and (systems.engFireDetectorUnits.vector[1].condition == 0 or (systems.engFireDetectorUnits.vector[1].loopOne == 9 and systems.engFireDetectorUnits.vector[1].loopTwo == 9 and systems.eng2Inop.getBoolValue())) and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		eng2FireDetFault.active = 1;
	} else {
		ECAM_controller.warningReset(eng2FireDetFault);
	}
	
	if (eng2LoopAFault.clearFlag == 0 and systems.engFireDetectorUnits.vector[1].loopOne == 9 and systems.engFireDetectorUnits.vector[1].loopTwo != 9 and !systems.eng2Inop.getBoolValue() and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		eng2LoopAFault.active = 1;
	} else {
		ECAM_controller.warningReset(eng2LoopAFault);
	}
	
	if (eng2LoopBFault.clearFlag == 0 and systems.engFireDetectorUnits.vector[1].loopOne != 9 and systems.engFireDetectorUnits.vector[1].loopTwo == 9 and !systems.eng2Inop.getBoolValue() and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		eng2LoopBFault.active = 1;
	} else {
		ECAM_controller.warningReset(eng2LoopBFault);
	}
	
	if (apuFireDetFault.clearFlag == 0 and (systems.engFireDetectorUnits.vector[2].condition == 0 or (systems.engFireDetectorUnits.vector[2].loopOne == 9 and systems.engFireDetectorUnits.vector[2].loopTwo == 9 and systems.apuInop.getBoolValue())) and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		apuFireDetFault.active = 1;
	} else {
		ECAM_controller.warningReset(apuFireDetFault);
	}
	
	if (apuLoopAFault.clearFlag == 0 and systems.engFireDetectorUnits.vector[2].loopOne == 9 and systems.engFireDetectorUnits.vector[2].loopTwo != 9 and !systems.apuInop.getBoolValue() and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		apuLoopAFault.active = 1;
	} else {
		ECAM_controller.warningReset(apuLoopAFault);
	}
	
	if (apuLoopBFault.clearFlag == 0 and systems.engFireDetectorUnits.vector[2].loopOne != 9 and systems.engFireDetectorUnits.vector[2].loopTwo == 9 and !systems.apuInop.getBoolValue() and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		apuLoopBFault.active = 1;
	} else {
		ECAM_controller.warningReset(apuLoopBFault);
	}
	
	if (crgAftFireDetFault.clearFlag == 0 and (systems.cargoSmokeDetectorUnits.vector[0].condition == 0 or systems.cargoSmokeDetectorUnits.vector[1].condition == 0) and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		crgAftFireDetFault.active = 1;
	} else {
		ECAM_controller.warningReset(crgAftFireDetFault);
	}
	
	if (crgFwdFireDetFault.clearFlag == 0 and systems.cargoSmokeDetectorUnits.vector[2].condition == 0 and (phaseVar2 == 6 or phaseVar2 >= 9 or phaseVar2 <= 2)) {
		crgFwdFireDetFault.active = 1;
	} else {
		ECAM_controller.warningReset(crgFwdFireDetFault);
	}
	
	if (hf1Emitting.clearFlag == 0 and transmitFlag1) {
		hf1Emitting.active = 1;
	} else {
		ECAM_controller.warningReset(hf1Emitting);
	}
	
	if (hf2Emitting.clearFlag == 0 and transmitFlag2) {
		hf2Emitting.active = 1;
	} else {
		ECAM_controller.warningReset(hf2Emitting);
	}
}

var messages_priority_1 = func {
}

var messages_priority_0 = func {
	if (FWC.Btn.recallStsNormalOutput.getBoolValue()) {
		recallNormal.active = 1;
		recallNormal1.active = 1;
		recallNormal2.active = 1;
	} else {
		ECAM_controller.warningReset(recallNormal);
		ECAM_controller.warningReset(recallNormal1);
		ECAM_controller.warningReset(recallNormal2);
	}
}

var messages_config_memo = func {
	phaseVarMemo = pts.ECAM.fwcWarningPhase.getValue();
	if (pts.Controls.Flight.flapsInput.getValue() == 0 or pts.Controls.Flight.flapsInput.getValue() == 4 or pts.Controls.Flight.speedbrake.getValue() != 0 or getprop("/fdm/jsbsim/hydraulics/stabilizer/final-deg") > 1.75 or getprop("/fdm/jsbsim/hydraulics/stabilizer/final-deg") < -3.65 or getprop("/fdm/jsbsim/hydraulics/rudder/trim-cmd-deg") < -3.55 or getprop("/fdm/jsbsim/hydraulics/rudder/trim-cmd-deg") > 3.55) {
		setprop("/ECAM/to-config-normal", 0);
	} else {
		setprop("/ECAM/to-config-normal", 1);
	}
	
	if (ecamConfigTest.getValue() and (phaseVarMemo == 1 or phaseVarMemo == 2 or phaseVarMemo == 9)) {
		setprop("/ECAM/to-config-set", 1);
	} else {
		setprop("/ECAM/to-config-set", 0);
	}
	
	if (!getprop("/ECAM/to-config-normal") or phaseVarMemo == 6) {
		setprop("/ECAM/to-config-reset", 1);
	} else {
		setprop("/ECAM/to-config-reset", 0);
	}
	
	if (systems.Autobrake.mode.getValue() == 3) {
		toMemoLine1.msg = "T.O AUTO BRK MAX";
		toMemoLine1.colour = "g";
	} else {
		toMemoLine1.msg = "T.O AUTO BRK.....MAX";
		toMemoLine1.colour = "c";
	}
	
	if (libraries.seatbeltSwitch.getValue() and libraries.noSmokingSwitch.getValue() ) {
		toMemoLine2.msg = "    SIGNS ON";
		toMemoLine2.colour = "g";
	} else {
		toMemoLine2.msg = "    SIGNS.........ON";
		toMemoLine2.colour = "c";
	}
	
	if (pts.Controls.Flight.speedbrakeArm.getValue()) {
		toMemoLine3.msg = "    SPLRS ARM";
		toMemoLine3.colour = "g";
	} else {
		toMemoLine3.msg = "    SPLRS........ARM";
		toMemoLine3.colour = "c";
	}
	
	if (pts.Controls.Flight.flapsPos.getValue() > 0 and pts.Controls.Flight.flapsPos.getValue() < 5) {
		toMemoLine4.msg = "    FLAPS T.O";
		toMemoLine4.colour = "g";
	} else {
		toMemoLine4.msg = "    FLAPS........T.O";
		toMemoLine4.colour = "c";
	}
	
	if (getprop("/ECAM/to-config-flipflop") and getprop("/ECAM/to-config-normal")) {
		toMemoLine5.msg = "    T.O CONFIG NORMAL";
		toMemoLine5.colour = "g";
	} else {
		toMemoLine5.msg = "    T.O CONFIG..TEST";
		toMemoLine5.colour = "c";
	}
	
	if (ecamConfigTest.getValue() and (phaseVarMemo == 2 or phaseVarMemo == 9)) {
		setprop("/ECAM/to-memo-set", 1);
	} else {
		setprop("/ECAM/to-memo-set", 0);
	}
	
	if (phaseVarMemo == 1 or phaseVarMemo == 3 or phaseVarMemo == 6 or phaseVarMemo == 10) {
		setprop("/ECAM/to-memo-reset", 1);
	} else {
		setprop("/ECAM/to-memo-reset", 0);
	}
	
	if ((phaseVarMemo == 2 and engStrtTime.getValue() != 0 and engStrtTime.getValue() + 120 < pts.Sim.Time.elapsedSec.getValue()) or getprop("/ECAM/to-memo-flipflop")) {
		toMemoLine1.active = 1;
		toMemoLine2.active = 1;
		toMemoLine3.active = 1;
		toMemoLine4.active = 1;
		toMemoLine5.active = 1;
	} else {
		ECAM_controller.warningReset(toMemoLine1);
		ECAM_controller.warningReset(toMemoLine2);
		ECAM_controller.warningReset(toMemoLine3);
		ECAM_controller.warningReset(toMemoLine4);
		ECAM_controller.warningReset(toMemoLine5);
	}
	
	if (getprop("/fdm/jsbsim/gear/gear-pos-norm") == 1) {
		ldgMemoLine1.msg = "LDG LDG GEAR DN";
		ldgMemoLine1.colour = "g";
	} else {
		ldgMemoLine1.msg = "LDG LDG GEAR......DN";
		ldgMemoLine1.colour = "c";
	}
	
	if (libraries.seatbeltSwitch.getValue() and libraries.noSmokingSwitch.getValue()) {
		ldgMemoLine2.msg = "    SIGNS ON";
		ldgMemoLine2.colour = "g";
	} else {
		ldgMemoLine2.msg = "    SIGNS.........ON";
		ldgMemoLine2.colour = "c";
	}
	
	if (pts.Controls.Flight.speedbrakeArm.getValue()) {
		ldgMemoLine3.msg = "    SPLRS ARM";
		ldgMemoLine3.colour = "g";
	} else {
		ldgMemoLine3.msg = "    SPLRS........ARM";
		ldgMemoLine3.colour = "c";
	}
	
	if (getprop("/it-fbw/law") == 1 or getprop("instrumentation/mk-viii/inputs/discretes/momentary-flap-3-override")) {
		if (pts.Controls.Flight.flapsPos.getValue() == 4) {
			ldgMemoLine4.msg = "    FLAPS CONF 3";
			ldgMemoLine4.colour = "g";
		} else {
			ldgMemoLine4.msg = "    FLAPS.....CONF 3";
			ldgMemoLine4.colour = "c";
		}
	} else {
		if (pts.Controls.Flight.flapsPos.getValue() == 5) {
			ldgMemoLine4.msg = "    FLAPS FULL";
			ldgMemoLine4.colour = "g";
		} else {
			ldgMemoLine4.msg = "    FLAPS.......FULL";
			ldgMemoLine4.colour = "c";
		}
	}
	
	gear_agl_cur = pts.Position.gearAglFt.getValue();
	if (gear_agl_cur < 2000) {
		setprop("/ECAM/ldg-memo-set", 1);
	} else {
		setprop("/ECAM/ldg-memo-set", 0);
	}
	
	if (gear_agl_cur > 2200) {
		setprop("/ECAM/ldg-memo-reset", 1);
	} else {
		setprop("/ECAM/ldg-memo-reset", 0);
	}
	
	if (gear_agl_cur > 2200) {
		setprop("/ECAM/ldg-memo-2200-set", 1);
	} else {
		setprop("/ECAM/ldg-memo-2200-set", 0);
	}
	
	if (phaseVarMemo != 6 and phaseVarMemo != 7 and phaseVarMemo != 8) {
		setprop("/ECAM/ldg-memo-2200-reset", 1);
	} else {
		setprop("/ECAM/ldg-memo-2200-reset", 0);
	}
	
	if ((phaseVarMemo == 6 and getprop("/ECAM/ldg-memo-flipflop") and getprop("/ECAM/ldg-memo-2200-flipflop")) or phaseVarMemo == 7 or phaseVarMemo == 8) {
		ldgMemoLine1.active = 1;
		ldgMemoLine2.active = 1;
		ldgMemoLine3.active = 1;
		ldgMemoLine4.active = 1;
	} else {
		ECAM_controller.warningReset(ldgMemoLine1);
		ECAM_controller.warningReset(ldgMemoLine2);
		ECAM_controller.warningReset(ldgMemoLine3);
		ECAM_controller.warningReset(ldgMemoLine4);
	}
}

var messages_memo = func {
	phaseVarMemo2 = pts.ECAM.fwcWarningPhase.getValue();
	if (getprop("/services/fuel-truck/enable") == 1 and toMemoLine1.active != 1 and ldgMemoLine1.active != 1) {
		refuelg.active = 1;
	} else {
		refuelg.active = 0;
	}
	
	if (systems.ADIRS.ADIRunits[0].inAlign == 1 or systems.ADIRS.ADIRunits[1].inAlign == 1 or systems.ADIRS.ADIRunits[2].inAlign == 1) {
		FWC.Logic.IRSinAlign.setValue(1);
	} else {
		FWC.Logic.IRSinAlign.setValue(0);
	}
	
	if ((phaseVarMemo2 == 1 or phaseVarMemo2 == 2) and toMemoLine1.active != 1 and ldgMemoLine1.active != 1 and (systems.ADIRS.ADIRunits[0].inAlign == 1 or systems.ADIRS.ADIRunits[1].inAlign == 1 or systems.ADIRS.ADIRunits[2].inAlign == 1)) {
		irs_in_align.active = 1;
		if (FWC.Timer.eng1or2Output.getValue()) {
			irs_in_align.colour = "a";
		} else {
			irs_in_align.colour = "g";
		}
		
		timeNow = pts.Sim.Time.elapsedSec.getValue();
		numberMinutes = math.round(math.max(systems.ADIRS.ADIRunits[0]._alignTime - timeNow, systems.ADIRS.ADIRunits[1]._alignTime - timeNow, systems.ADIRS.ADIRunits[2]._alignTime - timeNow) / 60);
		
		if (numberMinutes >= 7) {
			irs_in_align.msg = "IRS IN ALIGN > 7 MN";
		} elsif (numberMinutes >= 1) {
			irs_in_align.msg = "IRS IN ALIGN " ~ numberMinutes ~ " MN";
		} else {
			irs_in_align.msg = "IRS IN ALIGN";
		}
	} else {
		if (irs_in_align.active and !timer10secIRS) {
			timer10secIRS = 1;
			irs_in_align.msg = "IRS ALIGNED";
			settimer(func() {
				irs_in_align.active = 0;
				irs_in_align.msg = "IRS IN ALIGN";
				timer10secIRS = 0;
			}, 10);
		} elsif (!timer10secIRS) {
			irs_in_align.active = 0;
			irs_in_align.msg = "IRS IN ALIGN";
		}
	}
	
	if (pts.Controls.Flight.speedbrakeArm.getValue() == 1 and toMemoLine1.active != 1 and ldgMemoLine1.active != 1) {
		gnd_splrs.active = 1;
	} else {
		gnd_splrs.active = 0;
	}
	
	if (libraries.seatbeltLight.getValue() == 1 and toMemoLine1.active != 1 and ldgMemoLine1.active != 1) {
		seatbelts.active = 1;
	} else {
		seatbelts.active = 0;
	}
	
	if (libraries.noSmokingLight.getValue() == 1 and toMemoLine1.active != 1 and ldgMemoLine1.active != 1) { # should go off after takeoff assuming switch is in auto due to old logic from the days when smoking was allowed!
		nosmoke.active = 1;
	} else {
		nosmoke.active = 0;
	}

	if (getprop("/controls/lighting/strobe") == 0 and !pts.Gear.wow[1].getValue() and toMemoLine1.active != 1 and ldgMemoLine1.active != 1) { # todo: use gear branch properties
		strobe_lt_off.active = 1;
	} else {
		strobe_lt_off.active = 0;
	}
	
	if (systems.FUEL.Valves.transfer1.getValue() == 1 or systems.FUEL.Valves.transfer2.getValue() == 1 and toMemoLine1.active != 1 and ldgMemoLine1.active != 1) {
		outr_tk_fuel_xfrd.active = 1;
	} else {
		outr_tk_fuel_xfrd.active = 0;
	}

	if (pts.Consumables.Fuel.totalFuelLbs.getValue() < 6613 and toMemoLine1.active != 1 and ldgMemoLine1.active != 1) { # assuming US short ton 2000lb
		if (acconfig_weight_kgs.getValue()) {
			fob_3T.active = 1;
			fob_66L.active = 0;
		} else {
			fob_3T.active = 0;
			fob_66L.active = 1;
		}
	} else {
		fob_3T.active = 0;
		fob_66L.active = 0;
	}
	
	if (getprop("instrumentation/mk-viii/inputs/discretes/momentary-flap-all-override") == 1 and toMemoLine1.active != 1 and ldgMemoLine1.active != 1) {
		gpws_flap_mode_off.active = 1;
	} else {
		gpws_flap_mode_off.active = 0;
	}
	
	if (!fmgc.FMGCInternal.flightNumSet and toMemoLine1.active != 1 and ldgMemoLine1.active != 1 and (phaseVarMemo2 <= 2 or phaseVarMemo2 == 6 or phaseVarMemo2 >= 9)) {
		company_datalink_stby.active = 1;
	} else {
		company_datalink_stby.active = 0;
	}
}

var messages_right_memo = func {
	phaseVarMemo3 = pts.ECAM.fwcWarningPhase.getValue();
	if (FWC.Timer.toInhibitOutput.getValue() == 1) {
		to_inhibit.active = 1;
	} else {
		to_inhibit.active = 0;
	}
	
	if (FWC.Timer.ldgInhibitOutput.getValue() == 1) {
		ldg_inhibit.active = 1;
	} else {
		ldg_inhibit.active = 0;
	}
	
	if (!(FWC.Timer.gnd.getValue() == 1) and (systems.ELEC.EmerElec.getValue() or dualFailNode.getValue() == 1 or systems.eng1FireWarn.getValue() == 1 or systems.eng2FireWarn.getValue() == 1 or systems.apuFireWarn.getValue() == 1 or systems.aftCargoFireWarn.getValue() == 1 or systems.fwdCargoFireWarn.getValue() == 1 or (systems.HYD.Warnings.greenAbnormLoPr.getValue() and systems.HYD.Warnings.yellowAbnormLoPr.getValue()) or (systems.HYD.Warnings.greenAbnormLoPr.getValue() and systems.HYD.Warnings.blueAbnormLoPr.getValue()) or (systems.HYD.Warnings.blueAbnormLoPr.getValue() and systems.HYD.Warnings.yellowAbnormLoPr.getValue()))) {
		land_asap_r.active = 1;
	} else {
		land_asap_r.active = 0;
	}
	
	if ((systems.ELEC.Bus.dc2.getValue() < 25 and (fbw.FBW.Failures.elac1.getValue() == 1 or fbw.FBW.Failures.sec1.getValue() == 1)) or ((systems.HYD.Psi.yellow.getValue() < 1500 or systems.HYD.Psi.green.getValue() < 1500) and (fbw.FBW.Failures.elac1.getValue() == 1 and fbw.FBW.Failures.sec1.getValue() == 1)) or (systems.HYD.Psi.blue.getValue() < 1500 and (fbw.FBW.Failures.elac2.getValue() == 1 and fbw.FBW.Failures.sec2.getValue() == 1))) {
		fltCtlLandAsap = 1;
	} else {
		fltCtlLandAsap = 0;
	}
	
	if (land_asap_r.active == 0 and !(FWC.Timer.gnd.getValue() == 1) and (warningNodes.Timers.lowLevelBoth.getValue() == 1 or warningNodes.Logic.eng1Shutdown.getValue() or warningNodes.Logic.eng2Shutdown.getValue() or warningNodes.Logic.eng1Fail.getValue() or warningNodes.Logic.eng2Fail.getValue() or warningNodes.Timers.dcEmerConfig.getValue() == 1 or fltCtlLandAsap)) {
		# todo avionics smoke and reverse unlocked
		land_asap_a.active = 1;
	} else {
		land_asap_a.active = 0;
	}
	
	if (ecam.ap_active == 1 and apWarn.getValue() == 1) {
		ap_off.active = 1;
	} else {
		ap_off.active = 0;
	}
	
	if (ecam.athr_active == 1 and athrWarn.getValue() == 1) {
		athr_off.active = 1;
	} else {
		athr_off.active = 0;
	}
	
	if ((phaseVarMemo3 >= 2 and phaseVarMemo3 <= 7) and pts.Controls.Flight.speedbrake.getValue() != 0) {
		spd_brk.active = 1;
	} else {
		spd_brk.active = 0;
	}
	
	thrustState = [systems.FADEC.detentText[0].getValue(), systems.FADEC.detentText[1].getValue()];
	if (thrustState[0] == "IDLE" and thrustState[1] == "IDLE" and phaseVarMemo3 >= 6 and phaseVarMemo3 <= 7) {
		spd_brk.colour = "g";
	} else if ((phaseVarMemo3 >= 2 and phaseVarMemo3 <= 5) or ((thrustState[0] != "IDLE" or thrustState[1]) != "IDLE") and (phaseVarMemo3 >= 6 and phaseVarMemo3 <= 7)) {
		spd_brk.colour = "a";
	}
	
	if (pts.Controls.Gear.parkingBrake.getValue() == 1 and phaseVarMemo3 != 3) {
		park_brk.active = 1;
	} else {
		park_brk.active = 0;
	}
	if (phaseVarMemo3 >= 4 and phaseVarMemo3 <= 8) {
		park_brk.colour = "a";
	} else {
		park_brk.colour = "g";
	}
	
	if (systems.HYD.Switch.ptu.getValue() == 1 and ((systems.HYD.Psi.yellow.getValue() < 1450 and systems.HYD.Psi.green.getValue() > 1450 and getprop("/controls/hydraulic/elec-pump-yellow") == 0) or (systems.HYD.Psi.yellow.getValue() > 1450 and systems.HYD.Psi.green.getValue() < 1450))) {
		ptu.active = 1;
	} else {
		ptu.active = 0;
	}
	
	if (systems.HYD.Rat.position.getValue() != 0) {
		rat.active = 1;
	} else {
		rat.active = 0;
	}
	
	if (phaseVarMemo3 >= 1 and phaseVarMemo3 <= 2) {
		rat.colour = "a";
	} else {
		rat.colour = "g";
	}
	
	if (systems.ELEC.Source.EmerGen.relayPos.getValue() == 1 and systems.HYD.Rat.position.getValue() != 0 and !pts.Gear.wow[1].getValue()) {
		emer_gen.active = 1;
	} else {
		emer_gen.active = 0;
	}
	
	if (getprop("/sim/model/autopush/enabled") == 1) { # this message is only on when towing - not when disc with switch
		nw_strg_disc.active = 1;
	} else {
		nw_strg_disc.active = 0;
	}
	
	if (pts.Engines.Engine.state[0].getValue() == 3 or pts.Engines.Engine.state[1].getValue() == 3) {
		nw_strg_disc.colour = "a";
	} else {
		nw_strg_disc.colour = "g";
	}
	
	if (systems.PNEU.Switch.ramAir.getValue() == 1) {
		ram_air.active = 1;
	} else {
		ram_air.active = 0;
	}
	
	if (getprop("/systems/oxygen/passenger-oxygen/sys-on-light") == 1) {
		pax_oxy.active = 1;
	} else {
		pax_oxy.active = 0;
	}
	
	if (getprop("/controls/engines/engine[0]/igniter-a") == 1 or getprop("/controls/engines/engine[0]/igniter-b") == 1 or getprop("/controls/engines/engine[1]/igniter-a") == 1 or getprop("/controls/engines/engine[1]/igniter-b") == 1) {
		ignition.active = 1;
	} else {
		ignition.active = 0;
	}
	
	if ((atc.Transponders.vector[0].condition == 0 and atc.Transponders.vector[1].condition == 0) or (!getprop("/systems/navigation/adr/operating-1") and !getprop("/systems/navigation/adr/operating-2") and !getprop("/systems/navigation/adr/operating-3")) or pts.Instrumentation.TCAS.Inputs.mode.getValue() == 1) {
		if (phaseVarMemo3 == 6) {
			tcas_stby.colour = "a";
		} else {
			tcas_stby.colour = "g";
		}
		tcas_stby.active = 1;
	} else {
		tcas_stby.active = 0;
	}
	
	if ((phaseVarMemo3 <= 2 or phaseVarMemo3 == 6 or phaseVarMemo3 >= 9) and atsu.CompanyCall.frequency != 999.99 and !atsu.CompanyCall.received) {
		company_call.active = 1;
	} else {
		company_call.active = 0;
	}
	
	if (mcdu.ReceivedMessagesDatabase.firstUnviewed() != -99 and (phaseVarMemo2 <= 2 or phaseVarMemo2 == 6 or phaseVarMemo2 >= 9)) {
		company_msg.active = 1;
	} else {
		company_msg.active = 0;
	}
	
	if (getprop("/controls/ice-protection/leng") == 1 or getprop("/controls/ice-protection/reng") == 1 or systems.ELEC.Bus.dc1.getValue() < 25 or  systems.ELEC.Bus.dc2.getValue() < 25) {
		eng_aice.active = 1;
	} else {
		eng_aice.active = 0;
	}
	
	if (wing_pb.getValue() == 1) {
		wing_aice.active = 1;
	} else {
		wing_aice.active = 0;
	}
	
	if (systems.PNEU.Switch.apu.getValue() == 1 and pts.APU.rpm.getValue() >= 95) {
		apu_bleed.active = 1;
	} else {
		apu_bleed.active = 0;
	}

	if (apu_bleed.active == 0 and pts.APU.rpm.getValue() >= 95) {
		apu_avail.active = 1;
	} else {
		apu_avail.active = 0;
	}

	if (pts.Controls.Lighting.landingLights[1].getValue() > 0 or pts.Controls.Lighting.landingLights[2].getValue() > 0) {
		ldg_lt.active = 1;
	} else {
		ldg_lt.active = 0;
	}
	
	if (systems.BrakeSys.brakeFans.getValue() == 1) {
		brk_fan.active = 1;
	} else {
		brk_fan.active = 0;
	}
	
	if (pts.Instrumentation.MKVII.Inputs.Discretes.flap3Override.getValue() == 1) { # todo: emer elec
		gpws_flap3.active = 1;
	} else {
		gpws_flap3.active = 0;
	}
	
	if (!rmp.vhf3_data_mode.getValue() and (phaseVarMemo3 == 1 or phaseVarMemo3 == 2 or phaseVarMemo3 == 6 or phaseVarMemo3 == 9 or phaseVarMemo3 == 10)) {
		vhf3_voice.active = 1;
	} else {
		vhf3_voice.active = 0;
	}
	
	if (systems.Autobrake.mode.getValue() == 1 and (phaseVarMemo3 == 7 or phaseVarMemo3 == 8)) {
		auto_brk_lo.active = 1;
	} else {
		auto_brk_lo.active = 0;
	}

	if (systems.Autobrake.mode.getValue() == 2 and (phaseVarMemo3 == 7 or phaseVarMemo3 == 8)) {
		auto_brk_med.active = 1;
	} else {
		auto_brk_med.active = 0;
	}

	if (systems.Autobrake.mode.getValue() == 3 and (phaseVarMemo3 == 7 or phaseVarMemo3 == 8)) {
		auto_brk_max.active = 1;
	} else {
		auto_brk_max.active = 0;
	}
	
	if (phaseVarMemo3 >= 2 and phaseVarMemo3 <= 9 and systems.ELEC.Bus.ac1.getValue() >= 110 and systems.ELEC.Bus.ac2.getValue() >= 110 and (getprop("/systems/fuel/feed-center-1") or getprop("/systems/fuel/feed-center-2"))) {
		ctr_tk_feedg.active = 1;
	} else {
		ctr_tk_feedg.active = 0;
	}
	
	if (systems.FUEL.Valves.crossfeed.getValue() != 0 and systems.FUEL.Switches.crossfeed.getValue()) {
		fuelx.active = 1;
	} else {
		fuelx.active = 0;
	}
	
	if (phaseVarMemo3 >= 3 and phaseVarMemo3 <= 5) {
		fuelx.colour = "a";
	} else {
		fuelx.colour = "g";
	}
	
	if (systems.SwitchingPanel.Switches.airData.getValue() != 0 or systems.SwitchingPanel.Switches.attHdg.getValue() != 0) {
		adirs_switch.active = 1;
	} else {
		adirs_switch.active = 0;
	}
}

setlistener("/engines/engine[0]/state", func() {
	if ((state1Node.getValue() != 3 and state2Node.getValue() != 3) and !pts.Fdm.JSBsim.Position.wow.getBoolValue()) {
		dualFailNode.setBoolValue(1);
	} else {
		dualFailNode.setBoolValue(0);
	}
}, 0, 0);

setlistener("/engines/engine[1]/state", func() {
	if ((state1Node.getValue() != 3 and state2Node.getValue() != 3) and !pts.Fdm.JSBsim.Position.wow.getBoolValue()) {
		dualFailNode.setBoolValue(1);
	} else {
		dualFailNode.setBoolValue(0);
	}
}, 0, 0);
