package com.tgptom.cordova.plugin.mlbarcode;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import androidx.annotation.NonNull;

import android.util.Base64;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.barcode.BarcodeScanner;
import com.google.mlkit.vision.barcode.BarcodeScannerOptions;
import com.google.mlkit.vision.barcode.BarcodeScanning;
import com.google.mlkit.vision.barcode.common.Barcode;

import java.io.FileNotFoundException;
import java.io.InputStream;

public class Mlbarcode extends CordovaPlugin {

    private static final int NORMFILEURI = 0; // Make bitmap without compression using uri from picture library (NORMFILEURI & NORMNATIVEURI have same functionality in android)
    private static final int NORMNATIVEURI = 1; // Make compressed bitmap using uri from picture library for faster ocr but might reduce accuracy (NORMFILEURI & NORMNATIVEURI have same functionality in android)
    private static final int FASTFILEURI = 2; // Make uncompressed bitmap using uri from picture library (FASTFILEURI & FASTFILEURI have same functionality in android)
    private static final int FASTNATIVEURI = 3; // Make compressed bitmap using uri from picture library for faster ocr but might reduce accuracy (FASTFILEURI & FASTFILEURI have same functionality in android)
    private static final int BASE64 = 4;  // send base64 image instead of uri
    private static final int ALLOWED_BARCODE_FORMATS =
            Barcode.FORMAT_CODE_128
                    | Barcode.FORMAT_CODE_39
                    | Barcode.FORMAT_CODE_93
                    | Barcode.FORMAT_CODABAR
                    | Barcode.FORMAT_DATA_MATRIX
                    | Barcode.FORMAT_EAN_13
                    | Barcode.FORMAT_EAN_8
                    | Barcode.FORMAT_ITF
                    | Barcode.FORMAT_QR_CODE
                    | Barcode.FORMAT_UPC_A
                    | Barcode.FORMAT_UPC_E
                    | Barcode.FORMAT_PDF417
                    | Barcode.FORMAT_AZTEC;

    @Override
    public boolean execute(String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {

        if (!action.equals("getBarcode")) {
            return false;
        }

        cordova.getThreadPool().execute(() -> {
            try {
                int argstype;
                String argimagestr;
                int argscodetype;
                try {
                    argstype = args.getInt(0);
                    argimagestr = args.getString(1);
                    argscodetype = args.getInt(2);
                } catch (Exception e) {
                    callbackContext.error("Argument error");
                    return;
                }

                Bitmap bitmap = null;
                if (argstype == NORMFILEURI || argstype == NORMNATIVEURI || argstype == FASTFILEURI || argstype == FASTNATIVEURI) {
                    if (argimagestr == null || argimagestr.trim().isEmpty()) {
                        callbackContext.error("Image Uri or Base64 string is empty");
                        return;
                    }

                    try {
                        String imagestr = argimagestr;
                        if (imagestr.startsWith("file://")) {
                            String filePath = imagestr.substring(7);
                            if (argstype == NORMFILEURI || argstype == NORMNATIVEURI) {
                                bitmap = BitmapFactory.decodeFile(filePath);
                            } else {
                                bitmap = decodeBitmapFile(filePath);
                            }
                        } else {
                            Uri uri = Uri.parse(imagestr);
                            if (uri != null) {
                                if (argstype == NORMFILEURI || argstype == NORMNATIVEURI) {
                                    try (InputStream is = cordova.getActivity().getBaseContext().getContentResolver().openInputStream(uri)) {
                                        if (is != null) {
                                            bitmap = BitmapFactory.decodeStream(is);
                                        }
                                    }
                                } else {
                                    bitmap = decodeBitmapUri(cordova.getActivity().getBaseContext(), uri);
                                }
                            }
                        }
                    } catch (Exception e) {
                        callbackContext.error("Exception");
                        return;
                    }
                } else if (argstype == BASE64) {
                    if (argimagestr == null || argimagestr.trim().isEmpty()) {
                        callbackContext.error("Image Uri or Base64 string is empty");
                        return;
                    }
                    try {
                        byte[] decodedString = Base64.decode(argimagestr, Base64.DEFAULT);
                        bitmap = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);
                    } catch (IllegalArgumentException e) {
                        callbackContext.error("Invalid Base64 image data");
                        return;
                    }
                } else {
                    callbackContext.error("Non existent argument. Use 0, 1, 2, 3 or 4");
                    return;
                }

                if (bitmap == null) {
                    callbackContext.error("Error in uri or base64 data!");
                    return;
                }

                BarcodeScannerOptions options = new BarcodeScannerOptions.Builder()
                        .setBarcodeFormats(sanitizeBarcodeFormats(argscodetype))
                        .enableAllPotentialBarcodes()
                        .build();
                BarcodeScanner barcodeScanner = BarcodeScanning.getClient(options);
                InputImage image = InputImage.fromBitmap(bitmap, 0);
                barcodeScanner.process(image)
                        .addOnSuccessListener(barcodes -> {
                            try {
                                JSONObject resultobj = new JSONObject();
                                JSONArray codes = new JSONArray();

                                for (Barcode barcode : barcodes) {
                                    if (barcode.getRawValue() != null) {
                                        codes.put(barcode.getRawValue());
                                    }
                                }

                                boolean foundBarcode = codes.length() > 0;
                                resultobj.put("foundBarcode", foundBarcode);
                                if (foundBarcode) {
                                    resultobj.put("codes", codes);
                                }
                                callbackContext.success(resultobj);
                            } catch (JSONException e) {
                                callbackContext.error(String.valueOf(e));
                            }
                        })
                        .addOnFailureListener(new OnFailureListener() {
                            @Override
                            public void onFailure(@NonNull Exception e) {
                                callbackContext.error("Error with ML Kit");
                            }
                        })
                        .addOnCompleteListener(new OnCompleteListener<java.util.List<Barcode>>() {
                            @Override
                            public void onComplete(@NonNull Task<java.util.List<Barcode>> task) {
                                barcodeScanner.close();
                            }
                        });
            } catch (Exception e) {
                callbackContext.error("Main loop Exception");
            }
        });

        return true;
    }


