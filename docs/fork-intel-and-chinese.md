# 本分支改动说明：Intel 支持 + 简体中文界面

本仓库是 [robbietilton/Compositor](https://github.com/robbietilton/Compositor) 的分支（fork）。
上游只面向 Apple silicon、只有英文界面。本分支在上游基础上做了两件事：

1. **支持 Intel 芯片** —— 让 app 能在 Intel Mac 上编译和运行（通用二进制）。
2. **简体中文界面** —— 界面跟随 macOS 系统语言，中文系统下自动显示简体中文。

本文写给需要**继续维护本分支**、或**把上游新版本合并进来**的人：说明改了什么、
为什么这么改、以后新增界面时该怎么处理。

> 术语说明：`rawValue` / `loc()` / `String Catalog` 等保留代码原文；界面文案与
> 翻译术语参考 Adobe Photoshop 简体中文版（色阶、曲线、仿制图章、正片叠底、羽化等）。

---

## 一、支持 Intel 芯片

改动非常小，因为 Compositor 没有任何架构相关的汇编或专属代码，Swift、C 像素代码、
Metal 着色器都是通用的。只要把编译目标架构从"仅 arm64"改成"arm64 + x86_64"即可。

### 1.1 改了什么

| 位置 | 改动 |
| --- | --- |
| `Compositor.xcodeproj/project.pbxproj` | `ARCHS = arm64;` → `ARCHS = "arm64 x86_64";`（Debug、Release 各一处，共 2 处） |
| `.github/workflows/build-intel.yml` | 新增的 CI 工作流，构建通用二进制并打包 `.dmg` |

### 1.2 本地构建（通用包）

```sh
xcodebuild build \
  -project Compositor.xcodeproj \
  -scheme Compositor \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO
```

- `ARCHS="arm64 x86_64"` 同时编译两种架构；`ONLY_ACTIVE_ARCH=NO` 保证 Release 出通用包。
- 校验是否真的包含 Intel 切片：
  ```sh
  lipo -archs "Compositor.app/Contents/MacOS/Compositor"   # 应同时列出 arm64 x86_64
  ```

### 1.3 CI 构建（GitHub Actions）

`.github/workflows/build-intel.yml` 的流程：选择 Xcode → 解析 Swift 包 → 通用 Release 构建
→ `lipo` 断言双架构都在 → **ad-hoc 签名**（`codesign --sign -`）→ 打 `.dmg` → 上传 artifact。
产物**没有 Apple 开发者签名/公证**，属于内部试用包。

### 1.4 运行未签名包的注意事项

从 Actions 下载的 `.dmg` 没有经过公证，首次打开会被 Gatekeeper 拦截。两种解法：

- 右键 app →「打开」→ 确认（一次即可）；或
- 命令行清除隔离属性：
  ```sh
  xattr -dr com.apple.quarantine /Applications/Compositor.app
  ```

---

## 二、简体中文界面

### 2.1 采用的机制

- 使用 macOS 现代的 **String Catalog**（`Localizable.xcstrings`），不是老的 `.lproj` 文件。
- 语言**跟随系统**：系统为简体中文时自动中文；也可在「系统设置 › 通用 › 语言与地区 ›
  应用程序」里单独把 Compositor 指定为简体中文。
- **关键约束：持久化标识符必须保持英文。** 图层混合模式、滤镜类型等以字符串形式写进
  `.comp` 工程文件（`rawValue`）。翻译只发生在**显示层**，绝不改动存盘内容——否则旧工程打不开。

### 2.2 改了哪些配置

| 位置 | 改动 | 作用 |
| --- | --- | --- |
| `project.pbxproj` → `knownRegions` | 加入 `"zh-Hans"` | 声明支持中文区域 |
| `project.pbxproj` → 各 build settings | `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`、`SWIFT_EMIT_LOC_STRINGS = YES` | 启用 String Catalog、自动抽取 SwiftUI 字面量 |
| `Config/Info.plist` | `CFBundleLocalizations = [en, zh-Hans]` | 让系统识别 app 支持中文 |
| `Compositor/Localization.swift` | 新增 | 提供 `loc()` 与 `displayName`（见下） |
| `Compositor/Localizable.xcstrings` | 新增（1117 条 key，1106 条有中文） | 英文 key → 各语言译文 |

`Localization.swift` 全文：

```swift
import Foundation

// 供"以 String 形式到达界面"的文字查表（自定义控件标题、AppKit 菜单等）；
// SwiftUI 字符串字面量会自动本地化，不需要它。
func loc(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

extension RawRepresentable where RawValue == String {
    // rawValue 是写进工程文件的英文标识，保持不变；
    // displayName 是界面上显示的文字，用 rawValue 去 catalog 查表。
    var displayName: String { loc(rawValue) }
}
```

### 2.3 代码里怎么调用（**新增界面时照此处理**）

这是维护时最容易踩坑的部分。规则如下：

**① SwiftUI 静态字面量：无需改代码，只需在 catalog 加译文。**
`Text("Export As")`、`Button("Fit")`、`.help("Format")`、`Label("Size", …)`、
`Picker("Format", …)`、`.accessibilityLabel("Navigator")` 这类**写死的双引号字符串**，
SwiftUI 会自动查表翻译。你只要在 `Localizable.xcstrings` 里补上这个 key 的中文即可。

**② 以下情况 SwiftUI 不会自动翻译，必须手动包 `loc()`：**
- **三元表达式**：`Text(cond ? "Hide Layer" : "Show Layer")` → `Text(loc(cond ? "…" : "…"))`
- **字符串插值**：`Text("Result: \(w) × \(h) pixels")` → `Text(String(format: loc("Result: %@ × %@ pixels"), …))`
- **变量/拼接传入**：`Text(someStringVar)`、`panel.title = "Export " + fmt` → 用 `loc(...)`

**③ 枚举显示一律用 `.displayName`，不要用 `.rawValue`。**
所有 `enum xxx: String` 的下拉项、标签，显示时用 `mode.displayName`（查表），
存盘/比较时用 `mode.rawValue`（英文）。这样中文环境下也能正确持久化。

**④ 自定义 helper 函数内部要 `loc()`。**
凡是"标题/提示作为参数传进来、内部再渲染"的辅助函数，其内部所有面向界面的出口都要查表：
`Text(loc(title))`、`.help(loc(help))`、`TextField(loc(title), …)`、`.accessibilityLabel(loc(title))`。
（本仓库的 `slider(...)`、`control(...)`、`field(...)`、`geometrySlider(...)` 等都已按此处理。）

**⑤ AppKit 直接绘制的文字是最大盲区，逐条 `loc()`。**
SwiftUI 不管这些，必须手动处理：
- 右键菜单 `NSMenuItem(title:)`、`NSMenu`、`addItem(withTitle:)`
- 窗口/面板标题 `panel.title`、`sheet.title`（NSSavePanel / NSOpenPanel / 导出对话框）
- `NSPopUpButton` 下拉项
- `setAccessibilityLabel(...)`、`toolTip = ...`

**⑥ AppKit 下拉框回读用 `representedObject`，不要依赖标题文字。**
中文环境下 `NSPopUpButton` 的 `item.title` 是中文，不能再拿它反查英文枚举。
正确做法：填项时把枚举塞进 `representedObject`，回读时取 `representedObject`
（见 `BlendModePicker.swift`）。同理，若代码里有 `menuItem.title == "Add Mask"` 这类
**用标题做逻辑判断**，本地化后比较会失效，需把比较右侧也写成 `loc("Add Mask")`。

**⑦ 插值格式说明符要按类型选对：**
`String` → `%@`，`Int` → `%lld`，`Double` → `%lf`；走 `String(format:)` 的 Swift 字符串
统一用 `%@`。**catalog 里的 key 必须与代码里的字符串逐字符一致**（含 `⌘`、`−`(U+2212)、
`…`(U+2026)、`·`(U+00B7) 等符号），否则查不到、退回英文。

### 2.4 动态文本（撤销/重做、错误提示）

- 撤销/重做菜单显示的是**历史操作名**，来自代码各处 `beginEdit("Brush Stroke")` 这类调用。
  显示处写成 `String(format: loc("Undo %@"), loc(session.history.undoName))`，
  并保证每个操作名（"Brush Stroke"、"Transform Layer"…）在 catalog 里有 key。
- `NSAlert` 的 `messageText` / `informativeText` / `addButton(withTitle:)` 都是英文字面量时，
  需在构造处包 `loc()`（见 `ProjectController.swift` 的保存对话框）。

### 2.5 手动加一条翻译的格式

`Localizable.xcstrings` 是 JSON。新增一条：

```json
"Delete Layer": {
  "localizations": {
    "zh-Hans": { "stringUnit": { "state": "translated", "value": "删除图层" } }
  }
}
```

- key 用英文原文；`value` 用中文；`state` 用 `"translated"`。
- 含插值时 key 写成 `"Zoom out (⌘−), now %@"` 这种带说明符的形式。
- 文件很大（数百条），建议用脚本按上面的结构批量写入，写完用
  `python3 -c "import json; json.load(open('Compositor/Localizable.xcstrings'))"` 校验合法性。

### 2.6 不翻译的内容

品牌名 **Compositor**、快捷键字母（⌘T、⌘J）、文件格式与编码名（PNG、JPEG、PDF、sRGB、
Camera Raw、LUT）、以及由 Apple 系统自行翻译的标准菜单（View / Edit / Window / Help 等）。

---

### 2.7 已合并到上游 v1.5.12

上游从 1.4.8 到 1.5.12 加了很多新界面，本分支合并时已一并本地化（catalog 由 840 条增至 1117 条）。
新增面与处理方式：

| 功能 | 涉及界面 | 处理 |
| --- | --- | --- |
| HDR / 16 位图层 | 导出为的「位深」、图层右键「转换为 16 位 / 8 位」、图层行的 HDR 与 16 位标签与小提示 | `loc()` + 新 key |
| CMYK 印刷 | 视图菜单的校样颜色、色域警告、配置文件、载入配置文件；导出为的 CMYK 与配置文件说明 | `loc()` + 新 key |
| GIF 图层与时间轴 | 帧条、播放/暂停、延时菜单、删除与复制帧 | `loc()` + 新 key |
| Lens Effects（光晕、星芒、雾气、棱镜、散景） | 滤镜面板整组滑块与提示 | 提示文案全部入 catalog |
| 对齐与分布 | 图层菜单、移动工具条 | 枚举一律 `.displayName` |
| 图层搜索与类型筛选 | 图层面板标题行、空状态 | 空状态标题与说明 |
| 通道打包导出 | 导出为的通道选择、帮助文本 | `String(format:)` + `%@` |

这次合并踩到的三类坑，以后同样会遇到：

1. **枚举新成员**（`LensEffect`、`BokehShape`、`DitherColors`、`CameraRawGroup`、`LayerAlignment`、
   `LayerDistribution`、`ChannelPack.Channel`）上游代码直接用 `.rawValue` 显示，必须逐处改 `.displayName`。
2. **`.help()` 里嵌套带引号的三元插值**（导出为的「其他格式」提示）没法按字面量翻译，
   已拆成两个 `loc(...)` 分支。
3. **AppKit 单元格文案**（`NativeLayerList` 的 toolTip 与无障碍标签、`CanvasRulers`、`CameraRawSlider`、
   `KeyboardShortcuts`）SwiftUI 不管，需逐条 `loc()`；带插值的写成 `String(format: loc("…%@…"), …)`。

---

## 三、如何把上游新版本合并进来

本分支会持续落后于上游。合并时的原则：**采纳上游的结构与行为变更，保留我们的 `loc()` 本地化。**

```sh
git remote add upstream https://github.com/robbietilton/Compositor.git   # 只需一次
git fetch upstream
git log --oneline main..upstream/main          # 看上游多了哪些提交/功能
git merge --no-commit --no-ff upstream/main    # 预演，不自动提交
git diff --name-only --diff-filter=U           # 列出真正冲突的文件
```

解决冲突：

1. 上游重构掉的方法（例如把多个导出合并成一个 `savePanel(for:)`），**采纳上游**、删掉本地旧版。
2. 上游改了行为（例如某按钮样式），**以游为准**，只把英文字面量重新包上 `loc()`。
3. 双方都改的对话框/菜单，合并成"上游新语义 + 我们的 `loc()`"。

合并后**别忘了本地化上游新增的界面**：扫新文件里的 `Text(`/`Button(`/`.help(`/`NSMenuItem(title:`，
按第二章的规则补 `loc()` 和 catalog 译文。

最后全局自检：

```sh
grep -rnE '^(<<<<<<<|>>>>>>>|=======$)' Compositor --include='*.swift'   # 无冲突残留
```

---

## 四、构建与验证

### 4.1 用 Xcode 图形界面（没写过代码也能做）

1. 打开 `/Applications/Xcode.app`。首次启动要点同意协议、安装附加组件。
2. 菜单 **File › Open…**（或直接双击）选仓库根目录的 `Compositor.xcodeproj`。
3. 确认窗口左上角两处：scheme 是 **Compositor**，运行目标是 **My Mac**。
4. **先把构建配置切成 Release**：菜单 **Product › Scheme › Edit Scheme… › Run ›
   Build Configuration** 选 `Release`。原因见下面的签名坑。
5. 菜单 **Product › Build**（⌘B）编译；**Product › Run**（⌘R）编译并启动。

产物在左侧导航栏最下方的 **Products › Compositor.app**，右键 **Show in Finder** 即可拖到
`/Applications`。

> **签名坑（必读）**：`project.pbxproj` 里 Debug 配置是 `CODE_SIGN_STYLE = Automatic` 且
> `DEVELOPMENT_TEAM = 3E4X3B9Z9T`（上游作者的团队 ID）。你的账号里没有这个团队，Debug 构建会报
> *Signing for "Compositor" requires a development team*。Release 配置是
> `CODE_SIGN_IDENTITY = "-"`（ad-hoc，本地能直接运行），所以选 Release 最省事。
> 若一定要用 Debug：选中 target › **Signing & Capabilities** › 取消
> **Automatically manage signing**，把 Signing Certificate 设为 **Sign to Run Locally**。

### 4.2 用终端（1.2 的命令 + 跳过签名，可脚本化）

```sh
xcodebuild build \
  -project Compositor.xcodeproj \
  -scheme Compositor \
  -configuration Release \
  -destination 'platform=macOS' \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

- `CODE_SIGNING_ALLOWED=NO` 跳过签名，免得本地没证书就报错；要运行的话补一次 ad-hoc 签名：
  `codesign --force --deep --sign - Compositor.app`
- 加 `-derivedDataPath ./.build-dd` 把中间产物留在仓库内，好清理。
- 只看关键行：`… 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"`

### 4.3 CI（连 Xcode 都不需要装）

两个工作流，触发条件不同：

| 工作流 | 触发条件 | 干什么 | 实测耗时 |
| --- | --- | --- | --- |
| `verify.yml` | 任意 push / PR | 编译 + 跑单测和 UI 测试 | 约 5 分钟 |
| `build-intel.yml` | **只** `intel-build` 分支的 push，或手动 dispatch | 通用 Release 构建 → `lipo` 断言双架构 → ad-hoc 签名 → 打 `.dmg` | 约 9 分钟 |

推送方式决定拿到什么：

```sh
git push origin main                          # 只跑测试，确认能编译、测试通过
git push origin main:refs/heads/intel-build   # 额外产出通用 DMG
```

产物在 **Actions › 对应那次 run › 页面底部 Artifacts › Compositor-universal-dmg**，
保留 30 天，下载需登录 GitHub。`.dmg` 未公证，首次打开按 1.4 处理。

### 4.4 不开 Xcode 的快速自检

```sh
swiftc -parse $(find Compositor -name '*.swift')      # 语法层，秒级
python3 -c "import json; json.load(open('Compositor/Localizable.xcstrings'))"   # catalog 合法性
```

只查语法，**类型检查与链接必须靠 Xcode 或 CI**。

---

## 五、给后来者的检查清单

新增一个界面 / 功能，或合并上游后，逐条对照：

- [ ] SwiftUI 静态文案：在 `Localizable.xcstrings` 补了中文 key 了吗？
- [ ] 三元 / 插值 / 变量传入的文字：包 `loc()` 或 `String(format: loc(...), …)` 了吗？
- [ ] 枚举显示：用的是 `.displayName` 而不是 `.rawValue` 吗？
- [ ] AppKit 菜单 / 面板标题 / 下拉 / 无障碍标签：逐条 `loc()` 了吗？
- [ ] AppKit 下拉回读 / 标题逻辑判断：改用 `representedObject` 或 `loc()` 比较了吗？
- [ ] 撤销/重做、错误弹窗等动态文本：源头包了 `loc()`、catalog 有对应 key 吗？
- [ ] 格式说明符（`%@`/`%lld`/`%lf`）与被插值变量类型匹配吗？key 里的特殊符号逐字符一致吗？
- [ ] 存盘字段（`rawValue`、工程格式）没被误翻译成中文吧？
- [ ] Intel：`ARCHS` 仍是 `"arm64 x86_64"`，构建产物 `lipo -archs` 含 x86_64 吧？
- [ ] 合并上游：冲突处保留了 `loc()`、新功能补了翻译、无冲突残留标记吧？
