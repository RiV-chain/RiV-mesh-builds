var riv = {
	partnerId: 1126,
	brand: 'RiV Mesh',
	applicationName: 'RiV Mesh Synology DSM App',
	useAuthNASRichScreen: true,
	nasOSName: 'Synology DSM',
	nasVisitEDWebsiteLogin: "https://github.com/RiV-chain/RiV-mesh",
	nasVisitEDWebsiteSignup: "https://github.com/RiV-chain/RiV-mesh",
	nasVisitEDWebsiteLoggedin: "https://github.com/RiV-chain/RiV-mesh",
	getCookie: function (name) {
		var matches = document.cookie.match(new RegExp(
			"(?:^|; )" + name.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, '\\$1') + "=([^;]*)"
		));
		return matches ? decodeURIComponent(matches[1]) : undefined;
	},
	setCookie: function (key, value, expires) {
		if(expires) {
			var d = new Date();
			d.setTime(d.getTime() + (30 * 60 * 1000));
			expires = "; expires=" + d.toUTCString();
		} else {
			expires = "";
		}
		document.cookie = key + "=" + value + expires + "; path=/";
	},
	getNasAuthUrl: function () {
		riv.setCookie('RiVSynoToken', "");
		var url = riv.getCookie('origin');
		if (url === undefined) {
			url = window.location.protocol + "//" + window.location.hostname + ":" + 5000;
		}
		return url;
	}
};

function params(obj) {
	if (typeof obj === 'string') {
		if (obj[0] === '?') {
			obj = obj.substring(1);
		}
		var result = {};
		obj = obj.split("&");
		obj.forEach(function (pair) {
			pair = pair.split("=");
			var key = decodeURIComponent(pair[0]);
			var value = decodeURIComponent(pair[1]);
			// If first entry with this name
			if (typeof result[key] === "undefined") {
				result[key] = value;
				// If second entry with this name
			} else if (typeof result[key] === "string") {
				result[key] = [result[key], value];
				// If third or later entry with this name
			} else {
				result[key].push(value);
			}
		});
		return result;
	} else {
		return Object.keys(obj).map(function (key) {
			return encodeURIComponent(key) + '=' + encodeURIComponent(obj[key]);
		}).join('&');
	}
};

function handleToken(){
	//Hide URL parameters
	var query = params(window.location.search.substring(1));
	var refresh = false;
	for (var k in query) {
		if (k === 'SynoToken') {
			riv.setCookie('RiVSynoToken', query[k]);
			refresh = true;
			delete query[k];
		} else if (k === 'origin') {
			riv.setCookie('origin', query[k]);
			refresh = true;
			delete query[k];
		}
	}

	query = Object.keys(query).map(function(k) {
		return encodeURIComponent(k) + '=' + encodeURIComponent(query[k])
	}).join('&');

	if (refresh)
		window.location.replace(window.location.origin + window.location.pathname + window.location.hash + ((query === "") ? "" : ("?" + query)));

};

window.onload = handleToken;