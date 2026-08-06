#import <Cordova/CDV.h>
@import MLKitBarcodeScanning;

@interface Mlbarcode : CDVPlugin

- (void) getBarcode:(CDVInvokedUrlCommand*)command;
- (UIImage *)resizeImage:(UIImage *)image;
- (NSData *)retrieveAssetDataPhotosFramework:(NSURL *)urlMedia;

@end
