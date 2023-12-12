#import <Cordova/CDV.h>
@import MLKitBarcodeScanning;

@interface Mlbarcode : CDVPlugin

@property CDVInvokedUrlCommand* commandglo;
// @property GMVDetector* textDetector;
@property UIImage* image;

- (void) getBarcode:(CDVInvokedUrlCommand*)command;
- (UIImage *)resizeImage:(UIImage *)image;
- (NSData *)retrieveAssetDataPhotosFramework:(NSURL *)urlMedia;

@end
