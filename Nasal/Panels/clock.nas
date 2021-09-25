#
# ﻿Chrono - Clock - ET
#
var chr = aircraft.timer.new("/instrumentation/chrono[0]/elapsetime-sec",1);
var clk = aircraft.timer.new("/instrumentation/clock/elapsetime-sec",1);
var chrono_cpt = aircraft.timer.new("/instrumentation/ndchrono[0]/elapsetime-sec",1);
var chrono_fo = aircraft.timer.new("/instrumentation/ndchrono[1]/elapsetime-sec",1);
var chrono_cpt_node = props.globals.getNode("/instrumentation/ndchrono[0]/elapsetime-sec");
var chrono_fo_node = props.globals.getNode("/instrumentation/ndchrono[1]/elapsetime-sec");

var chr_min = nil;
var chr_sec = nil;
var chr_tmp = nil;
var clock2_1 = nil;
var clock2_2 = nil;
var day = nil;
var et_hr = nil;
var et_min = nil;
var et_tmp = nil;
var month = nil;
var rudder_val = nil;
var tmp = nil;
var tmp1 = nil;
var UTC_date = nil;
var UTC_date1 = nil;
var UTC_date2 = nil;
var UTC_date3 = nil;
var year = nil;

var et_selector = props.globals.initNode("/instrumentation/clock/et-selector", 1, "INT");
var utc_selector = props.globals.initNode("/instrumentation/clock/utc-selector",0,"INT");
var set_knob = props.globals.initNode("/instrumentation/clock/set-knob",0,"INT");

var clock = {
	elapsedHour: props.globals.initNode("/instrumentation/clock/et-hr", 0, "INT"),
	elapsedMin: props.globals.initNode("/instrumentation/clock/et-min", 0, "INT"),
	elapsedString: props.globals.initNode("/instrumentation/clock/elapsed-string", 0, "STRING"),
	elapsedSec: props.globals.initNode("/instrumentation/clock/elapsetime-sec", 0, "INT"),
	indicatedSec: props.globals.getNode("/instrumentation/clock/indicated-seconds"),
	hhMM: props.globals.initNode("/instrumentation/clock/clock_hh_mm", 0, "STRING"),
	utcDate: [props.globals.initNode("/instrumentation/clock/utc-date", "", "STRING"), props.globals.initNode("/instrumentation/clock/utc-date1", "", "STRING"),
		props.globals.initNode("/instrumentation/clock/utc-date2", "", "STRING"),props.globals.initNode("/instrumentation/clock/utc-date3", "", "STRING")],
};

var chrono = {
	chronoReset: props.globals.initNode("/instrumentation/chrono[0]/chrono-reset", 1, "INT"),
	elapseTime: props.globals.initNode("/instrumentation/chrono[0]/elapsetime-sec", 0, "INT"),
	etMin: props.globals.initNode("/instrumentation/chrono[0]/chr-et-min", 0, "INT"),
	etSec: props.globals.initNode("/instrumentation/chrono[0]/chr-et-sec", 0, "INT"),
	etString: props.globals.initNode("/instrumentation/chrono[0]/chr-et-string", 0, "STRING"),
	paused: props.globals.getNode("/instrumentation/chrono[0]/paused"),
	started: props.globals.getNode("/instrumentation/chrono[0]/started"),
};

#Cpt chrono
var cpt_chrono = {
	etHh_cpt: props.globals.initNode("/instrumentation/ndchrono[0]/etHh_cpt", 0, "INT"),
	etMin_cpt: props.globals.initNode("/instrumentation/ndchrono[0]/etMin_cpt", 0, "INT"),
	etSec_cpt:  props.globals.initNode("/instrumentation/ndchrono[0]/etSec_cpt", 0, "INT"),
	text: props.globals.initNode("/instrumentation/ndchrono[0]/text", "0' 00''", "STRING"),
};

