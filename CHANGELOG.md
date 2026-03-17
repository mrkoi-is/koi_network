# Changelog

## [0.2.0] - 2026-03-12

### Added
- **Typed Request Executor** — New `KoiTypedRequestExecutor` for pre-parsed strong-type responses
- **`KoiTypedResponse<T>`** interface for bridging Retrofit/OpenAPI generated models
- Typed methods in `KoiNetworkRequestMixin`: `typedRequest`, `typedSilentRequest`, `typedQuickRequest`
- Typed methods in `NetworkRequestUtils`: `typedRequest`, `typedSilentRequest`
- Full method parity: `execute`, `executeSilent`, `executeQuick`, `executeBatch`, `executeWithRetry`
- Comprehensive test suite for typed executor

### Migration Guide
Projects using Retrofit-generated `BaseResult<T>` can integrate by:
1. Implementing `KoiTypedResponse<T>` on the existing `BaseResult<T>` class
2. Replacing `KoiRequestExecutor.execute(request: ...)` with `KoiTypedRequestExecutor.execute(request: ...)`

## [0.1.0] - 2026-03-01

### Added
- Initial release of `koi_network`
- Adapter-based architecture for auth, error handling, loading, and platform
- Configurable response parsing via `KoiResponseParser`
- Request executor with execute/silent/quick/batch/retry patterns
- JWT-based proactive + reactive token refresh interceptor
- Smart retry via `dio_smart_retry`
- Cache support via `dio_cache_interceptor`
- Multi-module Dio instance management
- `KoiNetworkRequestMixin` for controller convenience
- Full type-safe generics support
