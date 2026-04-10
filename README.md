# AI Associate Input Method

macOS 菜单栏应用，在你跟 AI 聊天时预测你接下来要打的内容，按 Tab 接受。类似 IDE 里的 Copilot 补全体验，但用在日常打字场景。

## 工作原理

```
你在文本框打字 → App 通过 Accessibility API 读取文本 → 连同页面上下文发送给 LLM → 浮窗显示预测 → 按 Tab 接受
```

## 环境要求

- macOS 14+
- Swift 5.10+
- 火山引擎豆包 API（或其他 OpenAI 兼容 API）

## 快速开始

### 1. 克隆并编译

```bash
git clone https://github.com/comoysha/ai-associate-input-method.git
cd ai-associate-input-method
swift build
```

### 2. 配置 API Key

在项目根目录创建 `.env` 文件：

```bash
DOUBAO_API_KEY=你的API密钥
DOUBAO_ENDPOINT_ID=你的模型接入点ID
DOUBAO_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
```

> 豆包 API 申请：[火山引擎控制台](https://console.volcengine.com/ark)

### 3. 打包并启动

```bash
# 创建 .app 包
mkdir -p .build/AIAssociateInputMethod.app/Contents/MacOS
cp .build/debug/AIAssociateInputMethod .build/AIAssociateInputMethod.app/Contents/MacOS/
```

创建 `.build/AIAssociateInputMethod.app/Contents/Info.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AIAssociateInputMethod</string>
    <key>CFBundleIdentifier</key>
    <string>com.aiassociate.inputmethod</string>
    <key>CFBundleName</key>
    <string>AI Associate</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

```bash
# 签名
codesign -f -s - --deep .build/AIAssociateInputMethod.app

# 启动
open .build/AIAssociateInputMethod.app
```

### 4. 授权辅助功能

首次启动后需要授权：

1. 打开 **系统设置 → 隐私与安全性 → 辅助功能**
2. 找到 **AIAssociateInputMethod**，开启

> ⚠️ 每次重新编译并签名后，需要在辅助功能里**关掉再开启**权限。

### 5. 使用

1. 点击菜单栏的 💬 图标
2. 开启 **AI Completion** 开关
3. 在任意应用的文本框中打字
4. 停顿约 300ms 后，光标附近会出现灰色补全建议
5. 按 **Tab** 接受补全

## 快捷操作

| 操作 | 效果 |
|------|------|
| Tab | 接受补全 |
| 继续打字 | 补全消失，触发新预测 |
| Esc / 切换窗口 | 补全消失 |

## 设置项

点击菜单栏图标 → **Settings...**：

| 设置 | 默认值 | 说明 |
|------|--------|------|
| API Key | - | 豆包 API 密钥 |
| Endpoint ID | - | 模型接入点 ID |
| Base URL | `https://ark.cn-beijing.volces.com/api/v3` | API 地址 |
| Max Tokens | 64 | 补全最大长度 |
| Debounce | 300ms | 打字停顿多久后触发预测 |

## 项目结构

```
AIAssociateInputMethod/
├── App/            # 入口 + 状态管理
├── Accessibility/  # macOS 辅助功能 API 监听
├── Completion/     # LLM API 调用 + Prompt 构建
├── Overlay/        # 浮窗显示
├── Input/          # 键盘监听 + 文本注入
├── Models/         # 数据模型 + 设置
├── Utilities/      # SSE 解析 + 防抖 + 日志
└── Views/          # 菜单栏 UI
```

## 调试

App 运行时会写日志到 `~/ai_associate_debug.log`：

```bash
tail -f ~/ai_associate_debug.log
```

## 已知限制

- 每次重新编译签名后需要重新授权辅助功能权限
- 光标定位依赖 Accessibility API，部分应用可能不支持精确定位
- 使用中文输入法时，在候选词阶段无法触发预测，需等文字确认后
