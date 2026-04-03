# Akari

Akari is a Swift tool for generating and exporting Adaptive HDR images with gain maps on macOS.

## Features

- Export Adaptive HDR as HEIF or JPEG
- Use Display P3 or sRGB output color spaces
- Support mono or RGB gain maps
- Resize the HDR input to match the SDR base when needed

## Requirements

- macOS 15.0 or newer
- Swift 6
- Swift Package Manager

## Usage

```bash
akari <sdr.tif> <hdr.tif> <output.{heic|heif|jpg|jpeg}> [p3|srgb] [mono|rgb]
```

## Examples

```bash
akari assets/SDR_base.tif assets/HDR_Layer.tif output.heic p3 mono
akari assets/SDR_base.tif assets/HDR_Layer.tif output.heic p3 rgb
akari assets/SDR_base.tif assets/HDR_Layer.tif output.jpg p3 rgb
```

## Project Structure

- `Package.swift`
- `Sources/akari/`
- `Tests/akariTests/`
- `assets/`
```

## 6) Quick one-shot shell script

This will apply the rename and rewrite `Package.swift` and `README.md` for you.

```bash
cd /Users/suhail/Library/CloudStorage/Dropbox/matrix/appledev/akari || exit 1

mv Sources/adaptive-hdr-encoder Sources/akari
mv Sources/akari/adaptive_hdr_encoder.swift Sources/akari/akari.swift

mv Tests/adaptive-hdr-encoderTests Tests/akariTests
mv Tests/akariTests/adaptive_hdr_encoderTests.swift Tests/akariTests/akariTests.swift

cat > Package.swift <<'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "akari",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "akari"
        ),
        .testTarget(
            name: "akariTests",
            dependencies: ["akari"]
        ),
    ]
)
EOF

python3 - <<'PY'
from pathlib import Path

main_file = Path("Sources/akari/akari.swift")
text = main_file.read_text()

text = text.replace("struct AdaptiveHDREncoder", "struct Akari")
text = text.replace("adaptive-hdr-encoder <", "akari <")
text = text.replace("adaptive-hdr-encoder myimage_sdr.tif myimage_hdr.tif out.heic p3 mono", "akari myimage_sdr.tif myimage_hdr.tif out.heic p3 mono")
text = text.replace("adaptive-hdr-encoder myimage_sdr.tif myimage_hdr.tif out.heic p3 rgb", "akari myimage_sdr.tif myimage_hdr.tif out.heic p3 rgb")
text = text.replace("adaptive-hdr-encoder myimage_sdr.tif myimage_hdr.tif out.jpg p3 rgb", "akari myimage_sdr.tif myimage_hdr.tif out.jpg p3 rgb")

main_file.write_text(text)

test_file = Path("Tests/akariTests/akariTests.swift")
if test_file.exists():
    test_text = test_file.read_text()
    test_text = test_text.replace("adaptive-hdr-encoderTests", "akariTests")
    test_text = test_text.replace("adaptive_hdr_encoderTests", "akariTests")
    test_text = test_text.replace("adaptive-hdr-encoder", "akari")
    test_text = test_text.replace("adaptive_hdr_encoder", "akari")
    test_file.write_text(test_text)
PY

cat > README.md <<'EOF'
# Akari

Akari is a Swift tool for generating and exporting Adaptive HDR images with gain maps on macOS.

## Features

- Export Adaptive HDR as HEIF or JPEG
- Use Display P3 or sRGB output color spaces
- Support mono or RGB gain maps
- Resize the HDR input to match the SDR base when needed

## Requirements

- macOS 15.0 or newer
- Swift 6
- Swift Package Manager

## Usage

```bash
akari <sdr.tif> <hdr.tif> <output.{heic|heif|jpg|jpeg}> [p3|srgb] [mono|rgb]
```

## Examples

```bash
akari assets/SDR_base.tif assets/HDR_Layer.tif output.heic p3 mono
akari assets/SDR_base.tif assets/HDR_Layer.tif output.heic p3 rgb
akari assets/SDR_base.tif assets/HDR_Layer.tif output.jpg p3 rgb
```

## Project Structure

- `Package.swift`
- `Sources/akari/`
- `Tests/akariTests/`
- `assets/`
EOF
```

## 7) Build and verify

```bash
swift package clean
swift build
swift test
swift run akari assets/SDR_base.tif assets/HDR_Layer.tif /tmp/output.heic p3 mono
```

## 8) Commit and push

```bash
git add .
git commit -m "Rename project from adaptive-hdr-encoder to akari"
git push
```

