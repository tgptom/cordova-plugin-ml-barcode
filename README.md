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
        codeType: mlbarcode.CODE_TYPES.QR_CODE // Optional: barcode format filter (default: ALL_FORMATS)
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

Use one of the plugin constants below (or `0` for all formats). You can pass either a numeric value or constant name string (for example `"QR_CODE"`):

| Constant | Value |
|---|---|
| `mlbarcode.CODE_TYPES.ALL_FORMATS` | `0` |
| `mlbarcode.CODE_TYPES.CODE_128` | `1` |
| `mlbarcode.CODE_TYPES.CODE_39` | `2` |
| `mlbarcode.CODE_TYPES.CODE_93` | `4` |
| `mlbarcode.CODE_TYPES.CODABAR` | `8` |
| `mlbarcode.CODE_TYPES.DATA_MATRIX` | `16` |
| `mlbarcode.CODE_TYPES.EAN_13` | `32` |
| `mlbarcode.CODE_TYPES.EAN_8` | `64` |
| `mlbarcode.CODE_TYPES.ITF` | `128` |
| `mlbarcode.CODE_TYPES.QR_CODE` | `256` |
| `mlbarcode.CODE_TYPES.UPC_A` | `512` |
| `mlbarcode.CODE_TYPES.UPC_E` | `1024` |
| `mlbarcode.CODE_TYPES.PDF417` | `2048` |
| `mlbarcode.CODE_TYPES.AZTEC` | `4096` |

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
- The plugin declares `READ_EXTERNAL_STORAGE` through Android 12L so apps can request access when reading shared `file://` paths on legacy devices. It does not request the permission at runtime.
- Prefer `content://` URIs from Photo Picker or MediaStore on modern Android; these rely on URI grants and do not require storage permission.

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
