#!/usr/bin/env python3
"""
Day 2: Create e-commerce schema + sample data on Neon.

Run from project root:
    ./venv/bin/python scripts/create_sample_db.py

Re-running drops and recreates tables (safe for our lab DB).
"""

import os
import random
from datetime import UTC, datetime, timedelta

import psycopg
from dotenv import load_dotenv
from faker import Faker

# --- Config: how much data we want -----------------------------------------
COUNTS = {
    "customers": 10_000,
    "products": 1_000,
    "orders": 50_000,
    "order_items": 100_000,  # 2 line items per order on average
}

# --- Schema: parent tables before children (foreign keys) --------------------
DROP_SQL = """
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
"""

CREATE_SQL = """
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2),
    stock_quantity INTEGER,
    category VARCHAR(100)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date TIMESTAMP NOT NULL,
    total_amount DECIMAL(10, 2),
    status VARCHAR(50)
);

CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id),
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);
"""


def seed_customers(cur, fake: Faker, count: int) -> None:
    """Insert customers via COPY (fast). SERIAL assigns customer_id 1..count."""
    print(f"  Seeding {count:,} customers...")
    rows = [(fake.unique.email(), fake.name()) for _ in range(count)]
    with cur.copy("COPY customers (email, name) FROM STDIN") as copy:
        for row in rows:
            copy.write_row(row)


def seed_products(cur, fake: Faker, count: int) -> None:
    print(f"  Seeding {count:,} products...")
    categories = ["Electronics", "Books", "Clothing", "Home", "Sports", "Toys"]
    rows = [
        (
            fake.catch_phrase()[:200],
            round(random.uniform(5, 500), 2),
            random.randint(0, 500),
            random.choice(categories),
        )
        for _ in range(count)
    ]
    with cur.copy(
        "COPY products (name, price, stock_quantity, category) FROM STDIN"
    ) as copy:
        for row in rows:
            copy.write_row(row)


def seed_orders(cur, count: int) -> None:
    """Each order belongs to a random existing customer (ids 1..10000)."""
    print(f"  Seeding {count:,} orders...")
    statuses = ["pending", "paid", "shipped", "delivered", "cancelled"]
    now = datetime.now(UTC)
    rows = []
    for _ in range(count):
        customer_id = random.randint(1, COUNTS["customers"])
        order_date = now - timedelta(days=random.randint(0, 365))
        total_amount = round(random.uniform(10, 2000), 2)
        status = random.choice(statuses)
        rows.append((customer_id, order_date, total_amount, status))

    with cur.copy(
        "COPY orders (customer_id, order_date, total_amount, status) FROM STDIN"
    ) as copy:
        for row in rows:
            copy.write_row(row)


def seed_order_items(cur, count: int) -> None:
    """
    Exactly 2 items per order → 50_000 orders × 2 = 100_000 line items.
    order_id and product_id must reference existing rows.
    """
    print(f"  Seeding {count:,} order items (2 per order)...")
    items_per_order = count // COUNTS["orders"]
    rows = []
    for order_id in range(1, COUNTS["orders"] + 1):
        for _ in range(items_per_order):
            product_id = random.randint(1, COUNTS["products"])
            quantity = random.randint(1, 5)
            price = round(random.uniform(5, 200), 2)
            rows.append((order_id, product_id, quantity, price))

    with cur.copy(
        "COPY order_items (order_id, product_id, quantity, price) FROM STDIN"
    ) as copy:
        for row in rows:
            copy.write_row(row)


def print_row_counts(cur) -> None:
    print("\nRow counts:")
    for table in ("customers", "products", "orders", "order_items"):
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        (n,) = cur.fetchone()
        print(f"  {table}: {n:,}")


def main() -> None:
    load_dotenv()
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        raise SystemExit("DATABASE_URL not set. Copy .env.example to .env")

    fake = Faker()
    Faker.seed(42)
    random.seed(42)

    print("Connecting to Neon...")
    with psycopg.connect(database_url) as conn:
        with conn.cursor() as cur:
            print("Dropping old tables (if any)...")
            cur.execute(DROP_SQL)

            print("Creating schema...")
            cur.execute(CREATE_SQL)

            print("Inserting data...")
            seed_customers(cur, fake, COUNTS["customers"])
            conn.commit()
            print("    ✓ customers committed")

            seed_products(cur, fake, COUNTS["products"])
            conn.commit()
            print("    ✓ products committed")

            seed_orders(cur, COUNTS["orders"])
            conn.commit()
            print("    ✓ orders committed")

            seed_order_items(cur, COUNTS["order_items"])
            conn.commit()
            print("    ✓ order_items committed")

            print_row_counts(cur)

    print("\nDone. Try in psql:")
    print('  psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM orders;"')


if __name__ == "__main__":
    main()
