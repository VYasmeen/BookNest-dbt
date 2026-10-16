"""Export Gold marts from DuckDB to CSV for upload into ThoughtSpot Analyst Studio."""

from pathlib import Path
import duckdb

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "booknest.duckdb"
EXPORTS = ROOT / "exports"
MARTS = ["sales_daily", "customer_lifetime", "book_performance", "low_stock_alert"]

EXPORTS.mkdir(exist_ok=True)
con = duckdb.connect(str(DB_PATH), read_only=True)
for mart in MARTS:
    out = EXPORTS / f"{mart}.csv"
    con.sql(f"COPY (SELECT * FROM main_gold.{mart}) TO '{out}' (HEADER, DELIMITER ',')")
    print(f"wrote {out}")
