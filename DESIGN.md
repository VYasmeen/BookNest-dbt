# BookNest — Design Document

> Companion to `readme.md`. This file captures the complete design of the BookNest data product **before any code is written**. It is the single source of truth for architecture, scope, and sequencing. Every model we eventually build must trace back to a decision in this document.

---

## 0. Confirmed Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Warehouse | **DuckDB** | Local, file-based, free, zero config, SQL-standard. Perfect for a learn-locally portfolio project. |
| Transformation | **dbt-core** with `dbt-duckdb` adapter | Industry standard, free, Git-friendly, generates docs + lineage out of the box. |
| Source data | **CSV seeds** committed to the repo (with intentional DQ issues) | Reproducible by viewers, versioned in Git, no external dependencies. |
| BI tool | **ThoughtSpot** (via CSV export of Gold marts) | ThoughtSpot has no native DuckDB connector. Workflow: `dbt build` → export marts as CSV → upload to ThoughtSpot Analyst Studio → build Liveboards. This mirrors how many real teams ship small marts to ThoughtSpot. |
| Audience | **Absolute beginners** | Pacing assumes no prior dbt knowledge and limited SQL/CLI comfort. Every new concept gets a "what and why" before any "how". |
| Teaching style | **8-step structure per task** (from readme §9) | We never generate code without walking through reasoning first. |

---

## 1. The BookNest Business Story

BookNest is a growing online bookstore. Customers browse a catalog, place orders, pay, and receive books shipped from a warehouse. The business runs on a transactional system (think Postgres) that is great at *recording* events but terrible at *answering questions*. Today, when the Head of Sales asks "which genre drove the most revenue last month?", someone exports CSVs, writes a one-off Excel pivot, and ships a number nobody fully trusts.

**The problem we're solving:** BookNest has no trusted, consistent, queryable analytical layer. Reports are inconsistent across teams, metrics drift, history is lost when the operational DB is overwritten, and data-quality issues go unnoticed until they corrupt a report.

**What we're building:** A dbt-driven data product that turns raw bookstore operational data into trusted, business-ready data models that power consistent dashboards for Sales, Inventory, Customer, and Operations teams.

**Why this story matters for the project:** Every model we build must trace back to a real business question. If we can't name the question, the model shouldn't exist.

---

## 2. Business Requirements (grouped by stakeholder)

Grouping by *stakeholder* (not by table) because real analytics requirements arrive from a person who needs to make a decision.

| Stakeholder | Core questions | Decision it drives |
|---|---|---|
| **Sales leadership** | Revenue, units sold, AOV, trend by day/week/month | Set sales targets, forecast |
| **Merchandising** | Top books, top authors, top genres | What to promote / buy more of |
| **Customer / Marketing** | Who buys, how often, LTV, repeat rate | Who to retarget, email, reward |
| **Warehouse / Ops** | Current stock, low stock, out-of-stock, slow movers | Reorder, markdown, deadstock removal |
| **Finance** | Order status mix, cancellations, returns, revenue by period | Revenue recognition, write-offs |
| **Data team** | DQ issues: missing IDs, bad statuses, orphan rows | Fix pipelines, improve trust |

**Design principle derived from this:** Every Gold model must map to at least one row in this table.

---

## 3. Source Datasets

Six sources, intentionally small. More tables would feel impressive but add noise without teaching anything new.

### 3.1 `customers`
- **Purpose:** Who the customer is.
- **Columns:** `customer_id` (PK), `first_name`, `last_name`, `email`, `signup_date`, `country`, `city`.
- **DQ problems to seed intentionally:** duplicate emails with different casing, missing `country`, future `signup_date`.

### 3.2 `books`
- **Purpose:** Catalog metadata.
- **Columns:** `book_id` (PK), `title`, `author`, `genre`, `price`, `published_year`.
- **DQ problems:** inconsistent genre spelling ("Sci-Fi" vs "Science Fiction"), negative prices, author name variants.

### 3.3 `orders` (header)
- **Purpose:** One order placed by one customer at one moment.
- **Columns:** `order_id` (PK), `customer_id` (FK), `order_date`, `status` (placed/shipped/delivered/cancelled/returned), `order_total`.
- **DQ problems:** mixed-case status, `order_total` not matching sum of items, orphan `customer_id`.

