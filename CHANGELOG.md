# Changelog

## [0.0.2] - 2026-03-21

### Added
- Chinese README (`README_ZH.md`) with language switch links
- Retrofit / Swagger integration guide in README
- GitHub Actions CI workflow (analyze + test on PRs)

## [0.0.1] - 2026-03-17

### Added
- Initial release of `koi_network`
- Adapter-based architecture for auth, error handling, loading, and platform
- Configurable response parsing via `KoiResponseParser`
- Request executor with execute/silent/quick/batch/retry patterns
- `KoiTypedRequestExecutor` for pre-parsed strong-type responses
- `KoiTypedResponse<T>` for bridging Retrofit/OpenAPI generated models
- Typed methods in `KoiNetworkRequestMixin`: `typedRequest`, `typedSilentRequest`, `typedQuickRequest`
- Typed methods in `NetworkRequestUtils`: `typedRequest`, `typedSilentRequest`
- JWT-based proactive + reactive token refresh interceptor
- Smart retry via `dio_smart_retry`
- Cache support via `dio_cache_interceptor`
- Multi-module Dio instance management
- `KoiNetworkRequestMixin` for controller convenience
- Full type-safe generics support
- Comprehensive test suite for typed executor
