## 1. Remove official online UI and navigation surfaces

- [x] 1.1 Remove official website and plugin-market menu entries from backend seeded menus
- [x] 1.2 Remove or simplify frontend entry points that expose official hosted AI analysis or remote-only plugin actions

## 2. Remove official outbound service dependencies

- [x] 2.1 Remove backend service calls that download skills or plugins from official GVA domains
- [x] 2.2 Remove default backend configuration values that point to official GVA-hosted runtime services
- [x] 2.3 Remove frontend proxy or runtime config that targets official GVA internet endpoints

## 3. Verify offline-safe runtime constraints

- [x] 3.1 Search the affected code paths for remaining official GVA outbound domains or links
- [x] 3.2 Sanity-check that local admin functionality still has valid source code paths after removals
