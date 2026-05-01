/*
 * Compatibility replacement for the original iStat nano Dashboard plugin.
 *
 * The legacy widget expects a synchronous global named `iStatNano`. This shim
 * keeps that API and serves cached data from the local Python snapshot server.
 */
(function(global) {
	if(global.iStatNano)
		return;

	var state = {
		cpu: [[0, 0, 0, 100, 0], [[0, 0, 0, 0]]],
		memory: ["0mb", "0mb", "0mb", "0mb", "0mb", 0, "0", "0", "0mb", "0mb", 0, 0],
		disks: [],
		network: [],
		tempsC: [],
		fans: [],
		battery: ["Unknown", "0%", "Unknown", "Unknown", "0", "0%"],
		externalIP: "",
		externalIPValid: false,
		isLaptop: true,
		uptime: "",
		load: "",
		processinfo: ""
	};
	var apiURL = "http://127.0.0.1:39123/snapshot";
	var hasSnapshot = false;
	var started = false;
	var readyCallbacks = [];
	var networkSetupChanged = true;
	var diskSetupChanged = true;

	function copyRows(rows) {
		var out = [];
		for(var i = 0; i < rows.length; i++) {
			var row = [];
			for(var j = 0; j < rows[i].length; j++) {
				if(rows[i][j] && rows[i][j].constructor == Array)
					row[j] = copyRows([rows[i][j]])[0];
				else
					row[j] = rows[i][j];
			}
			out.push(row);
		}
		return out;
	}

	function tempsForScale(scale) {
		var mode = String(scale);
		var suffix = mode == "2" ? "K" : "\u00b0";
		var temps = [];
		for(var i = 0; i < state.tempsC.length; i++) {
			var item = state.tempsC[i];
			var value = Number(item[1] || item[2] || 0);
			if(mode == "1")
				value = Math.round((value * 9 / 5) + 32);
			else if(mode == "2")
				value = Math.round(value + 273.15);
			else
				value = Math.round(value);
			temps.push([item[0], value + suffix]);
		}
		return temps;
	}

	function arraysDifferLength(before, after) {
		return (before || []).length != (after || []).length;
	}

	function applySnapshot(snapshot) {
		var oldNetwork = state.network;
		var oldDisks = state.disks;
		for(var key in snapshot) {
			if(snapshot.hasOwnProperty(key))
				state[key] = snapshot[key];
		}
		networkSetupChanged = networkSetupChanged || arraysDifferLength(oldNetwork, state.network);
		diskSetupChanged = diskSetupChanged || arraysDifferLength(oldDisks, state.disks);
		hasSnapshot = true;
		runReadyCallbacks();
	}

	function runReadyCallbacks() {
		var waiting = global.document ? global.document.getElementById("server_waiting") : null;
		if(waiting)
			waiting.style.display = "none";
		while(readyCallbacks.length > 0) {
			var callback = readyCallbacks.shift();
			try {
				callback();
			}
			catch(ex) {}
		}
	}

	function pollSnapshot() {
		try {
			var xhr = new XMLHttpRequest();
			xhr.open("GET", apiURL, true);
			xhr.onreadystatechange = function() {
				if(xhr.readyState != 4 || xhr.status != 200)
					return;
				var payload;
				if(typeof JSON != "undefined" && JSON.parse)
					payload = JSON.parse(xhr.responseText);
				else
					payload = eval("(" + xhr.responseText + ")");
				applySnapshot(payload);
			};
			xhr.send(null);
		}
		catch(ex) {}
	}

	pollSnapshot();
	setInterval(pollSnapshot, 1000);

	global.iStatNano = {
		isIntel: function() { return true; },
		isLaptop: function() { return !!state.isLaptop; },
		needsIntelBundle: function() { return false; },
		wasIntelModuleInstalled: function() { return true; },
		installIntelModule: function() {},

		cpuUsage: function() { return [state.cpu[0] || [0, 0, 0, 100, 0], copyRows(state.cpu[1] || [[0, 0, 0, 0]])]; },
		memoryUsage: function() { return (state.memory || []).slice(0); },
		diskUsage: function() { return copyRows(state.disks || []); },
		network: function() { return copyRows(state.network || []); },
		temps: function(scale) { return tempsForScale(scale); },
		fans: function() { return copyRows(state.fans || []); },
		battery: function() { return (state.battery || ["Unknown", "0%", "Unknown", "Unknown", "0", "0%"]).slice(0, 6); },

		uptime: function() { return state.uptime || ""; },
		load: function() { return state.load || ""; },
		processinfo: function() { return state.processinfo || ""; },
		externalIP: function() { return state.externalIP || ""; },
		externalIPValid: function() { return !!state.externalIPValid; },

		hasDiskSetupChanged: function() {
			if(!diskSetupChanged)
				return false;
			diskSetupChanged = false;
			return true;
		},
		hasNetworkSetupChanged: function() {
			if(!networkSetupChanged)
				return false;
			networkSetupChanged = false;
			return true;
		},
		setShouldMonitorSMARTTemps: function() {},
		setNeedsSMARTUpdate: function() {},

		copyTextToClipboard: function(text) {
			global.__iStatNanoClipboardText = text;
		},
		getselfpid: function() { return "-1"; },
		getPsName: function() { return "Unknown widget"; },
		getAppPath: function() { return ""; },

		startWhenReady: function(callback) {
			if(started)
				return;
			started = true;
			if(hasSnapshot)
				callback();
			else
				readyCallbacks.push(callback);
		},

		updateSnapshot: function(snapshot) {
			applySnapshot(snapshot);
		}
	};
})(this);