#Fo chrono
var fo_chrono = {
	etHh_fo: props.globals.initNode("/instrumentation/ndchrono[1]/etHh_fo", 0, "INT"),
	etMin_fo: props.globals.initNode("/instrumentation/ndchrono[1]/etMin_fo", 0, "INT"),
	etSec_fo:  props.globals.initNode("/instrumentation/ndchrono[1]/etSec_fo", 0, "INT"),
	text: props.globals.initNode("/instrumentation/ndchrono[1]/text", "0' 00''", "STRING"),
};

var rudderTrim = {
	rudderTrimDisplay: props.globals.initNode("/controls/flight/rudder-trim-display", 0, "STRING"),
	rudderTrimDisplayLetter: props.globals.initNode("/controls/flight/rudder-trim-letter-display", "", "STRING"),
};

setlistener("/sim/signals/fdm-initialized", func {
	chr.stop();
	chr.reset();
	clk.stop();
	clk.reset();
	chrono_cpt.reset();
	chrono_fo.reset();
	rudderTrim.rudderTrimDisplay.setValue(sprintf("%2.1f", pts.Fdm.JSBsim.Hydraulics.Rudder.trimDeg.getValue()));
	start_loop.start();
});

setlistener("/instrumentation/chrono[0]/chrono-reset", func(et){
	tmp = et.getValue();
	if (tmp == 2) {
		if (chrono.started.getBoolValue()) {
			if (!chrono.paused.getBoolValue()) {
				chrono.elapseTime.setValue(0);
				chrono.chronoReset.setBoolValue(0);
			} else {
				chr.stop();
				chr.reset();
				chrono.chronoReset.setBoolValue(1);
				chrono.started.setBoolValue(0);
				chrono.paused.setBoolValue(0);
			};
		} else {
			if (!chrono.paused.getBoolValue()) {
				# No action required
			} else {
				chrono.paused.setBoolValue(0);
			};
		};
	} elsif (tmp == 1) {
		if (chrono.started.getBoolValue()) {
			if (!chrono.paused.getBoolValue()) {
				chr.stop();
				chrono.paused.setBoolValue(1);
			} else {
				chr.stop();
			};
		} else {
			if (!chrono.paused.getBoolValue()) {
				chr.stop();
			} else {
				chr.stop();
				chrono.paused.setBoolValue(0);
			};
		};
	} elsif (tmp == 0) {
		if (!chrono.started.getBoolValue()) {
			if (!chrono.paused.getBoolValue()) {
				chr.start();
				chrono.started.setBoolValue(1);
			} else {
				chr.start();
				chrono.paused.setBoolValue(0);
			};
		} else {
			if (!chrono.paused.getBoolValue()) {
				# No action required
			} else {
				chr.start();
				chrono.paused.setBoolValue(0);
			};
		};
	};
}, 0, 0);

#Chrono
setlistener("/instrumentation/efis[0]/inputs/CHRONO", func(et){
		chrono0 = et.getValue();
		if (chrono0 == 1){
			chrono_cpt.start();
		} elsif (chrono0 == 2) {
			chrono_cpt.stop();
		} elsif (chrono0 == 0) {
			chrono_cpt.reset();
			chrono_cpt_node.setValue(0);
		}
}, 0, 0);

setlistener("/instrumentation/efis[1]/inputs/CHRONO", func(et){
		chrono1 = et.getValue();
		if (chrono1 == 1){
			chrono_fo.start();
		} elsif (chrono1 == 2) {
			chrono_fo.stop();
		} elsif (chrono1 == 0) {
			chrono_fo.reset();
			chrono_fo_node.setValue(0);
		}
}, 0, 0);

setlistener("/instrumentation/clock/et-selector", func(et){
	tmp1 = et.getValue();
	if (tmp1 == 2){
		clk.reset();
	} elsif (tmp1 == 1){
		clk.stop();
	} elsif (tmp1 == 0){
		clk.start();
	}
}, 0, 0);

