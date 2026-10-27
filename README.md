# Compositor

> **关于本分支 / About this fork**  
> 本仓库是从 [robbietilton/Compositor](https://github.com/robbietilton/Compositor) 派生的分支，相对上游做了两处主要改动：  
> 1. **支持 Intel 芯片** — 上游仅面向 Apple silicon，本分支已调整构建配置，可在 Intel Mac 上编译与运行。  
> 2. **简体中文界面** — 新增 `zh-Hans` String Catalog，跟随 macOS 系统语言自动切换。在系统偏好设置 > 通用 > 语言与地区 > 应用程序中，也可单独把 Compositor 指定为中文。  
> 详细要求见下方 Requirements 章节。  
> 完整改动清单与维护指南（新增界面如何做本地化、如何合并上游、如何构建 Intel 包）见 [docs/fork-intel-and-chinese.md](docs/fork-intel-and-chinese.md)。  
>  
> This fork of [robbietilton/Compositor](https://github.com/robbietilton/Compositor) adds **Intel Mac support** (upstream is Apple-silicon only) and a **Simplified Chinese (zh-Hans) interface** that follows the system language. See *Requirements* below, and [docs/fork-intel-and-chinese.md](docs/fork-intel-and-chinese.md) for the full maintenance guide.

Adobe Photoshop costs too much and tools like GIMP don’t feel familiar enough for me to stay in flow. That’s why I built Compositor.

The goal was to create a full-featured image editor that is completely free and open source. I used to use Photoshop for compositing and post-processing, so Compositor is built around that workflow - with the tools needed to create a pixel-perfect final image.

Because it’s open source, you can download the Xcode project and add, remove, or modify any feature to fit your workflow.

## Installation

### Download
Get Compositor from [robbietilton.com/compositor](https://robbietilton.com/compositor), or download the latest release directly from [GitHub Releases](https://github.com/robbietilton/Compositor/releases/latest).

### Homebrew

```sh
brew install --cask robbietilton-compositor
```

## Features

### Layers
- Layers and folders, with opacity and Photoshop's full set of blend modes in its order — a folder's opacity dims everything inside it
- Layer masks: paint, fill, invert, blur and feather them anywhere on the canvas, past the layer's own pixels; link or unlink them to transform a mask on its own
- Clipping masks and folder masks
- Adjustment layers: Hue/Saturation, Levels, Curves, Exposure, Gradient Map, Grain, Black & White, Color Balance, Invert, Gaussian Blur, Motion Blur and Noise
- Layer effects: Stroke, Drop Shadow, Color Overlay, Inner Shadow, Outer Glow and Inner Glow, rendered on the GPU and editable at any time
- Merge Down, Merge Layers and Merge Group (⌘E)
- Duplicate, rename inline, reorder and nest by drag and drop; Option-drag to duplicate; a right-click menu in the Layers panel
- Copy and paste whole layers and folders (⌘C/⌘V with no selection), within a project or between projects, or drag them between projects

### Transform
- Non-destructive move, scale, rotate and flip — images keep their full resolution however small you make them
- Free distort (⌘-drag a handle), with Shift to lock to an axis
- Transform several layers, or a whole folder, together
- Snapping to canvas and layer edges and centers, with guides
- Exact values for position, size, scale and angle, stepped with the arrow keys
- Flip Layer and Flip Canvas, horizontal and vertical

### Selections
- Rectangle and Ellipse Marquee, Freehand and Polygonal Lasso, and the Magic tool — Wand selects by color, Object traces whatever you click (Tab switches)
- Select Subject, and Expand, Contract and Feather on any selection
- Add to and subtract from selections, move the outline, or move and duplicate the pixels inside
- Load a layer's pixels or a mask as a selection
- Content-Aware Fill, which can also extend an image past its edges

### Painting and retouching
- Brush with size, hardness, opacity and smoothing, in Paint or Erase mode (B and E), and Shift for straight lines
- Spot Healing Brush (content-aware)
- Clone Stamp, aligned or not, sampling one layer or all of them
- Blur tool, on pixels or masks
- Gradient tool and Shape tool (rectangles, rounded rectangles, ellipses and lines), which stay editable rather than being rasterized
- Type tool (T): inline multiline editing in draggable, resizable paragraph boxes; font, size, color, alignment and spacing in the tool header; transform text and use it as a clipping mask
- Eyedropper and a full color picker

### Adjustments and filters
- Camera Raw filter: light, color, curves, color mixer, color grading, detail, optics and geometry, in a panel beside the canvas
- Levels (with Auto), Curves, Hue/Saturation, Exposure, Gradient Map, Grain, Black & White, Color Balance and Invert
- Gaussian Blur and Motion Blur that spread past a layer's edges
- Add Noise, Vignette, Bloom / Glow, Dither, Scanlines, Tonal Contrast, Lens Correction and Remove Background
- Live previews, limited to the selection when there is one
- Last Filter (⌃⌘F) runs the last filter again with the same settings

### Canvas and files
- Multiple projects in tabs
- Search Commands (⌘F): find every menu command and tool by name, as in Raycast or Obsidian, and run it with Return
- Toggle Fullscreen (F): the canvas alone on black over the whole screen, with every panel put away; F or Esc brings them back
- Rulers (⌘R), guides dragged from them, a layout grid with adjustable spacing and subdivisions, and Snap To for guides, grid, layers and document bounds
- Crop with snapping, ratios including 3:4 and 9:16, and Option for symmetric cropping; with a selection, the crop starts at it
- Canvas Size, Image Size and Trim
- A Navigator minimap in the canvas's corner from 300% zoom: the whole document in small with a box around the view; click or drag to move there (View › Navigator)
- Sharp high-quality downsampling when zoomed out, and a pixel grid when zoomed in
- Import JPEG, PNG, HEIC, TIFF, SVG, camera RAW (with a develop step first) and Photoshop PSD and PSB (8-bit RGB; not CMYK). Photoshop folders, masks, blend modes, fill rectangles/ellipses, and simple horizontal text stay editable; other vectors and vertical text become pixels. A conversion report is shown before anything is applied.
- Large documents: the memory budget scales with your Mac, and a Photoshop file too big to open has its layers cropped to the canvas instead
- Export PNG (⇧⌘E), Export JPEG (⇧⌥⌘S), and Export As (⇧⌥⌘W) for PNG, JPEG or a one-page PDF at the print size, scaled if you like, with a live preview, JPEG quality and file size; Copy Merged
- Keep working while a project saves
- Photoshop-style keyboard shortcuts throughout, remappable in Edit > Keyboard Shortcuts
- Drag a number's label to scrub its value, as in Photoshop
- Automatic updates, signed and notarized

### Works with AI agents
- AI agents and scripts can build and edit projects directly: a `.comp` is a folder of PNG layers and a manifest, and an open project updates live as it's written. See [Writing Compositor projects](docs/writing-comp-files.md)

## Requirements

- macOS 26.0 或更高，**Apple silicon 或 Intel** Mac / macOS 26.0 or later on an Apple silicon **or Intel** Mac
- Xcode 26 或更高（从源码构建时）/ Xcode 26 or later (to build from source)

### 中文界面 / Simplified Chinese UI

界面语言跟随 macOS 系统语言。若要在英文系统中单独把 Compositor 设为中文，请在“系统设置 › 通用 › 语言与地区 › 应用程序”里为 Compositor 选择“简体中文”，然后重启应用。翻译覆盖菜单、面板、工具栏、悬停提示、滤镜/调整图层/混合模式/形状/对齐等动态枚举标签，以及 AppKit 直接绘制的下拉与工具提示。品牌名 Compositor、专有名词与快捷键字母保留原文。术语参考了 Adobe Photoshop 简体中文界面（色阶、曲线、仿制图章、羽化、正片叠底 等）。

The interface follows the macOS system language. To pin Compositor to Chinese on an English system, open System Settings › General › Language & Region › Applications and add Compositor with 简体中文, then relaunch. Translation covers menus, panels, toolbars, hover help, dynamic enum labels (filters, adjustments, blend modes, shapes, alignment) and AppKit-drawn pop-ups and tooltips. The brand name, shortcuts and file extensions stay in their original form; terminology matches the Chinese Photoshop UI.

## Translations

Compositor is English only for now, and translation pull requests aren't being accepted. It's maintained by one person, every new string would need translating from then on, and translations in languages I don't read can't be reviewed. I'll revisit this once the app settles; until then, please don't open localization PRs.

## Building

Open `Compositor.xcodeproj` and run the **Compositor** scheme.

## Releasing

`scripts/release.sh` builds a Release version, signs it with Developer ID, notarizes and staples it, and packages it into `dist/Compositor-<version>.dmg`.

It needs, all kept outside this repository:

- a **Developer ID Application** certificate in the login keychain
- notarization credentials saved with `xcrun notarytool store-credentials "compositor-notary" …`
- [`create-dmg`](https://github.com/create-dmg/create-dmg) (`brew install create-dmg`)

## License

MIT — see [LICENSE](LICENSE).
