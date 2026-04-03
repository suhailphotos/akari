# Akari

Akari is a Swift command line tool for authoring Apple-style Adaptive HDR still images on macOS.

The current goal of the project is to take two authored source images:

- an SDR base image
- an HDR alternate image

and encode them using Apple's own Core Image export path so the result behaves as closely as possible to native Apple HDR stills on Apple devices.

## Why this project exists

The practical problem Akari is trying to solve is not just "how do I make an HDR file," but:

- how to author Adaptive HDR the Apple way
- how to preserve a controlled SDR base image
- how to test mono versus RGB gain maps
- how to compare Apple device behavior versus Instagram behavior
- how to understand what headroom works best in the real world

In testing so far, different sharing paths behave very differently:

- iPhone / Instagram app can preserve HDR presentation better, but may rebuild or ignore the authored SDR base
- web upload can preserve the authored SDR base better, but may drop HDR behavior
- Apple Photos on iPhone may show HDR where macOS apps show a more SDR-like rendering

So Akari is also a research tool for understanding those differences.

## Current scope

Akari currently supports:

- Apple Adaptive HDR export using Core Image
- HEIF / HEIC output
- JPEG output
- Display P3 or sRGB output color spaces
- mono gain map generation
- RGB gain map generation
- automatic resizing of the HDR image to match the SDR base when needed

## Current workflow

Author two images from the same source composition in Photoshop or another grading tool:

1. `SDR base`
   - the exact display-referred SDR appearance you want preserved
2. `HDR alternate`
   - a brighter HDR version of the same image

Then pass both into Akari to generate an Adaptive HDR file.

## Usage

```bash
akari <sdr.tif> <hdr.tif> <output.{heic|heif|jpg|jpeg}> [p3|srgb] [mono|rgb]
```

## Examples

From the project root:

```bash
.build/release/akari \
  assets/SDR_base_1080.tif \
  assets/HDR_Layer_1080.tif \
  assets/output_p3_1080_mono.heic \
  p3 \
  mono
```

```bash
.build/release/akari \
  assets/SDR_base_1080.tif \
  assets/HDR_Layer_1080.tif \
  assets/output_p3_1080_rgb.heic \
  p3 \
  rgb
```

```bash
.build/release/akari \
  assets/SDR_base_1080.tif \
  assets/HDR_Layer_1080.tif \
  assets/output_p3_1080_rgb.jpg \
  p3 \
  rgb
```

If you want to run the executable through SwiftPM:

```bash
swift run akari \
  assets/SDR_base_1080.tif \
  assets/HDR_Layer_1080.tif \
  assets/output_p3_1080_mono.heic \
  p3 \
  mono
```

## Build

```bash
swift package clean
swift build -c release
```

Binary path after release build:

```bash
.build/release/akari
```

## Inputs

Recommended source inputs:

- SDR base: 16-bit TIFF
- HDR alternate: 32-bit TIFF
- matching dimensions
- matching composition and framing
- exported intentionally from the same master file

Recommended starting color space:

- Display P3 for Apple-device testing

## Gain map modes

### mono

Mono gain map mode derives HDR enhancement primarily as a luminance-style ratio.

Use this when:

- you care mostly about brightness headroom
- your HDR version is mostly a brighter version of the SDR base
- you want a simpler baseline for testing

### rgb

RGB gain map mode derives HDR enhancement as a color ratio.

Use this when:

- the HDR image contains meaningful color differences, not just brightness differences
- you want to preserve colored highlights more faithfully
- you are testing how Apple-aware viewers respond to RGB gain mapping

One thing already observed in testing is that RGB mode can appear a little darker for strongly blue highlights. That may be expected because colored HDR is not the same thing as neutral luminance lift.

## Practical authoring guidance

### SDR base

Treat the SDR base as the exact image you want on SDR displays.

That means:

- do not treat SDR as a throwaway preview
- do not assume Instagram or another platform will preserve it perfectly
- but still author it carefully because Apple viewers may use it directly

### HDR alternate

