# dia

一个为 Zig 提供跨平台后端支持的框架，基于 Rust 和 actix-web 构建。

## 项目概述

dia 是一个后端框架，通过 Rust 封装 actix-web，为 Zig 开发者提供类似 Java Spring Boot 的直观 API，同时解决 zap 框架在 Windows 平台不可用的问题。

## 核心特性

- ✅ **跨平台支持**: 基于 actix-web，支持 Windows、Linux、macOS
- ✅ **类型安全**: Rust 底层保证内存安全和并发安全
- ✅ **简洁 API**: 为 Zig 提供直观易用的接口
- ✅ **高性能**: 基于 actix-web 的异步架构
- ✅ **模块化设计**: Application、Request、Response、Controller、Middleware

## 项目结构

```
dia_qoder/
├── Cargo.toml          # 工作区配置
├── dia-core/           # 核心库 (Rust)
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs      # 主入口
│       ├── application.rs  # 应用程序核心
│       ├── request.rs  # HTTP 请求封装
│       ├── response.rs # HTTP 响应封装
│       ├── controller.rs # 路由控制器
│       ├── middleware.rs # 中间件支持
│       └── ffi.rs      # FFI 接口
├── dia-macros/         # 宏库 (Rust)
│   ├── Cargo.toml
│   └── src/
│       └── lib.rs      # 过程宏定义
└── README.md           # 项目文档
```

## 已完成功能

### ✅ Rust 核心功能
- [x] 项目初始化和工作区配置
- [x] Application 模块 - 应用启动和HTTP服务
- [x] Request 模块 - HTTP请求上下文封装
- [x] Response 模块 - 支持 text()、json() 等方法
- [x] Controller 模块 - 路由定义，支持 GET/POST
- [x] Middleware 模块 - 请求前后处理支持
- [x] 宏支持 - #[get("/path")]、#[post("/path")] 等注解
- [x] FFI 导出接口 - 使用 #[unsafe(no_mangle)] 的现代语法

### ✅ Zig 侧集成
- [x] dia.zig 封装层 - 提供 Zig 友好的 API
- [x] Application、Request、Response 类型接口
- [x] Hello World 示例
- [x] REST API 示例
- [x] @import("dia") 导入支持
- [x] 构建系统配置

### ✅ 测试和文档
- [x] Rust 侧单元测试
- [x] Zig 示例测试
- [x] API 文档和 README
- [x] GitHub CI/CD 配置

## 构建项目

```bash
# 检查项目编译
cargo check

# 构建项目
cargo build

# 运行测试
cargo test
```

## 目标 API 示例

### Rust 侧使用 (当前可用)

```rust
use dia_core::{Application, Response};
use dia_macros::*;

#[get("/")]
async fn hello() -> Response {
    Response::ok_text("Hello, World!")
}

#[get("/users")]
async fn get_users() -> Response {
    Response::ok_json(serde_json::json!({
        "users": [
            {"id": 1, "name": "Alice"},
            {"id": 2, "name": "Bob"}
        ]
    }))
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let app = Application::new()
        .host("0.0.0.0")
        .port(3000);
    
    app.run().await?;
    Ok(())
}
```

### Zig 侧使用 (计划中)

```zig
const dia = @import("dia");

pub fn main() void {
    var app = dia.Application.init();
    app.get("/", fn (req, res) {
        res.send("Hello, Zig + dia!");
    });
    app.run();
}
```

## 技术架构

```
┌─────────────────┐
│   Zig 应用层    │
├─────────────────┤
│   dia.zig 封装  │
├─────────────────┤
│   FFI 接口层    │
├─────────────────┤
│   dia-core      │
│   (Rust 核心)   │
├─────────────────┤
│   actix-web     │
└─────────────────┘
```

## 开发状态

### M1 - Rust MVP ✅
- ✅ 建立基础项目结构
- ✅ 提供 Application 启动 HTTP 服务
- ✅ 提供 Controller 定义路由
- ✅ 提供 Request & Response 对象
- ✅ 提供基础 Middleware 支持

### M2 - Zig 接入 ✅
- ✅ 提供 Zig 包装接口
- ✅ 确保 Zig 用户能导入 dia
- ✅ 编写 Zig 示例项目

### M3 - 功能完善 ✅
- ✅ 增加内置中间件
- ✅ 提供单元测试与文档
- ✅ GitHub CI/CD 配置

## 贡献

欢迎提交 Issues 和 Pull Requests！

## 许可证

MIT OR Apache-2.0