[![CI/CD](https://github.com/billqhan/rfp-ui/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/billqhan/rfp-ui/actions)
# RFP Response Platform - UI

React-based frontend for the RFP Response Platform. Provides an intuitive dashboard for viewing opportunities, matches, and reports.

## Technology Stack

- **React 18** - UI framework
- **Vite 5** - Build tool and dev server
- **TanStack Query** - Server state management
- **Axios** - HTTP client
- **Tailwind CSS** - Styling
- **Lucide React** - Icons
- **date-fns** - Date formatting

## Quick Start

### Prerequisites

- Node.js 18+ and npm
- API Gateway URL from `rfp-infrastructure` deployment

### Installation

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/billqhan/rfp-ui.git
cd rfp-ui

# Or if already cloned, initialize submodules
git submodule update --init --recursive

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Edit .env with your API Gateway URL
# VITE_API_BASE_URL=https://YOUR_API_GATEWAY_ID.execute-api.us-east-1.amazonaws.com/dev
```

### API Contracts

This repository uses contracts from `rfp-infrastructure` as a git submodule:

```bash
# Update contracts to latest version
git submodule update --remote contracts

# Validate API integration against contracts
./validate-contracts.sh
```

**Contract Location:** `contracts/rfp-contracts/openapi/api-gateway.yaml`

### Development

```bash
# Start development server
npm run dev

# Open http://localhost:5173
```

### Build

```bash
# Build for production
npm run build

# Preview production build
npm run preview
```

## Project Structure

```
rfp-ui/
├── src/
│   ├── components/         # React components
│   │   ├── Dashboard.jsx   # Main dashboard
│   │   ├── Opportunities.jsx
│   │   ├── Reports.jsx
│   │   └── Layout.jsx
│   ├── services/           # API clients
│   │   └── api.js          # Axios instance and API methods
│   ├── hooks/              # Custom React hooks
│   ├── utils/              # Utility functions
│   ├── App.jsx             # Root component
│   ├── main.jsx            # Entry point
│   └── index.css           # Global styles
├── public/                 # Static assets
├── index.html              # HTML template
├── vite.config.js          # Vite configuration
├── tailwind.config.js      # Tailwind CSS configuration
└── package.json            # Dependencies and scripts
```

## API Integration

The UI consumes the API Gateway defined in `rfp-infrastructure/rfp-contracts/openapi/api-gateway.yaml`.

### Endpoints Used

- `GET /dashboard/metrics` - Dashboard summary metrics
- `GET /dashboard/activity` - Recent activity feed
- `GET /dashboard/charts/{type}` - Chart data
- `GET /dashboard/top-matches` - Top matching opportunities
- `GET /opportunities` - List all opportunities
- `GET /opportunities/{id}` - Get single opportunity
- `GET /reports` - List all reports
- `GET /reports/{id}/download` - Download report

### Configuration

Set the API base URL in `.env`:

```env
VITE_API_BASE_URL=https://i1fnmajbyf.execute-api.us-east-1.amazonaws.com/dev
```

## Deployment

### Deploy to S3 + CloudFront

```bash
# Build production bundle
npm run build

# Deploy using provided script
./deploy.sh <environment>

# Example
./deploy.sh dev
```

The deployment script will:
1. Build the production bundle
2. Upload to S3 bucket
3. Invalidate CloudFront cache
4. Output the CloudFront URL

### Manual Deployment

```bash
# Build
npm run build

# Upload to S3
aws s3 sync dist/ s3://your-ui-bucket/ --delete

# Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `VITE_API_BASE_URL` | API Gateway base URL | Yes |
| `VITE_APP_ENV` | Environment (development, staging, production) | No |
| `VITE_DEBUG` | Enable debug logging | No |

## Features

### Dashboard
- Summary metrics (opportunities, matches, reports)
- Recent activity timeline
- Chart visualizations
- Top matching opportunities

### Opportunities
- List view with filtering and sorting
- Detail view with full opportunity information
- Match scores and recommendations

### Reports
- List of generated reports
- Download functionality
- Report status tracking

## Development Guide

### Code Style

- Use functional components with hooks
- Follow React best practices
- Use Tailwind CSS for styling
- Keep components small and focused
- Use TanStack Query for data fetching

### Adding a New Page

1. Create component in `src/components/`
2. Add route in `src/App.jsx`
3. Update navigation in `src/components/Layout.jsx`
4. Add API methods in `src/services/api.js` if needed

### API Client

The API client (`src/services/api.js`) automatically:
- Adds base URL from environment
- Handles authentication headers
- Provides centralized error handling
- Returns typed responses

## Troubleshooting

### CORS Errors

If you see CORS errors in the browser console:
1. Verify API Gateway has CORS enabled (OPTIONS methods)
2. Check Lambda functions return CORS headers
3. Verify API Gateway URL is correct in `.env`

### Build Errors

```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Clear Vite cache
rm -rf node_modules/.vite
```

### CloudFront 403 Errors

If CloudFront returns "Access Denied":
1. Verify CloudFront has Origin Access Identity (OAI)
2. Check S3 bucket policy allows CloudFront OAI
3. Verify files were uploaded to S3 correctly

## CI/CD

GitHub Actions workflow automatically:
1. Runs linting and tests
2. Builds production bundle
3. Validates contract compliance
4. Deploys to S3 + CloudFront (on main branch)

See `.github/workflows/deploy.yml` for details.

## Contract Validation

The UI references API contracts from `rfp-infrastructure/rfp-contracts/`:
- OpenAPI specification for API endpoints
- JSON schemas for request/response validation

Contracts are validated during CI/CD build process.

## Resources

- [Vite Documentation](https://vitejs.dev/)
- [React Documentation](https://react.dev/)
- [TanStack Query](https://tanstack.com/query/latest)
- [Tailwind CSS](https://tailwindcss.com/)
- [rfp-infrastructure Repository](https://github.com/billqhan/rfp-infrastructure)

## License

Internal use only - RFP Response Platform
