/*global cordova, module*/

var IMG_TYPES = {
    NORMFILEURI: 0,
    NORMNATIVEURI: 1,
    FASTFILEURI: 2,
    FASTNATIVEURI: 3,
    BASE64: 4
};

var CODE_TYPES = {
    ALL_FORMATS: 0,
    CODE_128: 1,
    CODE_39: 2,
    CODE_93: 4,
    CODABAR: 8,
    DATA_MATRIX: 16,
    EAN_13: 32,
    EAN_8: 64,
    ITF: 128,
    QR_CODE: 256,
    UPC_A: 512,
    UPC_E: 1024,
    PDF417: 2048,
    AZTEC: 4096
};

function normalizeCodeType(codeType) {
    if (typeof codeType === "number") {
        return codeType;
    }
    if (typeof codeType === "string" && Object.prototype.hasOwnProperty.call(CODE_TYPES, codeType)) {
        return CODE_TYPES[codeType];
    }
    return CODE_TYPES.ALL_FORMATS;
}

module.exports = {
    IMG_TYPES: IMG_TYPES,
    CODE_TYPES: CODE_TYPES,
    getBarcode: function (successCallback, errorCallback, options) {
    	options = options || {};
		
    	if(options.imgSrc)
    	{
			var imgType = typeof options.imgType === "number" ? options.imgType : IMG_TYPES.NORMFILEURI;
			var imgSrc = options.imgSrc;
			var codeType = normalizeCodeType(options.codeType);
			var args = [imgType, imgSrc, codeType];
			
        	cordova.exec(successCallback, errorCallback, "Mlbarcode", "getBarcode", args);
    	}
    	else
    	{
            if (typeof errorCallback === "function") {
                errorCallback("No Uri or Base64 passed into the plugin. Please provide a value for imgSrc");
            }
    	}
    }
};