# StatsCrawler - Project Plan

## Project Overview
StatsCrawler is a web service that automatically crawls and stores NHL game data. The application pulls all upcoming games from NHL.com, tracks live game data, and stores comprehensive statistics in a PostgreSQL database.

### Core Functionality
- **Game Discovery**: Automatically retrieves all upcoming NHL games from NHL.com
- **Live Data Crawling**: Monitors and captures real-time game statistics during live games
- **Gamecenter Browsing**: Uses browser automation (Chrome) to access and extract data from NHL gamecenter links
- **Data Storage**: Persists all game data and statistics in a PostgreSQL database
- **Web Interface**: Provides a Next.js/React interface for viewing and analyzing the collected data

## Current Status
**Phase**: Initial Setup Complete ✅

### Completed
- [x] Next.js project initialization with App Router
- [x] TypeScript configuration
- [x] React 18 integration
- [x] ESLint setup
- [x] Comprehensive coding standards documentation
- [x] Code style enforcement (camelCase, tabs)
- [x] Prettier and EditorConfig setup
- [x] VS Code workspace settings
- [x] Initial project structure
- [x] Documentation (README, style guide)

## Technology Stack

### Frontend
- **Framework**: Next.js 14 (App Router)
- **UI Library**: React 18
- **Language**: TypeScript 5
- **Styling**: CSS (extensible to CSS Modules, Tailwind, etc.)

### Backend & Data
- **Database**: PostgreSQL - Primary data store for game statistics
- **ORM**: (TBD - Prisma, Drizzle, or raw SQL)
- **Browser Automation**: Puppeteer or Playwright - Chrome browser control for crawling
- **API**: Next.js API Routes - Backend endpoints for data operations

### Data Sources
- **NHL.com**: Primary source for upcoming games and schedules
- **NHL Gamecenter**: Live game data and detailed statistics

### Development Tools
- **Linting**: ESLint with TypeScript support
- **Formatting**: Prettier
- **Editor Config**: EditorConfig
- **Package Manager**: npm
- **Version Control**: Git

### Code Standards
- Variables: camelCase
- Types/Interfaces: PascalCase
- Indentation: Tabs
- Quotes: Single quotes
- Line length: 100 characters

## Project Structure

```
StatsCrawler/
├── .specs/                    # Project specifications and chat history
│   ├── 01-initial-setup.md
│   ├── 02-coding-standards.md
│   └── PROJECT_PLAN.md
├── .vscode/                   # VS Code settings
│   └── settings.json
├── app/                       # Next.js App Router
│   ├── layout.tsx            # Root layout
│   ├── page.tsx              # Home page
│   └── globals.css           # Global styles
├── coding-standards/          # Coding style documentation
│   ├── STYLE_GUIDE.md
│   └── README.md
├── .editorconfig             # Editor configuration
├── .eslintrc.json            # ESLint configuration
├── .gitignore                # Git ignore rules
├── .prettierrc               # Prettier configuration
├── next.config.js            # Next.js configuration
├── package.json              # Dependencies and scripts
├── README.md                 # Project documentation
└── tsconfig.json             # TypeScript configuration
```

## Planned Structure (Future)

```
StatsCrawler/
├── .specs/                   # Specifications
├── app/                      # Next.js pages
│   ├── api/                 # API routes (future)
│   ├── (routes)/            # Route groups (future)
│   └── ...
├── components/               # Reusable React components (future)
│   ├── ui/                  # UI components
│   └── features/            # Feature-specific components
├── lib/                      # Utility functions and helpers (future)
│   ├── utils/               # General utilities
│   └── api/                 # API client functions
├── types/                    # TypeScript type definitions (future)
├── public/                   # Static assets (future)
│   ├── images/
│   └── fonts/
├── styles/                   # Additional styles (future)
└── tests/                    # Test files (future)
```

## Development Phases

### Phase 1: Foundation ✅ (COMPLETED)
- [x] Project initialization
- [x] Coding standards setup
- [x] Development environment configuration
- [x] Documentation structure

### Phase 2: Architecture & Database Setup (CURRENT)
- [x] Define specific application requirements (NHL stats crawling)
- [x] Identify data sources (NHL.com, NHL Gamecenter)
- [x] Database selection (PostgreSQL)
- [x] Design database schema for games and statistics
- [x] Design event-driven architecture for data capture
- [x] Plan data lake streaming pipeline
- [ ] Install PostgreSQL and create database
- [ ] Run schema migrations
- [ ] Set up Prisma ORM for TypeScript types
- [ ] Design crawler architecture
- [ ] Select browser automation library (Puppeteer vs Playwright)
- [ ] Design API endpoints structure

