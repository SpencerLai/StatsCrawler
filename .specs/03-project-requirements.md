# Chat Prompt 03: Project Requirements Definition

## Date
November 15, 2025

## User Request
> Update the overview of the project, this is a web service which pulls all upcoming games from NHL.com and pull all the live data of each game into a postgres database. The crawling engine will find all gamecenter links of each game and begin browswing it as the latest chrome browser

## Project Requirements Defined

### Core Purpose
StatsCrawler is a **web service for NHL game data aggregation and storage**. It automatically crawls NHL.com to collect and store comprehensive game data in a PostgreSQL database.

### Key Components

#### 1. Game Discovery System
- **Source**: NHL.com
- **Function**: Automatically retrieve all upcoming NHL games
- **Data**: Game schedules, teams, dates, venues
- **Output**: List of games to monitor

#### 2. Gamecenter Link Extraction
- **Function**: Find and extract gamecenter links for each game
- **Purpose**: Identify the specific URLs for detailed game data
- **Storage**: Track links for active monitoring

#### 3. Browser-Based Crawler
- **Technology**: Chrome browser automation (Puppeteer or Playwright)
- **Function**: Browse gamecenter pages as a real Chrome browser
- **Purpose**: Extract live game data that may be JavaScript-rendered
- **Behavior**: Simulate human browsing to access dynamic content

#### 4. Live Data Extraction
- **Source**: NHL Gamecenter pages
- **Function**: Extract real-time game statistics during live games
- **Data Types**:
  - Game scores
  - Period information
  - Player statistics
  - Play-by-play data
  - Timestamps and game status

#### 5. PostgreSQL Database
- **Purpose**: Persistent storage for all game data
- **Schema**: Store games, statistics, teams, and related data
- **Access**: Backend queries for web interface

#### 6. Web Interface
- **Framework**: Next.js with React
- **Purpose**: Display collected game data to users
- **Features**: View upcoming games, live scores, historical data

## Technology Stack Updates

### New Requirements
1. **PostgreSQL Database**
   - Primary data store
   - Needs ORM or database client
   - Schema design required

2. **Browser Automation**
   - **Options**: Puppeteer or Playwright
   - **Purpose**: Chrome browser control
   - **Use Case**: Navigate and extract data from gamecenter pages
   - **Requirement**: Headless Chrome capability

3. **Web Scraping/Crawling**
   - Extract data from NHL.com
   - Parse gamecenter pages
   - Handle dynamic JavaScript-rendered content

4. **Background Processing**
   - Scheduled jobs for game discovery
   - Continuous monitoring during live games
   - Data processing pipeline

### Architecture Implications

#### Backend Services Needed
1. **Scheduler Service**
   - Check for new games periodically
   - Monitor active games for updates
   - Trigger crawling operations

2. **Crawler Service**
   - Browser automation control
   - Page navigation and data extraction
   - Error handling and retries

3. **Data Service**
   - Database operations
   - Data validation and normalization
   - API endpoints for frontend

4. **API Layer**
   - REST or GraphQL endpoints
   - Serve game data to frontend
   - Admin endpoints for crawler management

### Data Flow
```
NHL.com → Scheduler → Game Discovery → Database (games list)
                                     ↓
                           Find Gamecenter Links
                                     ↓
                    Browser Crawler (Chrome) → Extract Live Data
                                     ↓
                           Parse & Validate Data
                                     ↓
                      PostgreSQL Database (game stats)
                                     ↓
                           API Endpoints
                                     ↓
                      Next.js Frontend → Users
```

## Updated Project Phases

### Phase 2: Architecture & Database Setup (CURRENT)
**Priority**: Set up foundation for data storage and crawling

**Tasks**:
1. PostgreSQL installation and configuration
2. Database schema design
3. ORM selection and setup (Prisma recommended)
4. Browser automation library selection
5. Initial crawler architecture design

### Phase 3: Crawler Development (NEXT)
**Priority**: Build the core crawling functionality

**Tasks**:
1. Implement NHL.com schedule scraper
2. Build gamecenter link discovery
3. Set up Chrome browser automation
4. Create data extraction logic
5. Implement parsing and validation
6. Add error handling and logging

### Phase 4: Data Storage & API
**Priority**: Connect crawler to database and expose data

**Tasks**:
1. Database models and migrations
2. Data persistence layer
3. API endpoint development
4. Data aggregation functions
5. Admin endpoints

### Phase 5: Frontend Development
**Priority**: User interface for viewing data

**Tasks**:
1. Game list and schedule views
2. Live game dashboard
3. Game detail pages
4. Data visualization
5. Real-time updates

## Technical Decisions Needed

### 1. ORM Selection
**Options**:
- **Prisma** (recommended for TypeScript)
- Drizzle ORM
- TypeORM
- Raw SQL with pg library

**Recommendation**: Prisma for type safety and developer experience

### 2. Browser Automation
**Options**:
- **Puppeteer** - Google's Chrome automation tool
- **Playwright** - Microsoft's cross-browser tool

**Recommendation**: Playwright for better API and cross-browser support (if needed)

### 3. Job Scheduling
**Options**:
- Node-cron
- Bull/BullMQ (job queue)
- Next.js API routes with setInterval
- External cron jobs

**Recommendation**: BullMQ for robust background job processing

### 4. NHL Data Access
**Considerations**:
- Is there an official NHL API?
- Rate limiting concerns with scraping
- Legal/terms of service considerations
- Data accuracy and reliability

**Action Required**: Research NHL.com API and data access policies

## Next Immediate Steps

1. **Research NHL.com Structure**
   - Identify exact URL patterns for upcoming games
   - Find gamecenter URL structure
   - Test page loading and data availability
   - Check for official API documentation

2. **Set Up PostgreSQL**
   - Install PostgreSQL locally
   - Create database
   - Design initial schema
   - Set up Prisma

3. **Prototype Crawler**
   - Install Playwright/Puppeteer
   - Create proof-of-concept scraper
   - Test data extraction from one game
   - Validate data structure

4. **Define Data Models**
   - Game entity structure
   - Statistics data structure
   - Relationships between entities
   - Indexing strategy

## Success Criteria

### Short-term (Phase 2-3)
- Successfully connect to PostgreSQL
- Extract game schedule from NHL.com
- Navigate to at least one gamecenter page
- Store one game's data in database

### Medium-term (Phase 4-5)
- Automatically discover and track all upcoming games
- Continuously update live game data
- Serve data through API endpoints
- Display games in frontend interface

### Long-term (Phase 6-7)
- Reliable 24/7 crawler operation
- Complete historical game database
- Real-time updates during live games
- Production-ready web interface

## Risks and Considerations

1. **Website Structure Changes**
   - NHL.com may change layout/structure
   - Need maintainable scraping code
   - Consider API alternatives

2. **Rate Limiting**
   - Too many requests may get blocked
   - Need respectful crawling intervals
   - Implement backoff strategies

3. **Data Volume**
   - Multiple games per day
   - Detailed statistics = large data
   - Database performance optimization needed

4. **Browser Resources**
   - Chrome instances are resource-intensive
   - May need headless mode optimization
   - Consider memory management

5. **Legal Compliance**
   - Review NHL.com terms of service
   - Ensure scraping is permitted
   - Consider data usage rights

## Updated Documentation

Modified files:
- **PROJECT_PLAN.md** - Updated with NHL-specific requirements
- **README.md** - Should be updated with project description
- Created **03-project-requirements.md** (this file)

## Outcome
Project requirements clearly defined. StatsCrawler will be an NHL game data aggregation service using PostgreSQL for storage and Chrome browser automation for data extraction from NHL.com and gamecenter pages.

