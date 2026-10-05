I want to build a realistic end-to-end data engineering portfolio project called **BookNest**, a fictional online bookstore.

The goal is NOT to create a collection of random SQL models. I want to build a small but realistic **business-driven data product** where raw bookstore data is transformed into trusted, business-ready data that can answer real business questions.

### My learning philosophy

I am using AI as a development assistant, but I do NOT want AI to blindly generate code for me.

For every major technical decision:

1. Explain the business problem first.
2. Explain the data engineering concept.
3. Explain why we need the transformation.
4. Explain why you chose the particular design.
5. Show the proposed implementation.
6. Explain the SQL/code line by line when necessary.
7. Mention alternatives and why we are not choosing them.
8. Identify what could go wrong.
9. Suggest appropriate tests.
10. Only then provide the final code.

I want to understand the engineering decisions behind the project.

---

# 1. Business Story

BookNest is an online bookstore that sells books to customers.

Imagine BookNest is growing and the business team wants to understand:

### Sales

* How many books are being sold?
* What is total revenue?
* Which books sell the most?
* Which authors generate the most revenue?
* Which genres perform best?
* How are sales changing over time?
* What is the average order value?

### Inventory

* How many books are currently in stock?
* Which books are low in stock?
* Which books are out of stock?
* Which genres have the most inventory?
* Which books have high inventory but low sales?

### Customers

* How many customers are purchasing?
* Who are the most valuable customers?
* How much does each customer spend?
* How many orders does each customer place?
* What is the average customer spend?

### Operations

* How many orders are placed?
* What is the order status distribution?
* How many orders are cancelled or returned?
* Are there data-quality problems in the source systems?

First define the business questions that the final data product must answer.

Do not create technical models until the business requirements are clear.

---

# 2. Design the Source Data

Design realistic source datasets for BookNest.

At minimum consider:

* customers
* books
* orders
* order_items
* inventory
* payments

For every source dataset, define:

* purpose
* columns
* data types
* primary key
* important relationships
* example records
* possible data-quality problems
* realistic business rules

Keep the project small enough for a beginner to understand, but realistic enough to demonstrate professional data engineering concepts.

---

# 3. Bronze Layer

Design a Bronze layer that represents raw/source data.

The Bronze layer should preserve the source data as much as reasonably possible.

Explain:

* What belongs in Bronze?
* What transformations should NOT happen here?
* What metadata should we consider?
* How should we name Bronze models/tables?
* How does Bronze differ from Silver?

Do not over-engineer this layer.

---

# 4. Silver Layer

Design the Silver layer for cleaned and standardized data.

Possible responsibilities include:

* standardizing column names
* handling data types
* cleaning invalid values
* handling nulls
* standardizing status values
* removing or identifying duplicates
* applying basic business rules
* creating clean relationships between entities

Propose appropriate staging/Silver models.

For each model explain:

* source
* purpose
* transformations
* primary key
* important columns
* data-quality assumptions

---

# 5. Gold Layer

Design the Gold layer around actual business questions.

Do NOT simply copy Silver tables into Gold.

Create business-ready models that allow analysts or dashboards to answer questions easily.

Consider models such as:

* fact_sales
* fact_orders
* fact_inventory
* dim_books
* dim_customers
* dim_date
* sales_summary
* inventory_summary
* customer_summary

But do not blindly use these names.

Decide what the best Gold model structure should be based on the BookNest business requirements.

For every Gold model explain:

* business purpose
* grain
* dimensions
* measures
* relationships
* important metrics
* example business questions it answers

---

# 6. Final Business Output

The final BookNest data product should be able to produce business-ready outputs such as:

### Sales dashboard/report

* total revenue
* books sold
* orders
* average order value
* revenue by genre
* revenue by book
* revenue by author
* sales over time

### Inventory dashboard/report

* current stock
* low-stock books
* out-of-stock books
* inventory by genre
* slow-moving books

