# Task: Implement Supabase Views for Inventory and Analytics

## Research & Planning
- [x] Analyze current analytics logic in `analytics.dart` and `inventory.dart`
- [x] Design SQL views for Supabase
- [x] Create implementation plan

## Database Setup
- [x] Generate SQL scripts for Supabase views:
    - [x] `v_executive_financials`: General financial breakdown
    - [x] `v_inventory_performance`: Sales efficiency, margins, and stock value

## Flutter Implementation
- [x] Update `dtos.dart` with new response models
- [x] Update `api_service.dart` to fetch data from views
- [x] Refactor `analytics.dart` to use the new view-based API
- [x] Refactor `inventory.dart` metrics to use the new view-based API
- [x] Implement caching for offline support in `sync_service.dart`

## Verification
- [x] Verify data consistency between old logic and new views (Logic review)
- [x] Verify offline behavior (Cache implementation)
