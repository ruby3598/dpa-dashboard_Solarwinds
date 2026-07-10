# SolarWinds DPA — Trial Conversion Dashboard

A growth-marketing dashboard for the SolarWinds Database Performance Analyzer free-trial funnel, built for a Global Growth Marketing Manager (Trial Conversion & Activation) demo. Front-end reads from **Supabase**, deploys on **Vercel**, code on **GitHub**.

> Synthetic/demo data. Design concept for portfolio use — not affiliated with SolarWinds.

## What's here

```
index.html            The dashboard (View 1: Executive overview, more views in progress)
schema.sql            Creates the 5 Supabase tables + read policies
data_csv/             The data to import (trials, product_usage, email_nurture,
                      crm_opportunities, channel_performance)
```

The dashboard is built around the exact KPIs in the job description — trial conversion, trial duration, CAC, trial abandonment, and feature adoption — plus an activation funnel and a monthly conversion trend, all filterable by product, region, and deployment.

## Run it right now (no setup)

Open `index.html` in a browser. With no keys entered it runs on built-in **sample numbers**, so the page always renders — handy for a screen-share even before Supabase is wired up. (Filters activate once Supabase is connected.)

## Go live with Supabase

1. Create a free project at **supabase.com**.
2. Open **SQL Editor**, paste all of `schema.sql`, and **Run**. This creates the five tables.
3. Import the data: **Table Editor → open a table → Insert → Import data from CSV**, and upload the matching file from `data_csv/`.
   - `trials.csv` and `product_usage.csv` are all View 1 needs — import those first.
   - For `email_nurture.csv` and `channel_performance.csv`, don't map an `id` column (it's auto-generated).
4. Go to **Project Settings → API** and copy your **Project URL** and **anon public** key.
5. In `index.html`, find the `CONFIG` block near the top of the script and paste them in:
   ```js
   const SUPABASE_URL = "https://YOUR-PROJECT.supabase.co";
   const SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY";
   ```
6. Reload. The source badge (top-right) flips to **Live · Supabase** and the filters become active.

The anon key is public by design and the tables are read-only via row-level security, so it's safe to ship in a demo like this.

## Deploy to Vercel (via GitHub)

1. Push this folder to a new **GitHub** repository.
2. At **vercel.com**, click **New Project → Import** your repo.
3. Framework preset: **Other** (it's a static site — no build command, no output dir).
4. **Deploy.** You get a live URL like `your-project.vercel.app`.

Any push to GitHub redeploys automatically.

## Roadmap (views)

1. **Overview** — built ✅
2. Activation funnel — self-hosted vs SaaS drop-off
3. Acquisition & CAC by campaign
4. Engagement & nurture (+ trial-extension opportunities)
5. Experiments (A/B: landing variant A vs B)
6. Pipeline & sales handoff (PQL → SQL → revenue)