Treat the HDR alternate as a controlled extension of the SDR image.

For iPhone-oriented authoring, a useful working guideline is:

- avoid authoring beyond `+3 stops` as your first target
- also test a more conservative version around `+2.3 stops`

Useful linear values relative to SDR white:

- SDR white = `1.0`
- `+1 stop` = `2.0`
- `+2 stops` = `4.0`
- `+2.3 stops` ≈ `4.93`
- `+3 stops` = `8.0`
- `+4 stops` = `16.0`

If you want to cap a highlight at `+3 stops`, do not let any RGB channel exceed `8.0` in the 32-bit HDR source.

Examples:

- neutral white at `+3 stops` = `R 8.0, G 8.0, B 8.0`
- neutral white at `+2.3 stops` ≈ `R 4.93, G 4.93, B 4.93`

## What has been observed so far

These are the practical findings from testing so far.

### Apple-side encoding

- Apple HEIF export works surprisingly well through Core Image
- generated HEIF files can display as HDR on iPhone
- macOS Preview / Photos may not always show the same HDR look as iPhone Photos

### Instagram behavior

- iPhone Instagram uploads can preserve HDR appearance better
- but Instagram app may appear to rebuild tone mapping and ignore or alter the authored SDR base
- Instagram app may even boost brightness beyond the authored HDR intent
- web upload may preserve SDR appearance better for JPEG
- but web upload may not honor HDR the same way
- HEIC may not be accepted in the web flow

This means there may not be one perfect deliverable for every sharing path.

## What Akari is trying to answer next

The next phase of the project is less about "can we encode HDR" and more about system behavior.

### Near-term goals

- confirm the best Apple-native export path for HEIF and JPEG
- improve compatibility with Apple Messages / iMessage sharing
- verify which formats survive Photos, Files, AirDrop, and Messages without losing Adaptive HDR behavior
- compare mono and RGB gain maps on Apple devices
- determine whether Instagram is reprocessing HDR uploads and rebuilding SDR outputs
- identify which authored headroom levels best match native iPhone photo behavior

### Specific research questions

- does iMessage preserve Akari-authored Adaptive HDR HEIF
- does iMessage preserve Akari-authored Adaptive HDR JPEG
- do Apple devices render mono and RGB gain maps differently across apps
- which path best matches a native iPhone camera HDR photo
- how much of the authored SDR base survives each platform and sharing path
- what is the best authoring ceiling for iPhone-targeted highlights

## Recommended next experiments

### 1. Headroom calibration set

Create three HDR alternates from the same master:

- conservative: max `4.93` (`+2.3 stops`)
- iPhone ceiling test: max `8.0` (`+3 stops`)
- aggressive control: current high-headroom version

Encode each in both:

- mono
- rgb

### 2. Sharing matrix

Test each file through:

- Photos on iPhone
- Files on iPhone
- Messages / iMessage
- AirDrop
- Instagram app on iPhone
- Instagram web upload
- macOS Photos
- macOS Preview

### 3. Compare against native iPhone captures

Use a real iPhone HDR photo as a reference and compare:

- highlight brightness
- SDR appearance
- colored highlight handling
- behavior when shared through the same path

## Future development ideas

Potential next upgrades for Akari:

- explicit metadata inspection mode
- reporting of input color spaces and dynamic range hints
- optional naming presets for test batches
- automated output matrix generation
- support for explicit gain map image input instead of only deriving from an HDR alternate
- support for sidecar test reports
- small helper scripts for Photoshop export naming conventions

## Project structure

```text
akari/
├── assets/
├── Sources/akari/
├── Tests/akariTests/
├── Package.swift
└── README.md
```

## Notes

Akari is both a utility and an experiment.

The encoding part is already working. The harder part now is understanding how Apple apps, iPhone, macOS, Messages, and Instagram each reinterpret or preserve the resulting file.

That means the project should keep focusing on:

- authoring discipline
- repeatable tests
- comparison against native iPhone output
- understanding where SDR is preserved and where HDR is remapped