### Phase 3: Crawler Development (FUTURE)
- [ ] Set up browser automation (Chrome/Puppeteer/Playwright)
- [ ] Implement NHL.com schedule scraper
- [ ] Build gamecenter link discovery system
- [ ] Create live game data extraction logic
- [ ] Implement data parsing and validation
- [ ] Set up automated crawling scheduler
- [ ] Error handling and retry logic
- [ ] Logging and monitoring for crawler

### Phase 4: Data Storage & API (FUTURE)
- [ ] Implement database models and migrations
- [ ] Create API endpoints for game data retrieval
- [ ] Build data aggregation and statistics calculations
- [ ] Implement caching layer for performance
- [ ] Create webhook/event system for live updates
- [ ] Build admin endpoints for crawler management

### Phase 5: UI/UX Development (FUTURE)
- [ ] Design game list and schedule views
- [ ] Create live game dashboard
- [ ] Build game detail pages with statistics
- [ ] Implement data visualization (charts, graphs)
- [ ] Real-time updates for live games
- [ ] Responsive design for mobile
- [ ] Search and filter functionality
- [ ] Dark/light mode

### Phase 6: Testing & Quality (FUTURE)
- [ ] Unit tests
- [ ] Integration tests
- [ ] E2E tests
- [ ] Performance optimization
- [ ] Accessibility testing
- [ ] Cross-browser testing

### Phase 7: Deployment (FUTURE)
- [ ] Production build optimization
- [ ] Environment configuration
- [ ] Deployment platform selection
- [ ] CI/CD pipeline
- [ ] Monitoring and logging

## Next Steps

### Immediate Actions Needed
1. **Database Setup**
   - Install and configure PostgreSQL
   - Design database schema for:
     - Games (id, date, teams, status, venue, etc.)
     - Game statistics (scores, periods, player stats, etc.)
     - Teams information
     - Players information (if needed)
   - Choose ORM/database client (Prisma recommended for TypeScript)
   - Create initial migrations

2. **Browser Automation Setup**
   - Choose between Puppeteer vs Playwright
   - Install and configure Chrome automation
   - Test basic NHL.com page navigation
   - Research NHL.com structure and gamecenter URL patterns

3. **Crawler Architecture**
   - Design crawler workflow:
     1. Fetch upcoming games schedule
     2. Extract gamecenter links
     3. Monitor games for live status
     4. Extract and parse game data
     5. Store in database
   - Plan scheduling system (cron jobs, intervals)
   - Design error handling and logging strategy

4. **API Endpoints Planning**
   - GET /api/games - List upcoming/past games
   - GET /api/games/[id] - Game details
   - GET /api/games/live - Currently live games
   - POST /api/crawler/trigger - Manual crawler trigger (admin)
   - GET /api/crawler/status - Crawler health check

### Future Considerations
- **Performance**: SSR vs. CSR strategy
- **SEO**: Metadata and sitemap strategy
- **Analytics**: User behavior tracking
- **Scalability**: Architecture for growth
- **Security**: Data protection and validation
- **Internationalization**: Multi-language support (if needed)

## Questions to Address
1. What specific NHL statistics should be captured?
   - Scores, goals, assists, penalties?
   - Player-level statistics?
   - Play-by-play data?
   - Shot maps and advanced analytics?

2. How frequently should games be checked for updates?
   - Continuous polling during live games?
   - Every minute, 30 seconds, or real-time?

3. Data retention policy:
   - How long to keep historical game data?
   - Archive old seasons?

4. User features:
   - Public access or authentication required?
   - User accounts for favorites/notifications?
   - Email/push notifications for game updates?

5. NHL.com structure:
   - What is the exact URL pattern for gamecenter?
   - Does NHL.com have an official API we should use instead?
   - Rate limiting concerns?

6. Performance considerations:
   - How many concurrent games during peak times?
   - Database indexing strategy?
   - Caching layer needed?

7. Deployment:
   - Where will the crawler run (same server as web app)?
   - Need for separate worker processes?
   - Background job queue system?

## Success Metrics (TBD)
- Define KPIs once requirements are clear
- Performance benchmarks
- User engagement metrics
- Data accuracy metrics

## Notes
- Project is using modern Next.js App Router pattern
- All code follows strict TypeScript typing
- Code style is enforced through automated tools
- Documentation is maintained alongside code

---

**Last Updated**: November 15, 2025
**Status**: Phase 1 Complete, Phase 2 (Architecture & Database) In Progress
**Data Source**: NHL.com and NHL Gamecenter

