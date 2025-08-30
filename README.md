# dia - 跨平台后端框架 🚀

[![CI](https://github.com/KayanoLiam/dia/workflows/CI/badge.svg)](https://github.com/KayanoLiam/dia/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.1-green.svg)](https://github.com/KayanoLiam/dia/releases)
[![Zig](https://img.shields.io/badge/zig-0.14.1+-orange.svg)](https://ziglang.org/)
[![Rust](https://img.shields.io/badge/rust-1.70+-red.svg)](https://www.rust-lang.org/)

**dia** 是一个为 Zig 开发者提供的跨平台后端框架，基于 Rust 的 actix-web 构建，提供类似 Java Spring Boot 的直观 API。解决了 zap 框架在 Windows 平台不可用的问题。

> 🎯 **设计目标**：让 Zig 开发者能够像使用 `std` 库一样轻松地构建跨平台 Web 应用

## ✨ 特性

- 🌍 **跨平台支持** - 在 Windows、macOS、Linux 上都能完美运行
- ⚡ **高性能** - 基于 Rust actix-web，性能卓越
- 🎯 **简单易用** - 为 Zig 开发者设计的直观 API
- 📦 **模块化设计** - Application、Request、Response、Controller、Middleware
- 🔧 **零配置** - 开箱即用的后端框架
- 📚 **std 风格 API** - 像使用 Zig 标准库一样的导入方式
- 🚀 **Zig 0.14.1 支持** - 完全兼容最新 Zig 版本，享受最新特性

## 📚 文档

- 🚀 **[快速开始](GUIDE.md)** - 完整的用户指南和教程
- 📝 **[API 参考](API.md)** - 详细的 API 文档和函数说明
- 📋 **[使用示例](examples/)** - 丰富的示例代码和最佳实践

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/KayanoLiam/dia.git
cd dia
```

### 2. 构建项目

```bash
# 构建 Rust 核心库
cargo build --release

# 构建 Zig 示例
zig build
```

### 3. 运行示例

```bash
# Hello World 示例
zig build run-hello

# REST API 示例
zig build run-rest
```

## 📖 基本用法

### Hello World

```zig
const std = @import("std");
const dia = @import("dia");

// 方式 1: 完整导入
fn hello_handler() callconv(.C) ?*anyopaque {
    var response = dia.Response.new();
    _ = response.text("Hello, Zig + dia! 🎉") catch return null;
    return null;
}

pub fn main() !void {
    try dia.init();
    
    var app = dia.Application.new();
    defer app.deinit();
    
    _ = try app.host("127.0.0.1");
    _ = try app.port(3000);
    _ = try app.get("/", hello_handler);
    
    try app.run();
}
```

### 模块化导入 (std 风格)

```zig
const dia = @import("dia");

// 像 std 库一样的模块化导入
const request = dia.request;
const response = dia.response;
const controller = dia.controller;
const middleware = dia.middleware;

// 或者直接导入类型
const Application = dia.Application;
const Response = dia.Response;
```

### REST API

```zig
const std = @import("std");
const dia = @import("dia");

fn get_users_handler() callconv(.C) ?*anyopaque {
    const users_json = 
        \\{
        \\  "users": [
        \\    {"id": 1, "name": "Alice", "email": "alice@example.com"},
        \\    {"id": 2, "name": "Bob", "email": "bob@example.com"}
        \\  ]
        \\}
    ;
    
    var response = dia.Response.new();
    _ = response.json(users_json) catch return null;
    return null;
}

pub fn main() !void {
    try dia.init();
    
    var app = dia.Application.new();
    defer app.deinit();
    
    _ = try app.host("127.0.0.1");
    _ = try app.port(3001);
    _ = try app.get("/users", get_users_handler);
    
    try app.run();
}
```

## 🏗️ 项目结构

```
dia/
├── dia-core/           # Rust 核心库
│   ├── src/
│   │   ├── lib.rs      # 库入口
│   │   ├── application.rs
│   │   ├── request.rs
│   │   ├── response.rs
│   │   ├── controller.rs
│   │   ├── middleware.rs
│   │   └── ffi.rs      # FFI 接口
│   └── Cargo.toml
├── dia-macros/         # Rust 宏库
├── src/
│   └── dia.zig        # Zig 封装层
├── examples/          # 示例代码
│   ├── hello_world.zig
│   ├── rest_api.zig
│   └── simple_server.rs
├── build.zig          # Zig 构建配置
└── README.md
```

## 🛠️ API 参考

### Application

```zig
var app = dia.Application.new();
defer app.deinit();

// 配置主机和端口
_ = try app.host("127.0.0.1");
_ = try app.port(3000);

// 添加路由
_ = try app.get("/", handler_function);
_ = try app.post("/api/data", post_handler);

// 启动服务器
try app.run();
```

### Response

```zig
var response = dia.Response.new();

// 返回文本
_ = response.text("Hello World") catch return null;

// 返回 JSON
_ = response.json("{\"message\": \"success\"}") catch return null;
```

## 🧪 测试

```bash
# 运行 Rust 测试
cargo test

# 运行完整测试套件
zig build test
```

## 📦 在你的项目中使用 dia

### 方法 1: 直接克隆 (推荐)

```bash
git clone https://github.com/KayanoLiam/dia.git
cd dia
cargo build --release
zig build run-hello  # 运行 Hello World 示例
```

### 方法 2: 子模块方式

```bash
# 在你的项目中添加 dia 作为子模块
git submodule add https://github.com/KayanoLiam/dia.git vendor/dia
```

在你的 `build.zig` 中：

```zig
const dia_dep = b.dependency("dia", .{
    .target = target,
    .optimize = optimize,
});

exe.addModule("dia", dia_dep.module("dia"));
```

### 方法 3: Zig 包管理器 (实验性)

```bash
zig fetch --save git+https://github.com/KayanoLiam/dia.git
```

### 方法 4: 直接下载 Release

从 [GitHub Releases](https://github.com/KayanoLiam/dia/releases) 下载最新版本，解压到你的项目目录。

## 🤝 贡献

欢迎贡献代码！请查看我们的贡献指南：

1. Fork 这个仓库
2. 创建你的特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交你的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启一个 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [actix-web](https://actix.rs/) - 强大的 Rust Web 框架
- [Zig](https://ziglang.org/) - 系统编程语言
- 所有贡献者和用户的支持

## 📞 联系我们

如果你有任何问题或建议，请：

- 创建 [Issue](https://github.com/KayanoLiam/dia/issues)
- 发起 [Discussion](https://github.com/KayanoLiam/dia/discussions)

## 🔄 版本更新说明

### v0.1.1 (2024-08-30) - Zig 0.14.1 支持

🎆 **重大更新**：完全支持 Zig 0.14.1！

✨ **新增特性**：
- ✅ 完全兼容 Zig 0.14.1 最新版本
- ✅ 向后兼容，无破坏性变更
- ✅ 性能优化和类型安全改进

🔧 **技术改进**：
- FFI 类型声明现代化 (`?*opaque` → `?*anyopaque`)
- 构建系统兼容性提升
- 语法结构标准化
- 编译错误全面修复

🔙 **升级指南**：
如果你正在使用旧版本，只需更新到最新代码即可。你的现有代码无需修改！

```bash
git pull origin main
cargo build --release
zig build
```

### v0.1.0 (2024-08-30) - 初始发布

✨ **核心特性**：
- 🎉 首个稳定版本发布
- 🌍 跨平台支持 (Windows/macOS/Linux)
- 📚 std 风格的 API 设计
- 🚀 基于 Rust actix-web 的高性能核心

---

Made with ❤️ for the Zig community