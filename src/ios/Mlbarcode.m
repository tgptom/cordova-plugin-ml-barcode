#import "Mlbarcode.h"
#import <Photos/Photos.h>
#import <MLKitVision/MLKitVision.h>

@implementation Mlbarcode
#define NORMFILEURI ((int) 0)
#define NORMNATIVEURI ((int) 1)
#define FASTFILEURI ((int) 2)
#define FASTNATIVEURI ((int) 3)
#define BASE64 ((int) 4)
#define ALLOWED_BARCODE_FORMATS (MLKBarcodeFormatCode128 | MLKBarcodeFormatCode39 | MLKBarcodeFormatCode93 | MLKBarcodeFormatCodaBar | MLKBarcodeFormatDataMatrix | MLKBarcodeFormatEAN13 | MLKBarcodeFormatEAN8 | MLKBarcodeFormatITF | MLKBarcodeFormatQRCode | MLKBarcodeFormatUPCA | MLKBarcodeFormatUPCE | MLKBarcodeFormatPDF417 | MLKBarcodeFormatAztec)

- (void)getBarcode:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        @try
        {
            int stype = NORMFILEURI; // sourceType
            NSString* name = nil;
            int ctype = 0;
            UIImage *imageToScan = nil;
            @try {
                NSNumber *st = [command argumentAtIndex:0 withDefault:@(0)];
                stype = [st intValue];
                name = [command argumentAtIndex:1];
                NSNumber *ct = [command argumentAtIndex:2 withDefault:@(0)];
                ctype = [ct intValue];
            }
            @catch (NSException *exception) {
                CDVPluginResult* result = [CDVPluginResult
                                          resultWithStatus:CDVCommandStatus_ERROR
                                          messageAsString:@"argument/parameter type mismatch error"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                return;
            }
            
            if (stype == NORMFILEURI || stype == NORMNATIVEURI || stype == FASTFILEURI || stype == FASTNATIVEURI)
            {
                if (name == nil || name.length == 0) {
                    CDVPluginResult* result = [CDVPluginResult
                                              resultWithStatus:CDVCommandStatus_ERROR
                                              messageAsString:@"Image Uri or Base64 string is empty"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    return;
                }
                if (stype==NORMFILEURI)
                {
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:name]];
                    imageToScan = [UIImage imageWithData:imageData];
                }
                else if (stype==NORMNATIVEURI)
                {
                    NSString *urlString = [NSString stringWithFormat:@"%@", name];
                    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
                    NSData *imageData = [self retrieveAssetDataPhotosFramework:url];
                    imageToScan = [UIImage imageWithData:imageData];
                }
                else if (stype==FASTFILEURI)
                {
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:name]];
                    imageToScan = [UIImage imageWithData:imageData];
                    imageToScan = [self resizeImage:imageToScan];
                }
                else if (stype==FASTNATIVEURI)
                {
                    NSString *urlString = [NSString stringWithFormat:@"%@", name];
                    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
                    NSData *imageData = [self retrieveAssetDataPhotosFramework:url];
                    imageToScan = [UIImage imageWithData:imageData];
                    imageToScan = [self resizeImage:imageToScan];
                }
                
            }
            else if (stype==BASE64)
            {
                if (name == nil || name.length == 0) {
                    CDVPluginResult* result = [CDVPluginResult
                                              resultWithStatus:CDVCommandStatus_ERROR
                                              messageAsString:@"Image Uri or Base64 string is empty"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    return;
                }
                NSData *data = [[NSData alloc]initWithBase64EncodedString:name options:NSDataBase64DecodingIgnoreUnknownCharacters];
                imageToScan = [UIImage imageWithData:data];
            }
            else
            {
                CDVPluginResult* result = [CDVPluginResult
                                          resultWithStatus:CDVCommandStatus_ERROR
                                          messageAsString:@"sourceType argument should be 0,1,2,3 or 4"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                return;
            }
            
            
            if (imageToScan != nil)
            {
                MLKBarcodeFormat format = [self sanitizeBarcodeFormats:ctype];
                MLKBarcodeScannerOptions *barcodeOptions = [[MLKBarcodeScannerOptions alloc] initWithFormats:format];
                MLKBarcodeScanner *barcodeScanner = [MLKBarcodeScanner barcodeScannerWithOptions:barcodeOptions];

                MLKVisionImage *image = [[MLKVisionImage alloc] initWithImage:imageToScan];
                image.orientation = imageToScan.imageOrientation;
                [barcodeScanner processImage:image
                                completion:^(NSArray<MLKBarcode *> *_Nullable barcodes,
                                            NSError *_Nullable error) {
                                      NSMutableDictionary* resultobjmut = [[NSMutableDictionary alloc] init];             
                                      if (error != nil) {
                                          CDVPluginResult* resulta = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error with Barcode Scanning Module"];
                                          [self.commandDelegate sendPluginResult:resulta callbackId:command.callbackId];
                                          return;
                                      }

                                      if (barcodes == nil || barcodes.count == 0) {
                                          NSNumber *foundBarcode = @NO;
                                          resultobjmut = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                                          foundBarcode,@"foundBarcode", nil] mutableCopy];
                                          NSDictionary *resultobj = [NSDictionary dictionaryWithDictionary:resultobjmut];
                                           
                                          CDVPluginResult* resultcor = [CDVPluginResult
                                                                      resultWithStatus:CDVCommandStatus_OK
                                                                      messageAsDictionary:resultobj];
                                          [self.commandDelegate sendPluginResult:resultcor callbackId:command.callbackId];
                                      }
                                      else
                                      {
                                        NSMutableArray* codes = [[NSMutableArray alloc] init];

                                        for (MLKBarcode *barcode in barcodes) {
                                            if (barcode.rawValue != nil) {
                                                [codes addObject:barcode.rawValue];
                                            }
                                        }

                                        NSNumber *foundBarcode = @(codes.count > 0);
                                        if (codes.count > 0) {
                                            resultobjmut = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                                            foundBarcode,@"foundBarcode",
                                                            codes,@"codes", nil] mutableCopy];
                                        } else {
                                            resultobjmut = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                                            foundBarcode,@"foundBarcode", nil] mutableCopy];
                                        }

                                        NSDictionary *resultobj = [NSDictionary dictionaryWithDictionary:resultobjmut];
                                         
                                        CDVPluginResult* resultcor = [CDVPluginResult
                                                                        resultWithStatus:CDVCommandStatus_OK
                                                                        messageAsDictionary:resultobj];
                                            [self.commandDelegate sendPluginResult:resultcor callbackId:command.callbackId];
                                      }
                                  }];
            }
            else
            {
                CDVPluginResult* result = [CDVPluginResult
                                          resultWithStatus:CDVCommandStatus_ERROR
                                          messageAsString:@"Error in uri or base64 data!"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        }
        @catch (NSException *exception)
        {
            CDVPluginResult* result = [CDVPluginResult
                                      resultWithStatus:CDVCommandStatus_ERROR
                                      messageAsString:@"Main loop Exception"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    }];
}

