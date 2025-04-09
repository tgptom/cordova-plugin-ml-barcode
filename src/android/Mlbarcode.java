package com.tgptom.cordova.plugin.mlbarcode;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import androidx.annotation.NonNull;

import android.provider.MediaStore;
import android.util.Base64;
import android.util.Log;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.barcode.BarcodeScanner;
import com.google.mlkit.vision.barcode.BarcodeScannerOptions;
import com.google.mlkit.vision.barcode.BarcodeScanning;
import com.google.mlkit.vision.barcode.common.Barcode;

import java.io.FileNotFoundException;
import java.util.Objects;


public class Mlbarcode extends CordovaPlugin {

    private static final int NORMFILEURI = 0; // Make bitmap without compression using uri from picture library (NORMFILEURI & NORMNATIVEURI have same functionality in android)
    private static final int NORMNATIVEURI = 1; // Make compressed bitmap using uri from picture library for faster ocr but might reduce accuracy (NORMFILEURI & NORMNATIVEURI have same functionality in android)
    private static final int FASTFILEURI = 2; // Make uncompressed bitmap using uri from picture library (FASTFILEURI & FASTFILEURI have same functionality in android)
    private static final int FASTNATIVEURI = 3; // Make compressed bitmap using uri from picture library for faster ocr but might reduce accuracy (FASTFILEURI & FASTFILEURI have same functionality in android)
    private static final int BASE64 = 4;  // send base64 image instead of uri

    @Override
    public boolean execute(String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {

        if (action.equals("getBarcode")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    try {
                            int argstype = NORMFILEURI;
                            String argimagestr = "";
                            int argscodetype = 0;
                        try
                        {
                            Log.d("args", args.toString());

                            argstype = args.getInt(0);
                            argimagestr = args.getString(1);
                            argscodetype = args.getInt(2);
                        }
                        catch(Exception e)
                        {
                            callbackContext.error("Argument error");
                            PluginResult r = new PluginResult(PluginResult.Status.ERROR);
                            callbackContext.sendPluginResult(r);
                        }
                        Bitmap bitmap= null;
                        Uri uri = null;
                        if(argstype==NORMFILEURI || argstype==NORMNATIVEURI||argstype==FASTFILEURI || argstype==FASTNATIVEURI)
                        {
                            try
                            {
                                if(!argimagestr.trim().equals(""))
                                {
                                        String imagestr = argimagestr;

                                        // code block that allows this plugin to directly work with document scanner plugin and camera plugin
                                        if(imagestr.substring(0,6).equals("file://"))
                                        {
                                            imagestr = argimagestr.replaceFirst("file://","");
                                        }

                                        uri = Uri.parse(imagestr);

                                        if((argstype==NORMFILEURI || argstype==NORMNATIVEURI)&& uri != null) // normal ocr
                                        {
                                            bitmap = MediaStore.Images.Media.getBitmap(cordova.getActivity().getBaseContext().getContentResolver(), uri);
                                        }
                                        else if((argstype==FASTFILEURI || argstype==FASTNATIVEURI) && uri != null) //fast ocr (might be less accurate)
                                        {
                                            bitmap = decodeBitmapUri(cordova.getActivity().getBaseContext(), uri);
                                        }

                                }
                                else
                                {
                                    callbackContext.error("Image Uri or Base64 string is empty");
                                    PluginResult r = new PluginResult(PluginResult.Status.ERROR);
                                    callbackContext.sendPluginResult(r);
                                }
                            }
                            catch (Exception e)
                            {
                                e.printStackTrace();
                                callbackContext.error("Exception");
                                PluginResult r = new PluginResult(PluginResult.Status.ERROR);
                                callbackContext.sendPluginResult(r);
                            }
                        }
                        else if (argstype==BASE64)
                        {
                            if(!argimagestr.trim().equals(""))
                            {
                                byte[] decodedString = Base64.decode(argimagestr, Base64.DEFAULT);
                                bitmap = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);
                            }
                            else
                            {
                                callbackContext.error("Image Uri or Base64 string is empty");
                                PluginResult r = new PluginResult(PluginResult.Status.ERROR);
                                callbackContext.sendPluginResult(r);
                            }
                        }
                        else
                        {
                            callbackContext.error("Non existent argument. Use 0, 1, 2, 3 or 4");
                            PluginResult r = new PluginResult(PluginResult.Status.ERROR);
                            callbackContext.sendPluginResult(r);
                        }

                        BarcodeScannerOptions options = new BarcodeScannerOptions.Builder().setBarcodeFormats(argscodetype).enableAllPotentialBarcodes().build();
                        BarcodeScanner barcodeScanner = BarcodeScanning.getClient(options);
                        if (bitmap != null)
                        {
                            InputImage image = InputImage.fromBitmap(bitmap,0);
                            barcodeScanner.process(image)
                                    .addOnSuccessListener(barcodes -> {
                                        try
                                        {
                                            JSONObject resultobj = new JSONObject();

                                            JSONArray codes = new JSONArray();

                                            if (barcodes.isEmpty()) {
                                                resultobj.put("foundBarcode", false);
                                            }else{
                                                
                                                resultobj.put("foundBarcode", true);

                                                for (Barcode barcode: barcodes) {
                                                    codes.put(barcode.getRawValue());
                                                }

                                                resultobj.put("codes", codes);
                                            }

                                            callbackContext.success(resultobj);
                                            PluginResult r = new PluginResult(PluginResult.Status.OK);
                                            callbackContext.sendPluginResult(r);

                                        }
                                        catch (JSONException e)
                                        {
                                            callbackContext.error(String.valueOf(e));
                                            PluginResult r = new PluginResult(PluginResult.Status.ERROR);
                                            callbackContext.sendPluginResult(r);
                                        }
                                    })
                                    .addOnFailureListener(
                                            new OnFailureListener() {
                                                @Override
                                                public void onFailure(@NonNull Exception e) {
                                                    callbackContext.error("Error with ML Kit");
                                                    PluginResult r = new PluginResult(PluginResult.Status.ERROR);
                                                    callbackContext.sendPluginResult(r);
                                                }
                                            });

                        }
                        else
                        {
                            callbackContext.error("Error in uri or base64 data!");
                            PluginResult r = new PluginResult(PluginResult.Status.ERROR);
                            callbackContext.sendPluginResult(r);
                        }
                    } catch (Exception e) {
                        callbackContext.error("Main loop Exception");
                        PluginResult r = new PluginResult(PluginResult.Status.ERROR);
                        callbackContext.sendPluginResult(r);
                    }
                }
            });

            return true;

        }
            return false;
    }


    private Bitmap decodeBitmapUri(Context ctx, Uri uri) throws FileNotFoundException
    {
        int targetW = 600;
        int targetH = 600;
        BitmapFactory.Options bmOptions = new BitmapFactory.Options();
        bmOptions.inJustDecodeBounds = true;
        BitmapFactory.decodeStream(ctx.getContentResolver().openInputStream(uri), null, bmOptions);
        int photoW = bmOptions.outWidth;
        int photoH = bmOptions.outHeight;

        int scaleFactor = Math.min(photoW / targetW, photoH / targetH);
        bmOptions.inJustDecodeBounds = false;
        bmOptions.inSampleSize = scaleFactor;

        return BitmapFactory.decodeStream(ctx.getContentResolver()
                .openInputStream(uri), null, bmOptions);
    }
}
