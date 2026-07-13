-- SolarWinds DPA trial dashboard — schema v2
-- Run this in the Supabase SQL editor, then import the 6 CSVs via
-- Table Editor > Import data from CSV (or `\copy` from psql).
--
-- CHANGES vs v1:
--   trials.ad_group            NEW  — CAC/quality now live at ad-group level
--   product_usage.instances_monitored NEW — this is what drives is_pql
--   campaign_performance       NEW table (was folded into channel_performance)
--   CHECK constraints on the funnel — the DB now REFUSES to store a broken funnel

drop table if exists crm_opportunities cascade;
drop table if exists product_usage cascade;
drop table if exists campaign_performance cascade;
drop table if exists channel_performance cascade;
drop table if exists email_nurture cascade;
drop table if exists trials cascade;

create table trials (
  trial_id              text primary key,
  signup_date           date        not null,
  month                 text        not null,
  product               text        not null,
  deployment_type       text        not null check (deployment_type in ('saas','self_hosted')),
  region                text        not null,
  company_size          text        not null check (company_size in ('SMB','mid_market','enterprise')),
  persona               text        not null,
  acquisition_channel   text        not null,
  campaign              text        not null,
  ad_group              text        not null,
  landing_variant       char(1)     not null check (landing_variant in ('A','B')),
  installed             boolean     not null,
  db_connected          boolean     not null,
  activated             boolean     not null,
  is_pql                boolean     not null,
  converted             boolean     not null,
  sales_assisted        boolean     not null,
  trial_extended        boolean     not null,
  non_conversion_reason text,
  cac_usd               numeric(10,2) not null,
  acv_usd               numeric(12,2),
  time_to_activate_hrs  numeric(8,1),
  time_to_convert_days  numeric(6,1),

  -- the funnel must nest. this is the constraint that would have caught v1.
  constraint funnel_nests check (
        (not db_connected or installed)
    and (not activated    or db_connected)
    and (not is_pql       or activated)
    and (not converted    or activated)
  ),
  constraint acv_iff_converted check (
        (converted and acv_usd is not null)
     or (not converted and acv_usd is null)
  ),
  constraint reason_iff_lost check (
        (converted and non_conversion_reason is null)
     or (not converted and non_conversion_reason is not null)
  )
);

create table product_usage (
  trial_id                  text primary key references trials(trial_id) on delete cascade,
  logins                    int  not null,
  instances_monitored       int  not null,
  wait_time_analyses_run    int  not null,
  tuning_advisors_used      int  not null,
  anomaly_alerts_configured int  not null,
  reports_generated         int  not null,
  feature_adoption_rate     numeric(4,2) not null,
  engagement_score          int  not null
);

create table channel_performance (
  month               text not null,
  acquisition_channel text not null,
  signups             int  not null,
  conversions         int  not null,
  spend_usd           numeric(12,2) not null,
  primary key (month, acquisition_channel)
);

create table campaign_performance (
  month               text not null,
  acquisition_channel text not null,
  campaign            text not null,
  ad_group            text not null,
  impressions         bigint not null,
  clicks              bigint not null,
  spend_usd           numeric(12,2) not null,
  signups             int not null,
  activated           int not null,
  conversions         int not null,
  primary key (month, campaign, ad_group)
);

create table crm_opportunities (
  opportunity_id text primary key,
  trial_id       text references trials(trial_id) on delete cascade,
  product        text not null,
  region         text not null,
  stage          text not null,
  won            boolean not null,
  acv_usd        numeric(12,2)
);

create table email_nurture (
  month     text not null,
  step      text not null,
  trial_day int  not null,
  sent      int  not null,
  opened    int  not null,
  clicked   int  not null,
  primary key (month, step)
);

create index on trials (acquisition_channel, month);
create index on trials (deployment_type);
create index on trials (ad_group);
create index on trials (converted) where converted;

-- ---------------------------------------------------------------------------
-- Sanity checks. Run AFTER import. Every one must return 0 rows / expected value.
-- ---------------------------------------------------------------------------

-- 1. funnel nests (the CHECK constraint enforces this, so this is belt-and-braces)
select count(*) as broken_funnel from trials
where (db_connected and not installed)
   or (activated and not db_connected)
   or (converted and not activated);

-- 2. trial -> customer should be ~3%
select round(100.0 * avg(converted::int), 1) as trial_to_customer_pct from trials;

-- 3. LTV/CAC should be 3-5x
select round(
         (select avg(acv_usd) from trials where converted)
       / ((select sum(cac_usd) from trials) / (select count(*) from trials where converted))
       , 1) as ltv_cac;

-- 4. CAC must NOT be flat across paid search ad groups
select ad_group,
       count(*)                        as signups,
       round(avg(cac_usd))             as avg_cac,
       round(100.0*avg(converted::int),1) as conv_pct,
       round(sum(cac_usd) / nullif(count(*) filter (where converted), 0)) as cac_per_customer
from trials
where acquisition_channel = 'paid_search'
group by 1
order by cac_per_customer desc;

-- 5. THE contribution query — won ACV minus spend, per channel
select acquisition_channel,
       count(*)                                          as signups,
       round(sum(cac_usd))                               as spend,
       count(*) filter (where converted)                 as customers,
       round(coalesce(sum(acv_usd), 0))                  as won_acv,
       round(coalesce(sum(acv_usd), 0) - sum(cac_usd))   as contribution,
       round(coalesce(sum(acv_usd), 0) / sum(cac_usd), 1) as roas
from trials
group by 1
order by roas;