    private Bitmap decodeBitmapFile(String filePath)
    {
        int targetW = 600;
        int targetH = 600;
        BitmapFactory.Options bmOptions = new BitmapFactory.Options();
        bmOptions.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(filePath, bmOptions);
        int photoW = bmOptions.outWidth;
        int photoH = bmOptions.outHeight;

        if (photoW <= 0 || photoH <= 0) {
            return null;
        }

        int scaleFactor = Math.min(photoW / targetW, photoH / targetH);
        if (scaleFactor < 1) {
            scaleFactor = 1;
        }
        bmOptions.inJustDecodeBounds = false;
        bmOptions.inSampleSize = scaleFactor;

        return BitmapFactory.decodeFile(filePath, bmOptions);
    }

    private Bitmap decodeBitmapUri(Context ctx, Uri uri) throws FileNotFoundException
    {
        int targetW = 600;
        int targetH = 600;
        BitmapFactory.Options bmOptions = new BitmapFactory.Options();
        bmOptions.inJustDecodeBounds = true;
        try (InputStream boundsStream = ctx.getContentResolver().openInputStream(uri)) {
            BitmapFactory.decodeStream(boundsStream, null, bmOptions);
        }
        int photoW = bmOptions.outWidth;
        int photoH = bmOptions.outHeight;

        if (photoW <= 0 || photoH <= 0) {
            return null;
        }

        int scaleFactor = Math.min(photoW / targetW, photoH / targetH);
        if (scaleFactor < 1) {
            scaleFactor = 1;
        }
        bmOptions.inJustDecodeBounds = false;
        bmOptions.inSampleSize = scaleFactor;

        try (InputStream decodeStream = ctx.getContentResolver().openInputStream(uri)) {
            return BitmapFactory.decodeStream(decodeStream, null, bmOptions);
        }
    }

    private int sanitizeBarcodeFormats(int rawFormats) {
        if (rawFormats <= 0) {
            return Barcode.FORMAT_ALL_FORMATS;
        }
        int sanitized = rawFormats & ALLOWED_BARCODE_FORMATS;
        return sanitized == 0 ? Barcode.FORMAT_ALL_FORMATS : sanitized;
    }
}
