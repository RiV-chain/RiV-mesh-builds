var riv = {
  partnerId: 1950,
  applicationName: 'RiV-Mesh App',
  nasOSName: 'My Cloud OS',
  useAuthNASRichScreen: true,
  basicEDWebsite: "https://github.com/RiV-chain/RiV-mesh",
  nasVisitEDWebsiteLogin: "https://github.com/RiV-chain/RiV-mesh",
  nasVisitEDWebsiteSignup: "https://github.com/RiV-chain/RiV-mesh",
  nasVisitEDWebsiteLoggedin: "https://github.com/RiV-chain/RiV-mesh",
  getNasAuthUrl: function () {
		return "/";
	}
};

function handleToken() {

	riv.nasLoginCall = function (nasLoginSuccess, nasLoginFailure) {
		/* encode function start */
		var ezEncodeChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

		function utf16to8(str)
		{
			var out, i, len, c;
			out = "";
			len = str.length;
			for (i = 0; i < len; i++) {
				c = str.charCodeAt(i);
				if ((c >= 0x0001) && (c <= 0x007F)) {
					out += str.charAt(i);
				} else if (c > 0x07FF) {
					out += String.fromCharCode(0xE0 | ((c >> 12) & 0x0F));
					out += String.fromCharCode(0x80 | ((c >> 6) & 0x3F));
					out += String.fromCharCode(0x80 | ((c >> 0) & 0x3F));

				} else {
					out += String.fromCharCode(0xC0 | ((c >> 6) & 0x1F));
					out += String.fromCharCode(0x80 | ((c >> 0) & 0x3F));
				}
			}
			return out;
		}

		function ezEncode(str)
		{
			var out, i, len;
			var c1, c2, c3;

			len = str.length;
			i = 0;
			out = "";
			while (i < len)
			{
				c1 = str.charCodeAt(i++) & 0xff;
				if (i == len)
				{
					out += ezEncodeChars.charAt(c1 >> 2);
					out += ezEncodeChars.charAt((c1 & 0x3) << 4);
					out += "==";
					break;
				}
				c2 = str.charCodeAt(i++);
				if (i == len)
				{
					out += ezEncodeChars.charAt(c1 >> 2);
					out += ezEncodeChars.charAt(((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4));
					out += ezEncodeChars.charAt((c2 & 0xF) << 2);
					out += "=";
					break;
				}
				c3 = str.charCodeAt(i++);
				out += ezEncodeChars.charAt(c1 >> 2);
				out += ezEncodeChars.charAt(((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4));
				out += ezEncodeChars.charAt(((c2 & 0xF) << 2) | ((c3 & 0xC0) >> 6));
				out += ezEncodeChars.charAt(c3 & 0x3F);
			}
			return out;
		}

		var d = new Date();
		d.setTime(d.getTime() + (30 * 60 * 1000));
		document.cookie = "wduser=" + encodeURIComponent($('username').value) + "; expires=" + d.toUTCString() + "; path=/";
		document.cookie = "wdpwd=" + encodeURIComponent(ezEncode(utf16to8($('password').value))) + "; expires=" + d.toUTCString() + "; path=/";
		fetch('api/self').then(function (response) {
			if (response.status === 200) {
				window.location.reload();
				checkError(response);
			} else {
				riv.nasLogoutCall();
				nasLoginFailure();
			}
		});
	};
	riv.nasLogoutCall = function() {
		document.cookie = "wduser=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/";
		document.cookie = "wdpwd=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/";
	};
	function getCookie(name) {
		var matches = document.cookie.match(new RegExp(
			"(?:^|; )" + name.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, '\\$1') + "=([^;]*)"
		));
		return matches ? decodeURIComponent(matches[1]) : undefined;
	}
	riv.getNasUser = function() {
		return getCookie('wduser');
	};
};

window.onload = handleToken;
