-- ============================================================
-- SolarWinds DPA Trial-Conversion Dashboard — Supabase schema
-- Run this in the Supabase SQL Editor BEFORE importing the CSVs.
-- Then import each CSV (Table editor -> the table -> Insert -> Import from CSV).
-- Data is synthetic/demo, so tables are world-readable via the anon key.
-- ============================================================

create table if not exists trials (
  trial_id text primary key,
  company_id text,
  signup_date date,
  product text,
  deployment_type text,
  company_size text,
  region text,
  country text,
  db_platform text,
  persona text,
  acquisition_channel text,
  campaign text,
  landing_variant text,
  trial_length_days int,
  activated boolean,
  is_pql boolean,
  sales_assisted boolean,
  became_sql boolean,
  trial_extended boolean,
  extension_days int,
  converted boolean,
  time_to_convert_days numeric,
  non_conversion_reason text,
  competitor text,
  plan text,
  acv_usd numeric,
  mrr_usd numeric,
  seats_purchased numeric,
  cac_usd numeric
);

create table if not exists product_usage (
  trial_id text primary key,
  product text,
  deployment_type text,
  installed boolean,
  install_date date,
  db_connected boolean,
  connect_date date,
  activated boolean,
  first_analysis_date date,
  time_to_activate_hrs numeric,
  days_active int,
  logins int,
  db_instances_monitored int,
  wait_time_analyses_run int,
  tuning_advisors_used int,
  anomaly_alerts_configured int,
  reports_generated int,
  seats_invited int,
  feature_adoption_rate numeric,
  engagement_score int
);

create table if not exists email_nurture (
  id bigint generated always as identity primary key,
  trial_id text,
  email_step text,
  send_date date,
  opened boolean,
  clicked boolean
);

create table if not exists crm_opportunities (
  opportunity_id text primary key,
  company_id text,
  trial_id text,
  product text,
  region text,
  company_size text,
  stage text,
  sales_assisted boolean,
  demo_date date,
  close_date date,
  won boolean,
  acv_usd numeric,
  mrr_usd numeric
);

create table if not exists channel_performance (
  id bigint generated always as identity primary key,
  month date,
  channel text,
  campaign text,
  impressions int,
  clicks int,
  sessions int,
  signups int,
  conversions int,
  spend_usd int,
  cost_per_signup numeric
);

-- ---- Row Level Security: allow public (anon) read for this demo ----
alter table trials enable row level security;
alter table product_usage enable row level security;
alter table email_nurture enable row level security;
alter table crm_opportunities enable row level security;
alter table channel_performance enable row level security;

create policy "public read trials"            on trials              for select using (true);
create policy "public read product_usage"     on product_usage       for select using (true);
create policy "public read email_nurture"     on email_nurture       for select using (true);
create policy "public read crm_opportunities" on crm_opportunities   for select using (true);
create policy "public read channel_perf"      on channel_performance for select using (true);

-- Note for CSV import: import email_nurture.csv and channel_performance.csv WITHOUT
-- an id column (it is auto-generated). trials & product_usage import as-is.
