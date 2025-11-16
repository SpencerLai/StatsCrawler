# StatsCrawler

An NHL game data aggregation service that automatically crawls NHL.com to collect and store live game statistics in a PostgreSQL database.

## Overview

StatsCrawler is a web service that:
- 🏒 Discovers upcoming NHL games from NHL.com
- 🔍 Extracts gamecenter links for each game
- 🌐 Uses Chrome browser automation to access live game data
- 💾 Stores comprehensive game statistics in PostgreSQL
- 📊 Provides a Next.js/React interface for viewing game data

Built with Next.js, React, TypeScript, and PostgreSQL.

## Getting Started

First, install the dependencies:

```bash
npm install
```

Then, run the development server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

## Available Scripts

- `npm run dev` - Start the development server
- `npm run build` - Build the application for production
- `npm start` - Start the production server
- `npm run lint` - Run ESLint

## Project Structure

- `.specs/` - Project specifications and chat history
- `app/` - Next.js App Router directory
  - `layout.tsx` - Root layout component
  - `page.tsx` - Home page
  - `globals.css` - Global styles
- `coding-standards/` - Coding style documentation and guidelines
- `database/` - PostgreSQL schema and migrations
  - `schema.sql` - Complete database schema
  - `example_queries.sql` - Common query patterns
  - `migrations/` - Database migrations
- `next.config.js` - Next.js configuration
- `tsconfig.json` - TypeScript configuration
- `.eslintrc.json` - ESLint configuration
- `.prettierrc` - Prettier configuration
- `.editorconfig` - Editor configuration

## Database Schema

Event-driven PostgreSQL schema designed for:
- ⚡ Real-time event capture with time-series partitioning
- 🔍 Complete crawler traceability
- 📊 Analytics-ready materialized views
- 🌊 Data lake streaming pipeline

Key tables:
- **events** - Fact table for all captured events (partitioned by time)
- **games** - Game metadata and status
- **players** / **teams** - Reference dimensions
- **crawler_runs** - Crawler execution tracking
- **event_stream_queue** - Data lake streaming

See `database/` folder for schema, migrations, and example queries.

## Coding Standards

This project uses TypeScript with the following style conventions:
- **Variables**: camelCase
- **Indentation**: Tabs (not spaces)
- **Quotes**: Single quotes

See the `coding-standards/` folder for detailed style guidelines and best practices.

