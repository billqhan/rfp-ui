# Dashboard TypeError Fix

## Issue
UI showed error: `TypeError: c.map is not a function` in `charts-BHGUu5cD.js`

## Root Cause
The Dashboard component was calling multiple API endpoints that don't exist:
- `/dashboard/chart-data/opportunities/7d` → 404 Not Found
- `/dashboard/activity` → 404 Not Found
- `/dashboard/top-matches` → 404 Not Found

When CloudFront couldn't route these to the ALB (due to cache), it served the HTML index page instead of JSON, causing `.map()` to be called on an HTML string.

## Available API Endpoint
The Java backend only provides ONE endpoint: `/dashboard/metrics`

This endpoint returns ALL dashboard data including:
```json
{
  "total_opportunities": 68,
  "total_matches": null,
  "active_workflows": 2,
  "opportunities_over_time": [...],  // Array for chart
  "matches_over_time": [...],         // Array for chart
  "recent_opportunities": [...],      // For activity feed
  "recent_matches": [...]             // For top matches
}
```

## Solution Applied

### 1. Removed Non-Existent API Calls
**Before:**
```javascript
const { data: metrics } = useQuery({ ... })
const { data: chartData } = useQuery({ ... })          // ❌ 404
const { data: recentActivity } = useQuery({ ... })     // ❌ 404
const { data: topMatches } = useQuery({ ... })         // ❌ 404
```

**After:**
```javascript
// Single API call to get all dashboard data
const { data: metrics } = useQuery({ ... })
```

### 2. Extract Data from Single Metrics Response
```javascript
// Extract chart data from metrics
const chartData = metrics?.opportunities_over_time?.map((item, index) => ({
  date: item.date ? new Date(item.date).toLocaleDateString() : '',
  opportunities: item.count || 0,
  matches: metrics?.matches_over_time?.[index]?.count || 0,
}))

// Extract recent activity
const recentActivity = metrics?.recent_opportunities?.slice(0, 5)?.map(opp => ({
  type: 'info',
  message: `New opportunity: ${opp.title}`,
  time: opp.posted_date ? new Date(opp.posted_date).toLocaleDateString() : '',
}))

// Extract top matches
const topMatches = metrics?.recent_matches?.slice(0, 5)?.map(match => ({
  title: match.opportunity_title,
  agency: 'Unknown',
  score: match.match_score,
  value: '-',
  date: match.match_date ? new Date(match.match_date).toLocaleDateString() : '',
}))
```

### 3. Added Loading States and Empty Data Handling
```javascript
{metricsLoading ? (
  <div className="flex items-center justify-center h-[300px]">
    <div className="text-gray-400">Loading chart data...</div>
  </div>
) : displayChartData && displayChartData.length > 0 ? (
  <ResponsiveContainer width="100%" height={300}>
    <LineChart data={displayChartData}>
      ...
    </LineChart>
  </ResponsiveContainer>
) : (
  <div className="flex items-center justify-center h-[300px]">
    <div className="text-gray-400">No chart data available</div>
  </div>
)}
```

### 4. Simplified Date Formatting
Removed complex date parsing that could fail:
```javascript
// Before (could throw errors)
tickFormatter={(date) => format(parseISO(date), 'MMM dd')}

// After (simple and safe)
<XAxis dataKey="date" />
```

## Files Changed
- `src/pages/Dashboard.jsx` - Refactored to use single API endpoint

## Testing
```bash
# Test API endpoint
curl https://d3bq9x49ahr8gq.cloudfront.net/api/dashboard/metrics

# Test UI
curl https://d3bq9x49ahr8gq.cloudfront.net/
```

## Deployment
```bash
npm run build
aws s3 sync dist/ s3://rfp-han-dev-ui --delete
aws cloudfront create-invalidation --distribution-id E31OSXN880F2UX --paths "/*"
```

## Verification
✅ UI loads without errors
✅ Dashboard displays metrics from API
✅ Chart renders with real data
✅ No more `.map()` errors
✅ Proper loading states
✅ Graceful handling of missing data

## Git Commit
```
commit abe29f2
fix: Dashboard to use single /dashboard/metrics API endpoint
```

## Related Issues Fixed
1. **CloudFront API Routing**: Some API paths were cached and returning HTML
2. **Non-Existent Endpoints**: UI was calling endpoints that don't exist in Java backend
3. **Type Errors**: Calling `.map()` on non-array data
4. **Date Parsing**: Complex date formatting that could fail

## Date
November 24, 2025
