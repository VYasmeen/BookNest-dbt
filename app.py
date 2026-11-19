import streamlit as st
import duckdb
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime

st.set_page_config(
    page_title="BookNest Analytics",
    page_icon="📊",
    layout="wide"
)

conn = duckdb.connect('./booknest.duckdb', read_only=True)

st.title("📚 BookNest Analytics Dashboard")
st.markdown("---")

tab1, tab2, tab3, tab4 = st.tabs(["🧾 Accounting", "📈 Sales", "👥 Customers", "📦 Inventory"])

# ==================== ACCOUNTING TAB ====================
with tab1:
    st.header("Finance & Reconciliation")

    col1, col2, col3 = st.columns(3)

    # Key metrics
    reconciliation = conn.execute("""
        SELECT
            COUNT(*) as total_orders,
            SUM(CASE WHEN needs_investigation THEN 1 ELSE 0 END) as orders_flagged,
            SUM(order_mismatch) as total_mismatch
        FROM main_gold.accounting_reconciliation
    """).fetchall()[0]

    with col1:
        st.metric("Total Orders", reconciliation[0])
    with col2:
        st.metric("Orders Flagged", reconciliation[1], delta=f"{round(reconciliation[1]/reconciliation[0]*100, 1)}%")
    with col3:
        st.metric("Total Mismatch ($)", f"${reconciliation[2]:,.2f}")

    st.markdown("---")

    # Revenue by Payment Method
    st.subheader("Revenue by Payment Method")
    revenue_data = conn.execute("""
        SELECT
            payment_method,
            payment_status_clean,
            SUM(total_payment_amount) as amount,
            COUNT(*) as order_count,
            AVG(avg_days_to_payment) as avg_days
        FROM main_gold.revenue_by_payment_method
        GROUP BY payment_method, payment_status_clean
        ORDER BY amount DESC
    """).fetch_df()

    if not revenue_data.empty:
        fig = px.bar(
            revenue_data,
            x="payment_method",
            y="amount",
            color="payment_status_clean",
            title="Payment Revenue by Method & Status",
            labels={"amount": "Revenue ($)", "payment_method": "Payment Method"}
        )
        st.plotly_chart(fig, use_container_width=True)

    # Reconciliation Issues
    st.subheader("Orders Needing Investigation")
    issues = conn.execute("""
        SELECT
            order_id,
            order_date,
            order_status,
            stated_order_total,
            payment_amount,
            order_mismatch,
            needs_investigation
        FROM main_gold.accounting_reconciliation
        WHERE needs_investigation = true
        ORDER BY order_date DESC
        LIMIT 20
    """).fetch_df()

    if not issues.empty:
        st.dataframe(issues, use_container_width=True)
    else:
        st.info("✅ No reconciliation issues found!")

    # Payment Status Overview
    st.subheader("Payment Status Distribution")
    payment_status = conn.execute("""
        SELECT
            payment_status_clean,
            COUNT(*) as count,
            SUM(total_payment_amount) as total_amount
        FROM main_gold.revenue_by_payment_method
        GROUP BY payment_status_clean
    """).fetch_df()

    if not payment_status.empty:
        col1, col2 = st.columns(2)
        with col1:
            fig = px.pie(payment_status, values="count", names="payment_status_clean", title="Orders by Payment Status")
            st.plotly_chart(fig, use_container_width=True)
        with col2:
            fig = px.pie(payment_status, values="total_amount", names="payment_status_clean", title="Revenue by Payment Status")
            st.plotly_chart(fig, use_container_width=True)

# ==================== SALES TAB ====================
with tab2:
    st.header("Sales Performance")

    # Daily Sales
    daily_sales = conn.execute("""
        SELECT
            sale_date,
            SUM(revenue) as revenue,
            SUM(units_sold) as units,
            SUM(orders) as orders
        FROM main_gold.sales_daily
        GROUP BY sale_date
        ORDER BY sale_date DESC
    """).fetch_df()

    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Total Revenue", f"${daily_sales['revenue'].sum():,.2f}")
    with col2:
        st.metric("Total Units Sold", f"{daily_sales['units'].sum():,.0f}")
    with col3:
        st.metric("Total Orders", f"{daily_sales['orders'].sum():,.0f}")

    st.markdown("---")

    # Revenue Trend
    st.subheader("Daily Revenue Trend")
    fig = px.line(
        daily_sales,
        x="sale_date",
        y="revenue",
        title="Revenue Over Time",
        labels={"sale_date": "Date", "revenue": "Revenue ($)"}
    )
    st.plotly_chart(fig, use_container_width=True)

    # Sales by Genre
    st.subheader("Sales by Genre")
    genre_sales = conn.execute("""
        SELECT
            genre,
            SUM(revenue) as revenue,
            SUM(units_sold) as units,
            SUM(orders) as orders
        FROM main_gold.sales_daily
        GROUP BY genre
        ORDER BY revenue DESC
    """).fetch_df()

    if not genre_sales.empty:
        col1, col2 = st.columns(2)
        with col1:
            fig = px.bar(genre_sales, x="genre", y="revenue", title="Revenue by Genre")
            st.plotly_chart(fig, use_container_width=True)
        with col2:
            fig = px.bar(genre_sales, x="genre", y="units", title="Units Sold by Genre")
            st.plotly_chart(fig, use_container_width=True)

