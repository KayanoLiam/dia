产品计划书 - dia

1. 产品概述
	•	产品名称: dia
	•	类型: 后端框架（Rust 封装，为 Zig 提供跨平台后端支持）
	•	愿景: 为 Zig 开发者提供类似 Java Spring Boot 的直观 API，同时解决 zap 在 Windows 平台不可用的问题。

⸻

2. 产品目标
	1.	短期（MVP）
	•	提供一个基于 actix-web 的封装，支持 Application、Request、Response、Controller、Middleware。
	•	提供 Zig 用户类似 @import("std") 的方式导入 dia。
	2.	中期
	•	优化 API 设计，保证 Zig 端开发体验流畅。
	•	提供更多内置中间件（如日志、跨域、错误处理）。
	3.	长期
	•	成为 Zig 生态里主流的跨平台后端框架。

⸻

3. 技术背景
	•	现状: zap 框架性能优秀，但不支持 Windows。
	•	解决思路: 通过 Rust 封装 actix-web，向 Zig 暴露跨平台 API。
	•	设计原则:
	1.	清晰 API → 类似 Java 的类和注解风格。
	2.	模块化 → Application, Request, Response, Controller, Middleware。
	3.	可扩展 → 能平滑支持未来功能增强。

⸻

4. 项目里程碑
	•	M1 - Rust MVP
	•	建立基础项目结构（Rust + actix-web 封装）。
	•	提供 Application 启动 HTTP 服务。
	•	提供 Controller 定义路由。
	•	提供 Request & Response 对象。
	•	提供基础 Middleware 支持。
	•	M2 - Zig 接入
	•	提供 Zig 包装接口（通过 FFI 或 @cImport）。
	•	确保 Zig 用户能像导入 std 一样导入 dia。
	•	编写 Zig 示例项目（简单的 REST API）。
	•	M3 - 功能完善
	•	增加内置中间件（日志、CORS、错误处理）。
	•	提供单元测试与文档。
	•	发布第一个版本（v0.1.0）。

⸻

5. 详细任务清单

5.1 Rust 侧开发
	•	项目初始化
	•	创建 dia-core crate（核心逻辑）。
	•	创建 dia-macros crate（提供宏语法糖）。
	•	配置工作区 Cargo.toml。
	•	核心模块
	•	Application：提供 new(), run() 方法。
	•	Request：封装 HTTP 请求上下文。
	•	Response：封装响应对象，支持 text(), json()。
	•	Controller：提供路由定义，支持 GET/POST。
	•	Middleware：支持请求前/后处理。
	•	宏支持
	•	提供 #[get("/path")], #[post("/path")] 等注解宏。
	•	自动注册控制器。
	•	FFI 导出
	•	通过 #[no_mangle] 暴露必要函数。
	•	定义 C ABI 兼容接口。

⸻

5.2 Zig 侧开发
	•	封装层
	•	编写 dia.zig，封装 Rust 导出的函数。
	•	提供 Application, Request, Response 类型接口。
	•	示例
	•	Hello World（返回字符串）。
	•	REST API（GET /users 返回 JSON）。
	•	打包
	•	确保 Zig 用户可以通过 @import("dia") 导入。

⸻

5.3 测试与文档
	•	提供单元测试（Rust 侧）。
	•	提供 Zig 示例测试。
	•	编写 API 文档（Rustdoc + README 示例）。
	•	在 GitHub 配置 CI/CD（构建 + 测试）。

⸻

6. 成功标准
	•	MVP 成功标准:
	•	能运行一个 Zig 项目：

const dia = @import("dia");

pub fn main() void {
    var app = dia.Application.init();
    app.get("/", fn (req, res) {
        res.send("Hello, Zig + dia!");
    });
    app.run();
}


	•	性能标准:
	•	与 zap 在 Linux/macOS 上性能差距 ≤ 20%。
	•	Windows 平台可正常运行。

⸻

7. 风险与对策
	•	风险: actix-web 升级/变动 → API 兼容性问题。
	•	对策: 在 API 层封装隔离底层实现。
	•	风险: Zig FFI 复杂度高。
	•	对策: 提供封装好的 Zig API，避免 Zig 用户直接操作 C ABI。