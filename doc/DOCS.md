# Koi Network 文档索引

## 概览

`README` 是面向 `pub.dev` 用户的主入口文档，偏英文说明。
`doc/` 目录用于补充中文使用指南、示例和设计说明。

## 推荐阅读

1. **[../README.md](../README.md)**  
   适合第一次接触包的开发者，包含功能概览、安装方式和基础示例。

2. **[QUICK_START.md](QUICK_START.md)**  
   适合希望快速完成接入的项目，包含最小可运行接入步骤。

3. **[USAGE_EXAMPLE.md](USAGE_EXAMPLE.md)**  
   展示初始化、请求执行、mixin、强类型请求和多模块场景。

4. **[TOKEN_REFRESH_GUIDE.md](TOKEN_REFRESH_GUIDE.md)**  
   解释 JWT token 自动刷新、白名单配置和常见注意事项。

5. **[TECH_STACK.md](TECH_STACK.md)**  
   解释核心依赖、架构取舍和当前实现策略。

6. **[TESTING_GUIDE.md](TESTING_GUIDE.md)**  
   说明如何在本地运行测试、生成覆盖率以及编写新测试。

7. **[../CHANGELOG.md](../CHANGELOG.md)**  
   查看版本演进和发布记录。

## 按场景查找

### 我想快速接入
阅读 [QUICK_START.md](QUICK_START.md)。

### 我想先看完整能力边界
先看 [../README.md](../README.md)，再看 [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md)。

### 我想了解 token 自动刷新
阅读 [TOKEN_REFRESH_GUIDE.md](TOKEN_REFRESH_GUIDE.md)。

### 我想确认设计是否适合我的项目
阅读 [TECH_STACK.md](TECH_STACK.md)。

### 我想验证包质量或参与维护
阅读 [TESTING_GUIDE.md](TESTING_GUIDE.md)。

## 维护建议

- `README` 保持为对外主说明，优先保证英文可读性。
- `doc/` 里的示例应始终使用当前真实存在的公开 API。
- 若新增功能，请同步更新 `README`、对应专题文档和 `CHANGELOG`。