### Customer dashboard/report

* total customers
* active customers
* top customers
* customer lifetime spend
* average customer spend
* orders per customer

Explain which Gold models would power each metric.

Also clearly distinguish between:

**raw data → transformed data → business metrics → dashboard/report**

---

# 7. dbt

Use dbt as the transformation and analytics engineering layer.

The project should demonstrate important dbt concepts progressively:

* dbt project structure
* SQL models
* sources
* ref()
* dependencies
* staging models
* marts
* tests/data tests
* documentation
* lineage
* Jinja
* macros
* incremental models
* snapshots/SCD Type 2
* production practices

Do not introduce everything at once.

Create a logical progression where each concept solves a problem that appears naturally in the BookNest project.

dbt should be used to create modular, maintainable transformation models and trusted data products.

---

# 8. Data Quality

Design realistic data-quality checks.

Examples:

* customer_id should not be null
* order_id should be unique
* book_id should exist
* order quantity should be positive
* price should not be negative
* order status should contain accepted values
* customer relationships should be valid
* sales amounts should follow business rules

Explain which tests belong at which layer and why.

Use dbt data tests appropriately. dbt supports assertions such as unique, not_null, accepted_values, and relationships, along with custom SQL-based tests.

---

# 9. AI-Assisted Development

I want AI to help me build the project, but I want the development process to remain understandable.

For every implementation task:

### Step 1

Explain what we are trying to accomplish.

### Step 2

Explain the engineering reasoning.

### Step 3

Ask me a short question to make me think about the design.

### Step 4

Propose the implementation.

### Step 5

Generate the code only after explaining it.

### Step 6

Explain the generated code.

### Step 7

Give me tests/checks to verify it.

### Step 8

Tell me what I should be able to explain to another data engineer or interviewer after completing this step.

Never encourage me to copy AI-generated code without understanding it.

---

# 10. Technology Progression

Start simple.

The project should be possible to understand locally first.

Then progressively introduce:

SQL
↓
dbt
↓
data modeling
↓
Bronze/Silver/Gold
↓
testing/documentation/lineage
↓
ouput as report required for bi


---

# 11. series

Design the project so each major technical milestone can become a video.

Potential progression:

1. dbt Fundamentals
2. Setting up the BookNest data product
3. Understanding the Bronze layer
4. Building Silver/staging models
5. Building Gold/business models
6. dbt ref() and lineage
7. Data quality and testing
8. Documentation
9. Jinja and macros
10. Incremental models
11. Snapshots / SCD Type 2
12. Building the final BookNest analytics output
13. Taking BookNest toward Databricks/Delta Lake/Workflows

For each episode, identify:

* what we are building
* what the viewer learns
* what business problem it solves
* what technical concept is introduced
* what should be demonstrated on screen
* what the final output should look like

The videos should feel like viewers are watching a real data product being built, not watching disconnected tutorials.

---

# 12. Final Architecture

At the end, provide a clean architecture diagram in text showing:

Source Data
↓
Bronze
↓
Silver
↓
Gold
↓
Business Metrics
↓
Dashboard / Report

In this project we will only focus on dbt+SQL+report for the BI

---

# 13. Important Constraints

Do not over-engineer the project.

Do not create unnecessary tables.

Do not introduce technologies just because they look impressive.

Every model must have a reason to exist.

Every transformation should solve a business or data-quality problem.

Every Gold model should have a clear business purpose.

Every technical decision should be explainable in simple language.

The final project should be realistic enough for a portfolio and YouTube series, but small enough that I can understand the entire system end to end.

Start by giving me:

1. The BookNest business story
2. Business requirements
3. Source datasets
4. Proposed Bronze/Silver/Gold architecture
5. Proposed final business outputs
6. Data model/ERD
7. dbt project structure
8. Technology stack
9. A episode roadmap
10. A recommended implementation order

Do NOT generate all the code yet.

First help me design the **complete BookNest data product**.