### 3.4 `order_items` (lines)
- **Purpose:** The books inside an order.
- **Columns:** `order_item_id` (PK), `order_id` (FK), `book_id` (FK), `quantity`, `unit_price`.
- **DQ problems:** negative quantity, zero price, orphan `book_id`.

### 3.5 `inventory`
- **Purpose:** Current stock per book (point-in-time snapshot).
- **Columns:** `book_id` (PK), `stock_quantity`, `last_restocked_at`.
- **DQ problems:** negative stock, missing restock date.

### 3.6 `payments`
- **Purpose:** Payment event per order.
- **Columns:** `payment_id` (PK), `order_id` (FK), `payment_method`, `payment_status`, `amount`, `paid_at`.
- **DQ problems:** `amount` ≠ `order_total`, duplicate payments, `paid_at` before `order_date`.

**Why these six and not more?** They cover sales, catalog, people, operations, and money — the four question areas in the readme. Adding shipments, returns-as-separate-table, or reviews would be learning-neutral.

---

## 4. Bronze / Silver / Gold Architecture

### Bronze — "raw, but landed"
- **One model per source**, 1:1 shape with source.
- No renaming, no casting, no filtering.
- Add metadata only: `_ingested_at`, `_source_name`.
- **Why:** If Silver gets a bug, you can always rebuild from Bronze without re-reading the operational system. Bronze is your contract with the source.

### Silver — "clean and conformed"
- **One model per Bronze model**, prefixed `stg_`.
- snake_case columns, correct types, trimmed strings.
- Standardize statuses (`'Shipped'`, `'shipped '`, `'SHIPPED'` → `'shipped'`).
- Deduplicate on business keys.
- Keep grain the same as source — do NOT join yet.
- **Why one Silver per Bronze?** Keeps lineage one-to-one and debuggable. Joins happen in Gold where business logic lives.

### Gold — "business-ready"
Dimensional star schema + a few pre-aggregated marts.

**Dimensions** (slowly changing attributes about entities):
- `dim_customers`
- `dim_books`
- `dim_date` (generated, not sourced)

**Facts** (events / measurements):
- `fct_order_items` — grain: one row per book sold in an order. This is the atomic sales fact.
- `fct_orders` — grain: one row per order. Order-level metrics (AOV, status).
- `fct_inventory_snapshot` — grain: one book per snapshot date.

**Marts** (pre-aggregated, dashboard-ready):
- `sales_daily` — revenue, units, orders by day × genre.
- `customer_lifetime` — one row per customer, LTV + order count + first/last order.
- `book_performance` — one row per book, units sold, revenue, days of stock left.
- `low_stock_alert` — books below threshold.

**Why both facts *and* marts?** Facts are reusable building blocks for any analyst. Marts are opinionated answers to specific business questions. Facts give flexibility, marts give speed.

---

## 5. Final Business Outputs → Model Mapping

| Dashboard | Metric | Powered by |
|---|---|---|
| Sales | Total revenue, units, AOV | `fct_order_items`, `fct_orders` |
| Sales | Revenue by genre / author / book | `fct_order_items` + `dim_books` |
| Sales | Sales over time | `sales_daily` |
| Customer | Active customers, LTV, top customers | `customer_lifetime` |
| Inventory | Current stock, low stock, out of stock | `fct_inventory_snapshot`, `low_stock_alert` |
| Inventory | Slow-moving books | `book_performance` |
| Ops | Order status mix, cancellations | `fct_orders` |

**The chain to make explicit in the series:**
`raw CSV → Bronze table → Silver stg_ → Gold dim/fact → Mart → ThoughtSpot Liveboard`

---

## 6. ERD (text)

```
customers (customer_id PK)
    │ 1
    │
    │ M
orders (order_id PK, customer_id FK)
    │ 1                        │ 1
    │                          │
    │ M                        │ 1
order_items                 payments
(order_item_id PK,          (payment_id PK,
 order_id FK,                order_id FK)
 book_id FK)
    │ M
    │
    │ 1
books (book_id PK)
    │ 1
    │
    │ 1
inventory (book_id PK/FK)
```