# ==================== CUSTOMERS TAB ====================
with tab3:
    st.header("Customer Analytics")

    # Customer Segments
    st.subheader("Customer Segmentation (RFM)")
    segments = conn.execute("""
        SELECT
            customer_segment,
            COUNT(*) as customer_count,
            AVG(lifetime_value) as avg_ltv,
            SUM(lifetime_value) as total_ltv
        FROM main_gold.customer_rfm
        WHERE customer_segment != 'never_purchased'
        GROUP BY customer_segment
        ORDER BY total_ltv DESC
    """).fetch_df()

    if not segments.empty:
        col1, col2 = st.columns(2)
        with col1:
            fig = px.bar(segments, x="customer_segment", y="customer_count", title="Customers by Segment")
            st.plotly_chart(fig, use_container_width=True)
        with col2:
            fig = px.bar(segments, x="customer_segment", y="avg_ltv", title="Avg LTV by Segment")
            st.plotly_chart(fig, use_container_width=True)

    st.markdown("---")

    # Customer Lifetime Value
    st.subheader("Customer Lifetime Value Distribution")
    ltv_dist = conn.execute("""
        SELECT
            lifetime_value,
            customer_id,
            full_name,
            order_count
        FROM main_gold.customer_lifetime
        ORDER BY lifetime_value DESC
        LIMIT 20
    """).fetch_df()

    if not ltv_dist.empty:
        fig = px.histogram(ltv_dist, x="lifetime_value", nbins=30, title="LTV Distribution")
        st.plotly_chart(fig, use_container_width=True)

        st.subheader("Top Customers by LTV")
        st.dataframe(ltv_dist, use_container_width=True)

# ==================== INVENTORY TAB ====================
with tab4:
    st.header("Inventory & Product Performance")

    # Stock Alert
    st.subheader("Low Stock Alert")
    low_stock = conn.execute("""
        SELECT
            COUNT(*) as total_books,
            SUM(CASE WHEN stock_status = 'out_of_stock' THEN 1 ELSE 0 END) as out_of_stock,
            SUM(CASE WHEN stock_status = 'critical' THEN 1 ELSE 0 END) as critical,
            SUM(CASE WHEN stock_status = 'low' THEN 1 ELSE 0 END) as low
        FROM main_gold.low_stock_alert
    """).fetchall()[0]

    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Books", low_stock[0])
    with col2:
        st.metric("Out of Stock", low_stock[1])
    with col3:
        st.metric("Critical", low_stock[2])
    with col4:
        st.metric("Low Stock", low_stock[3])

    st.markdown("---")

    # Books at risk
    st.subheader("Books Requiring Attention")
    at_risk = conn.execute("""
        SELECT
            book_id,
            title,
            stock_status,
            stock_quantity
        FROM main_gold.low_stock_alert
        WHERE stock_status IN ('out_of_stock', 'critical', 'low')
        ORDER BY stock_quantity ASC
        LIMIT 15
    """).fetch_df()

    if not at_risk.empty:
        st.dataframe(at_risk, use_container_width=True)
    else:
        st.info("✅ All inventory levels healthy!")

    # Book Performance
    st.subheader("Top Performers")
    top_books = conn.execute("""
        SELECT
            book_id,
            title,
            units_sold,
            revenue,
            current_stock
        FROM main_gold.book_performance
        ORDER BY revenue DESC
        LIMIT 10
    """).fetch_df()

    if not top_books.empty:
        fig = px.bar(top_books, x="title", y="revenue", title="Top 10 Books by Revenue")
        st.plotly_chart(fig, use_container_width=True)

st.markdown("---")
st.caption(f"Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
