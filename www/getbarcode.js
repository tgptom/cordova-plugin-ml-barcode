/*global cordova, module*/

module.exports = {
    getBarcode: function (successCallback, errorCallback, options) {
    	options = options || {};
    	var imgType = options.imgType || 0;	// 0 NORMFILEURI, 1 NORMNATIVEURI, 2 FASTFILEURI, 3 FASTNATIVEURI, 4 BASE64
		
    	if(options.imgSrc)
    	{
			var imgType = options.imgType || 0;
			var imgSrc = options.imgSrc;
			var codeType = options.codeType || 0;
			var args = [imgType, imgSrc, codeType];
			
        	cordova.exec(successCallback, errorCallback, "Mlbarcode", "getBarcode", args);
    	}
    	else
    	{
    		alert("No Uri or Base64 passed into the plugin. Please provide a value for imgsrc");
    	}
    }
};