---

## 7. dbt Project Structure

```
BookNest-dbt/
├── dbt_project.yml
├── packages.yml
├── profiles.yml                  # local, gitignored
├── seeds/                        # our fake source CSVs
│   ├── raw_customers.csv
│   ├── raw_books.csv
│   ├── raw_orders.csv
│   ├── raw_order_items.csv
│   ├── raw_inventory.csv
│   └── raw_payments.csv
├── models/
│   ├── bronze/
│   │   ├── _bronze__sources.yml
│   │   ├── bronze_customers.sql
│   │   ├── bronze_books.sql
│   │   ├── bronze_orders.sql
│   │   ├── bronze_order_items.sql
│   │   ├── bronze_inventory.sql
│   │   └── bronze_payments.sql
│   ├── silver/
│   │   ├── _silver__models.yml
│   │   ├── stg_customers.sql
│   │   ├── stg_books.sql
│   │   ├── stg_orders.sql
│   │   ├── stg_order_items.sql
│   │   ├── stg_inventory.sql
│   │   └── stg_payments.sql
│   └── gold/
│       ├── _gold__models.yml
│       ├── dim/
│       │   ├── dim_customers.sql
│       │   ├── dim_books.sql
│       │   └── dim_date.sql
│       ├── fct/
│       │   ├── fct_order_items.sql
│       │   ├── fct_orders.sql
│       │   └── fct_inventory_snapshot.sql
│       └── marts/
│           ├── sales_daily.sql
│           ├── customer_lifetime.sql
│           ├── book_performance.sql
│           └── low_stock_alert.sql
├── snapshots/
│   └── snap_inventory.sql        # SCD2 of inventory
├── macros/                       # introduced only when needed
├── tests/                        # custom singular tests
├── exports/                      # CSV exports of Gold marts for ThoughtSpot
└── analyses/
```

**Why seeds instead of a real DB?** For a portfolio project, seeds are reproducible, versioned in Git, and let viewers run the whole thing with `dbt seed && dbt build`. We can migrate to real sources later.

---

## 8. Technology Stack

| Layer | Choice | Why |
|---|---|---|
| Warehouse | **DuckDB** | In-process, zero config, free, SQL-standard, blazingly fast locally |
| Transformation | **dbt-core** (open source) | Industry standard, free, Git-friendly |
| Source data | **CSV seeds** | Reproducible, viewable in GitHub |
| Docs/lineage | **dbt docs** | Built-in, auto-generated |
| BI output | **ThoughtSpot** (CSV upload workflow) | Search-driven analytics; marts exported from DuckDB as CSV |
| Version control | **Git + GitHub** | Standard |

**What we are deliberately NOT using (yet):** Snowflake / BigQuery / Databricks, Airflow, Kafka, dbt Cloud. They would obscure the dbt learning. BookNest can graduate to Databricks in a bonus episode later.

### ThoughtSpot integration workflow

```
1. dbt build                                    # produce Gold marts in DuckDB
2. python scripts/export_marts.py               # dump 4 marts to exports/*.csv
3. Upload CSVs to ThoughtSpot Analyst Studio    # one-time per refresh
4. Build Liveboards in ThoughtSpot              # Sales, Inventory, Customer, Ops
```

A tiny Python/DuckDB export script will be introduced in the final BI episode — nothing fancy, ~15 lines.

---

## 9. Episode Roadmap (series)

