#import "Mlbarcode.h"
#import <Photos/Photos.h>
#import <MLKitVision/MLKitVision.h>

@implementation Mlbarcode
#define NORMFILEURI ((int) 0)
#define NORMNATIVEURI ((int) 1)
#define FASTFILEURI ((int) 2)
#define FASTNATIVEURI ((int) 3)
#define BASE64 ((int) 4)

- (void)getBarcode:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        @try
        {
            self.commandglo = command;
            int stype = NORMFILEURI; // sourceType
            NSString* name;
            int ctype = 0;
            self.image = NULL;
            @try {
                NSString *st =[self.commandglo argumentAtIndex:0 withDefault:@(0)];
                stype = [st intValue];
                name = [self.commandglo argumentAtIndex:1];
                NSString *ct =[self.commandglo argumentAtIndex:2 withDefault:@(0)];
                ctype = [ct intValue];
            }
            @catch (NSException *exception) {
                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_ERROR
                                           messageAsString:@"argument/parameter type mismatch error"];
                [self.commandDelegate sendPluginResult:result callbackId:self.commandglo.callbackId];
            }
            
            if (stype == NORMFILEURI || stype == NORMNATIVEURI || stype == FASTFILEURI || stype == FASTNATIVEURI)
            {
                if (stype==NORMFILEURI)
                {
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:name]];
                    self.image = [UIImage imageWithData:imageData];
                }
                else if (stype==NORMNATIVEURI)
                {
                    NSString *urlString = [NSString stringWithFormat:@"%@", name];
                    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
                    NSData *imageData = [self retrieveAssetDataPhotosFramework:url];
                    self.image = [UIImage imageWithData:imageData];
                }
                else if (stype==FASTFILEURI)
                {
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:name]];
                    self.image = [UIImage imageWithData:imageData];
                    self.image = [self resizeImage:self.image];
                }
                else if (stype==FASTNATIVEURI)
                {
                    NSString *urlString = [NSString stringWithFormat:@"%@", name];
                    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
                    NSData *imageData = [self retrieveAssetDataPhotosFramework:url];
                    self.image = [UIImage imageWithData:imageData];
                    self.image = [self resizeImage:self.image];
                }
                
            }
            else if (stype==BASE64)
            {
                NSData *data = [[NSData alloc]initWithBase64EncodedString:name options:NSDataBase64DecodingIgnoreUnknownCharacters];
                self.image = [UIImage imageWithData:data];
            }
            else
            {
                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_ERROR
                                           messageAsString:@"sourceType argument should be 0,1,2,3 or 4"];
                [self.commandDelegate sendPluginResult:result callbackId:self.commandglo.callbackId];
            }
            
            
            if (self.image!=NULL)
            {
                MLKBarcodeFormat format = ctype; // MLKBarcodeFormatAll
                MLKBarcodeScannerOptions *barcodeOptions = [[MLKBarcodeScannerOptions alloc] initWithFormats:format];
                MLKBarcodeScanner *barcodeScanner = [MLKBarcodeScanner barcodeScannerWithOptions:barcodeOptions];

                MLKVisionImage *image = [[MLKVisionImage alloc] initWithImage:self.image];
                [barcodeScanner processImage:image
                                completion:^(NSArray<MLKBarcode *> *_Nullable barcodes,
                                             NSError *_Nullable error) {
                                      NSMutableDictionary* resultobjmut = [[NSMutableDictionary alloc] init];             
                                      if (error != nil || result == nil) {
                                          if (result==nil) {
                                            NSNumber *foundBarcode = @NO;
                                            resultobjmut = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                                            foundBarcode,@"foundBarcode", nil] mutableCopy];
                                            NSDictionary *resultobj = [NSDictionary dictionaryWithDictionary:resultobjmut];
                                            
                                            CDVPluginResult* resultcor = [CDVPluginResult
                                                                        resultWithStatus:CDVCommandStatus_OK
                                                                        messageAsDictionary:resultobj];
                                            [self.commandDelegate sendPluginResult:resultcor callbackId:_commandglo.callbackId];

                                            //   CDVPluginResult* resulta = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No text found in image"];
                                            //   [self.commandDelegate sendPluginResult:resulta callbackId: self.commandglo.callbackId];
                                          }
                                          else
                                          {
                                              CDVPluginResult* resulta = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error with Text Recognition Module"];
                                              [self.commandDelegate sendPluginResult:resulta callbackId: self.commandglo.callbackId];
                                          }
                                      }
                                      
                                      NSMutableArray* codes = [[NSMutableArray alloc] init];

                                      for (MLKBarcode *barcode in barcodes) {
                                          [codes addObject:barcode.rawValue];
                                      }

                                      NSNumber *foundBarcode = @YES;
                                      resultobjmut = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                                       foundBarcode,@"foundBarcode",
                                                       codes,@"codes", nil] mutableCopy];

                                      NSDictionary *resultobj = [NSDictionary dictionaryWithDictionary:resultobjmut];
                                      
                                      CDVPluginResult* resultcor = [CDVPluginResult
                                                                    resultWithStatus:CDVCommandStatus_OK
                                                                    messageAsDictionary:resultobj];
                    [self.commandDelegate sendPluginResult:resultcor callbackId: self.commandglo.callbackId];
                                  }];
            }
            else
            {
                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_ERROR
                                           messageAsString:@"Error in uri or base64 data!"];
                [self.commandDelegate sendPluginResult:result callbackId: self.commandglo.callbackId];
            }
        }
        @catch (NSException *exception)
        {
            CDVPluginResult* result = [CDVPluginResult
                                       resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"Main loop Exception"];
            [self.commandDelegate sendPluginResult:result callbackId: self.commandglo.callbackId];
        }
    }];
}


-(UIImage *)resizeImage:(UIImage *)image
{
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
    
    PHFetchResult *result = [PHAsset fetchAssetsWithALAssetURLs:@[urlMedia] options:nil];
    PHAsset *asset = [result firstObject];
    if (asset != nil)
    {
        PHImageManager *imageManager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
        options.synchronous = YES;
        options.version = PHImageRequestOptionsVersionCurrent;
        
        @autoreleasepool {
            [imageManager requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                iData = [imageData copy];
            }];
        }
        //assert(iData.length != 0);
        return iData;
    }
    else
    {
        return NULL;
    }
    
}

@end
