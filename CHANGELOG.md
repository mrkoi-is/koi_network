# Changelog

## [0.0.4] - 2026-07-06

### Changed
- Enable SSL certificate validation by default for `KoiNetworkConfig.create()`
  and `KoiNetworkConfig.production()`.
- Keep development and testing configurations opt-out by default for local and
  self-signed services.

### Added
- Add explicit `validateCertificate` overrides to `KoiNetworkConfig.production`,
  `KoiNetworkConfig.development`, `KoiNetworkConfig.testing`, and
  `KoiNetworkInitializer.initialize` / `reinitialize`.

## [0.0.3] - 2026-07-06

### Added
- Export `package:dio/dio.dart` from the public library for convenience.
- Add `KoiHeaderBuilder` support for injecting dynamic per-request headers.
- Add typed batch request helpers to `KoiNetworkRequestMixin` and `NetworkRequestUtils`.

### Changed
- Preserve an externally injected `Authorization` header instead of overwriting it with the auth adapter token.
- Pass configured header builders through `KoiNetworkInitializer`, `KoiNetworkConfig`, and `KoiDioFactory`.

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