-(MLKBarcodeFormat)sanitizeBarcodeFormats:(NSInteger)rawFormats
{
    if (rawFormats <= 0) {
        return MLKBarcodeFormatAll;
    }
    NSInteger sanitized = rawFormats & ALLOWED_BARCODE_FORMATS;
    if (sanitized == 0) {
        return MLKBarcodeFormatAll;
    }
    return (MLKBarcodeFormat)sanitized;
}


-(UIImage *)resizeImage:(UIImage *)image
{
    if (image == nil) {
        return nil;
    }
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float maxHeight = 600;
    float maxWidth = 600;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = maxWidth/maxHeight;
    float compressionQuality = 0.50;//50 percent compression
    
    if (actualHeight > maxHeight || actualWidth > maxWidth)
    {
        if(imgRatio < maxRatio)
        {
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if(imgRatio > maxRatio)
        {
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }
        else
        {
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    NSData *imageData = UIImageJPEGRepresentation(img, compressionQuality);
    UIGraphicsEndImageContext();
    return [UIImage imageWithData:imageData];
    
}

-(NSData *)retrieveAssetDataPhotosFramework:(NSURL *)urlMedia
{
    __block NSData *iData = nil;
    
    PHFetchResult *result = nil;
    
    // Handle modern ph:// photo library URLs.
    // The ph:// scheme uses the PHAsset local identifier as the resource specifier,
    // e.g. "ph://CC95F08C-88C3-4012-9D6D-64A413D254B3/L0/001".
    if ([urlMedia.scheme isEqualToString:@"ph"]) {
        NSString *urlString = urlMedia.absoluteString;
        if ([urlString hasPrefix:@"ph://"]) {
            NSString *localIdentifier = [urlString substringFromIndex:[@"ph://" length]];
            localIdentifier = [localIdentifier stringByRemovingPercentEncoding];
            if (localIdentifier && localIdentifier.length > 0) {
                result = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
            }
        }
    } else {
        // Fall back to the assets-library:// (ALAsset) URL style
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        result = [PHAsset fetchAssetsWithALAssetURLs:@[urlMedia] options:nil];
#pragma clang diagnostic pop
    }
    
    PHAsset *asset = [result firstObject];
    if (asset != nil)
    {
        PHImageManager *imageManager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
        options.synchronous = YES;
        options.version = PHImageRequestOptionsVersionCurrent;
        
        @autoreleasepool {
            if (@available(iOS 13.0, *)) {
                [imageManager requestImageDataAndOrientationForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, CGImagePropertyOrientation orientation, NSDictionary *info) {
                    iData = [imageData copy];
                }];
            } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [imageManager requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                    iData = [imageData copy];
                }];
#pragma clang diagnostic pop
            }
        }
        return iData;
    }
    else
    {
        return NULL;
    }
    
}

@end
