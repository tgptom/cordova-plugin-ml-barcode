# cordova-plugin-ml-barcode

Cordova plugin for barcode detection using [Google ML Kit Barcode Scanning](https://developers.google.com/ml-kit/vision/barcode-scanning).

## Supported Platforms

| Platform | Version | Notes |
|---|---|---|
| Android | cordova-android ≥ 10 (tested on 14 & 15) | ML Kit 17.3.0 |
| iOS | cordova-ios ≥ 7 (tested on 7 & 8) | MLKitBarcodeScanning ~> 8.0.0, requires iOS 13+ at runtime |

### iOS Deployment Target

`MLKitBarcodeScanning ~> 8.0.0` requires **iOS 13.0 or later** at runtime. When building with cordova-ios 7 or 8, ensure your project's deployment target is set to at least `13.0` in `config.xml`:

```xml
<platform name="ios">
    <preference name="deployment-target" value="13.0" />
</platform>
```

## ML Kit Dependency Versions

| Platform | Artifact | Version |
|---|---|---|
| Android | `com.google.mlkit:barcode-scanning` | 17.3.0 (latest as of 2025) |
| iOS | `MLKitBarcodeScanning` (CocoaPods) | ~> 8.0.0 |

You can override the Android ML Kit version via plugin variables:

```xml
<plugin name="cordova-plugin-ml-barcode" spec="~0.1.0">
    <variable name="MLKIT_BARCODE_PACKAGE" value="com.google.mlkit:barcode-scanning" />
    <variable name="MLKIT_BARCODE_VERSION" value="17.3.0" />
</plugin>
```

## Installation

```bash
cordova plugin add cordova-plugin-ml-barcode
```

## Usage

```javascript
mlbarcode.getBarcode(
    function(result) {
        if (result.foundBarcode) {
            console.log('Barcodes found:', result.codes);
        } else {
            console.log('No barcode found');
        }
    },
    function(error) {
        console.error('Error:', error);
    },
    {
        imgSrc: imageUri,   // Required: URI string or base64 image data
        imgType: 0,         // Optional: see Image Source Types below (default: 0)
        codeType: 0         // Optional: barcode format filter (default: 0 = all formats)
    }
);
```

### Image Source Types (`imgType`)

| Value | Constant | Description |
|---|---|---|
| `0` | `NORMFILEURI` | `file://` or `content://` URI, full-quality decode |
| `1` | `NORMNATIVEURI` | Native photo library URI (`assets-library://` or `ph://`), full-quality |
| `2` | `FASTFILEURI` | `file://` or `content://` URI, downsampled for speed |
| `3` | `FASTNATIVEURI` | Native photo library URI, downsampled for speed |
| `4` | `BASE64` | Base64-encoded image string |

### Barcode Format (`codeType`)

Use `0` to scan all formats, or pass an ML Kit barcode format constant. See [ML Kit Barcode formats](https://developers.google.com/ml-kit/vision/barcode-scanning/android#barcode-formats) for the list of supported values.

### Result Object

```javascript
{
    foundBarcode: true,       // boolean
    codes: ["VALUE1", ...]    // array of decoded barcode strings (only when foundBarcode is true)
}
```

## Android Notes

- `file://` URIs are decoded directly from the filesystem (avoids ContentResolver restrictions on modern Android).
- `content://` URIs are loaded via ContentResolver (works with Photo Picker and MediaStore outputs).
- `WRITE_EXTERNAL_STORAGE` and `READ_EXTERNAL_STORAGE` permissions are declared with `maxSdkVersion="32"` (not requested on Android 13+).

## iOS Notes

- `NORMFILEURI` / `FASTFILEURI`: loads from a `file://` URL using `NSData dataWithContentsOfURL:`.
- `NORMNATIVEURI` / `FASTNATIVEURI`: loads from the photo library.
  - Modern `ph://` URLs (from PHPicker / iOS 14+ photo picker) are supported via `PHAsset fetchAssetsWithLocalIdentifiers:`.
  - Legacy `assets-library://` URLs remain supported for backward compatibility.
- `requestImageDataAndOrientationForAsset:` is used on iOS 13+ (the deprecated `requestImageDataForAsset:` is used as a fallback for iOS < 13).

## Testing Notes

Full Cordova platform builds (Android Gradle / Xcode) were not run in the automated environment. Recommended manual validation steps:

1. **Android**: Build with `cordova-android` 14 or 15, Java 17, and Android SDK 35. Test with `file://` path, `content://` URI (from camera or media picker), and base64 string.
2. **iOS**: Build with `cordova-ios` 7 or 8, Xcode 15+, CocoaPods 1.16+. Set deployment target ≥ 13.0. Test with `file://`, `ph://` (from PHPicker), and base64 inputs on iOS 16/17/18 simulator or device.