#Chrono
setlistener("instrumentation/efis[0]/inputs/CHRONO", func(et){
		chrono0 = et.getValue();
		if (chrono0 == 1){
			chrono_cpt.start();
		} elsif (chrono0 == 2) {
			chrono_cpt.stop();
		} elsif (chrono0 == 0) {
			chrono_cpt.reset();
			setprop("instrumentation/ndchrono[0]/elapsetime-sec", 0);
		}
}, 0, 0);

setlistener("instrumentation/efis[1]/inputs/CHRONO", func(et){
		chrono1 = et.getValue();
		if (chrono1 == 1){
			chrono_fo.start();
		} elsif (chrono1 == 2) {
			chrono_fo.stop();
		} elsif (chrono1 == 0) {
			chrono_fo.reset();
			setprop("instrumentation/ndchrono[1]/elapsetime-sec", 0);
		}
}, 0, 0);

var start_loop = maketimer(0.1, func {
	if (systems.ELEC.Bus.dcEss.getValue() < 25) { return; }
	
	# Annun-test
	if (pts.Controls.Switches.annunTest.getBoolValue()) {
		UTC_date = sprintf("%02d %02d %02d", "88", "88", "88");
		UTC_date1 = sprintf("%02d", "88");
		UTC_date2 = sprintf("%02d", "88");
		UTC_date3 = sprintf("%02d", "88");
		clock2_1 = "88:88";
		clock2_2 = sprintf("%02d", 88);
		
		clock.hhMM.setValue(clock2_1);
		clock.indicatedSec.setValue(clock2_2);
		clock.utcDate[0].setValue(UTC_date);
		clock.utcDate[1].setValue(UTC_date1);
		clock.utcDate[2].setValue(UTC_date2);
		clock.utcDate[3].setValue(UTC_date3);
		
		chrono.etString.setValue("88 88");
		clock.elapsedString.setValue("88:88");
	} else {
		day = pts.Sim.Time.Utc.day.getValue();
		month = pts.Sim.Time.Utc.month.getValue();
		year = pts.Sim.Time.Utc.year.getValue();
		
		# Clock
		UTC_date = sprintf("%02d %02d %02d", month, day, substr(sprintf("%2d", year),1,2));
		UTC_date1 = sprintf("%02d", month);
		UTC_date2 = sprintf("%02d", day);
		UTC_date3 = substr(sprintf("%2d", year),2,2);
		clock2_1 = pts.Instrumentation.Clock.indicatedStringShort.getValue();
		clock2_2 = sprintf("%02d", substr(pts.Instrumentation.Clock.indicatedString.getValue(),6,2));
		
		clock.hhMM.setValue(clock2_1);
		clock.indicatedSec.setValue(clock2_2);
		clock.utcDate[0].setValue(UTC_date);
		clock.utcDate[1].setValue(UTC_date1);
		clock.utcDate[2].setValue(UTC_date2);
		clock.utcDate[3].setValue(UTC_date3);
		
		if (set_knob.getValue() == "") {
			set_knob.setValue(0);
		}
	
		if (utc_selector.getValue() == "") {
			utc_selector.setValue(0);
		}
		
#		if (getprop("/instrumentation/clock/utc-selector") == 0) {
#			# To do - GPS mode
#		};
#		if (getprop("/instrumentation/clock/utc-selector") == 1) {
#			# To do - INT mode
#		};
#		if (getprop("/instrumentation/clock/utc-selector") == 2) {
#			# To do - SET mode
#		};

		# Chrono
		chr_tmp = chrono.elapseTime.getValue();
		if (chr_tmp >= 6000) {
			chrono.elapseTime.setValue(chr_tmp - 6000);
		}
		
		chr_min = int(chr_tmp * 0.0166666666667);
		if (chr_tmp >= 60) {
			chr_sec = int(chr_tmp - (chr_min * 60));
		} else {
			chr_sec = int(chr_tmp);
		}
		
		chrono.etMin.setValue(chr_min);
		chrono.etSec.setValue(chr_sec);
		chrono.etString.setValue(sprintf("%02d:%02d", chr_min, chr_sec));

		# ET clock
		et_tmp = clock.elapsedSec.getValue();
		if (et_tmp >= 360000) {
			clock.elapsedSec.setValue(et_tmp - 360000);
		}
		
		et_min = int(et_tmp * 0.0166666666667);
		et_hr  = int(et_min * 0.0166666666667);
		et_min = et_min - (et_hr * 60);
		
		clock.elapsedHour.setValue(et_hr);
		clock.elapsedMin.setValue(et_min);
		clock.elapsedString.setValue(sprintf("%02d:%02d", et_hr, et_min));
		
		foreach (item; update_items) {
			item.update(nil);
		}
	}
	
	#Cpt Chrono
	chr0_tmp = chrono_cpt_node.getValue();
	if (chr0_tmp >= 360000) {
		chrono_cpt_node.setValue(chrono_cpt_node.getValue() - 360000);
	}
	
	chr0_hh = int(chr0_tmp * 0.000277777777778);		
	chr0_min = int((chr0_tmp * 0.0166666666667) - (chr0_hh * 60));
	chr0_sec = int(chr0_tmp - (chr0_min * 60) - (chr0_hh * 3600));
	cpt_chrono.etHh_cpt.setValue(chr0_hh);
	cpt_chrono.etMin_cpt.setValue(chr0_min);
	cpt_chrono.etSec_cpt.setValue(chr0_sec);
	if (chr0_tmp >= 3600) {
		cpt_chrono.text.setValue(sprintf("%02d H %02d'", chr0_hh, chr0_min));
	} else {
		cpt_chrono.text.setValue(sprintf("%02d' %02d''", chr0_min, chr0_sec));
	}
	
	#Fo Chrono
	chr1_tmp = chrono_fo_node.getValue();
	if (chr1_tmp >= 360000) {
		chrono_fo_node.setValue(chrono_fo_node.getValue() - 360000);
	}
	
	chr1_hh = int(chr1_tmp * 0.000277777777778);		
	chr1_min = int(chr1_tmp * 0.0166666666667);
	chr1_sec = int(chr1_tmp - (chr1_min * 60) - (chr1_hh * 3600));
	fo_chrono.etHh_fo.setValue(chr1_hh);
	fo_chrono.etMin_fo.setValue(chr1_min);
	fo_chrono.etSec_fo.setValue(chr1_sec);
	if (chr1_tmp >= 3600) {
		fo_chrono.text.setValue(sprintf("%02d H %02d'", chr1_hh, chr1_min));
	} else {
		fo_chrono.text.setValue(sprintf("%02d' %02d''", chr1_min, chr1_sec));
	}
});