| # | Episode | Business problem solved | New dbt concept |
|---|---|---|---|
| 1 | Why dbt? The BookNest story | Framing: untrusted reports | — |
| 2 | Project setup + DuckDB + seeds | Getting raw data loaded | `dbt seed`, `profiles.yml` |
| 3 | Building Bronze | "Where does raw data live?" | Models, materializations (`view` vs `table`) |
| 4 | Sources & `source()` | Why pretend seeds are sources | `sources.yml`, `source()` |
| 5 | Silver / `stg_` models | Cleaning dirty data | `ref()`, naming conventions, dependencies |
| 6 | Dimensions in Gold | Who is the customer, what is the book | SCD1 dim modeling |
| 7 | `dim_date` without a source | Why we fabricate a date dim | Jinja, generators |
| 8 | Fact tables | The atomic sales fact | Grain discipline, joins |
| 9 | Pre-aggregated marts | Dashboard-ready metrics | Mart-layer thinking |
| 10 | Data tests | How do we trust this? | `unique`, `not_null`, `relationships`, `accepted_values` |
| 11 | Custom + singular tests | Business-rule tests | Custom test SQL |
| 12 | Docs + lineage | Explaining the pipeline | `dbt docs generate` |
| 13 | Jinja + macros | DRY-ing repeated SQL | Macros |
| 14 | Incremental models | "Why rebuild everything every night?" | `is_incremental()` |
| 15 | Snapshots / SCD2 | Tracking inventory over time | `snapshots` |
| 16 | Final BI output | The payoff — ThoughtSpot Liveboards | CSV export + Liveboard design |
| 17 (bonus) | BookNest → Databricks | Scaling to the cloud | Platform migration |

Audience is **absolute beginners**, so Episodes 1–5 should move slowly: define warehouse, model, materialization, and ref() before using them.

---

## 10. Recommended Implementation Order

Each step is self-contained and runnable.

1. Install `dbt-duckdb`, scaffold the project, confirm `dbt debug` works.
2. Design the seed CSVs (~20–50 rows per table, with intentional DQ issues baked in). You will learn more from this step than you expect.
3. Load seeds, declare them in `sources.yml`.
4. Build **Bronze** (6 models). Prove `dbt run --select bronze` works.
5. Build **Silver `stg_`** models (6 models). Add `not_null` / `unique` tests.
6. Build `dim_customers`, `dim_books`, `dim_date`.
7. Build `fct_order_items`, `fct_orders`.
8. Build the marts (`sales_daily`, `customer_lifetime`, `book_performance`, `low_stock_alert`).
9. Add `relationships` tests between facts and dims.
10. Add docs (`description:` in every yml) and generate lineage.
11. Introduce Jinja/macros by refactoring a repeated pattern you'll naturally hit.
12. Add a snapshot on `inventory` so we can answer "what was stock on this date?"
13. Make one model incremental (orders is a good candidate).
14. Export marts to CSV and build ThoughtSpot Liveboards.

---

## 11. Final Architecture (text diagram)

```
       CSV seeds
   (raw_* in /seeds)
          │
          ▼
    ┌──────────┐
    │  BRONZE  │   1:1 with source, +metadata
    └──────────┘
          │
          ▼
    ┌──────────┐
    │  SILVER  │   cleaned, typed, standardized (stg_*)
    └──────────┘
          │
          ▼
    ┌──────────┐
    │   GOLD   │   dim_* + fct_* (star schema)
    └──────────┘
          │
          ▼
    ┌──────────┐
    │  MARTS   │   sales_daily, customer_lifetime,
    │          │   book_performance, low_stock_alert
    └──────────┘
          │
          ▼
    exports/*.csv
          │
          ▼
     ThoughtSpot
      Liveboards
```

---

## 12. Guardrails (from readme §13)

- Do not over-engineer. Every model must have a reason to exist.
- Every transformation must solve a business or data-quality problem.
- Every Gold model must have a clear business purpose.
- Every decision must be explainable in simple language.
- Small enough to understand end-to-end; realistic enough for a portfolio.

---

## 13. Next Action

**Episode 2 / Step 1 — Project scaffolding.**

Following the 8-step teaching structure from readme §9, the next conversation will:

1. **What we're accomplishing:** Create a dbt project directory that `dbt debug` recognizes and that can connect to a local DuckDB file.
2. **Engineering reasoning:** dbt needs two things to run — a project (`dbt_project.yml`) describing *what* to transform, and a profile (`profiles.yml`) describing *where* to transform it. DuckDB is file-based, so the "where" is just a path to a `.duckdb` file.
3. **Design question for you:** Where should the DuckDB file live — inside the repo (easy, but committing a binary DB is bad practice) or in your home directory (cleaner, but less portable)? What are the trade-offs?

We will pause after step 3 and wait for your answer before writing any files.