var updateRudderTrim = func() {
	if (pts.Controls.Switches.annunTest.getBoolValue()) {
		rudderTrim.rudderTrimDisplay.setValue(sprintf("%3.1f", "88.8"));
		rudderTrim.rudderTrimDisplayLetter.setValue(sprintf("%1.0f", "8"));
	} else {
		rudder_val = pts.Fdm.JSBsim.Hydraulics.Rudder.trimDeg.getValue();
		if (rudder_val > -0.05 and rudder_val < 0.05) {
			rudderTrim.rudderTrimDisplay.setValue(sprintf("%2.1f", abs(rudder_val)));
			rudderTrim.rudderTrimDisplayLetter.setValue("");
		} else {
			rudderTrim.rudderTrimDisplay.setValue(sprintf("%2.1f", abs(rudder_val)));
			if (rudder_val >= 0.05) {
				rudderTrim.rudderTrimDisplayLetter.setValue("R");
			} elsif (rudder_val <= -0.05) {
				rudderTrim.rudderTrimDisplayLetter.setValue("L");
			}
		}
	}
}

var update_items = [
	props.UpdateManager.FromProperty("/fdm/jsbsim/hydraulics/rudder/trim-deg", 0.05, func(notification)
		{
			updateRudderTrim();
		}
	),
];

setlistener("/controls/switches/annun-test", updateRudderTrim, 0, 0);
