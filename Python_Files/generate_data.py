# generate_data.py
# Generates realistic e-commerce CSVs: dim_customer, dim_product, dim_order, fact_order_items, dim_session
import os, random
from faker import Faker
import pandas as pd
import numpy as np
from datetime import timedelta
from tqdm import tqdm

# Deterministic seeds
Faker.seed(42)
random.seed(42)
np.random.seed(42)
fake = Faker()

OUT_DIR = "C:\\Videos of Python and HTML\\Project\\EV Project\\PowerBI_Sql\\output_csv"
os.makedirs(OUT_DIR, exist_ok=True)

# Sizes (adjust if needed)
NUM_CUSTOMERS = 10000
NUM_PRODUCTS = 1000
NUM_ORDERS = 25000
NUM_ORDER_ITEMS = 120000
NUM_SESSIONS = 30000
CHUNK_SIZE = 20000  # for streaming fact file

# 1. dim_customer
segments = ["Retail","SMB","Enterprise"]
customers = []
for cid in range(1, NUM_CUSTOMERS+1):
    created = fake.date_time_between(start_date='-5y', end_date='now')
    customers.append({
        "customer_id": cid,
        "first_name": fake.first_name(),
        "last_name": fake.last_name(),
        "email": fake.email(),
        "phone": fake.phone_number(),
        "country": fake.country(),
        "city": fake.city(),
        "postcode": fake.postcode(),
        "created_at": created.isoformat(sep=' '),
        "marketing_opt_in": int(random.random() < 0.4),
        "customer_segment": random.choice(segments),
        "lifetime_value": round(random.uniform(50,20000),2),
        "repeat_customer": int(random.random() < 0.35)
    })
pd.DataFrame(customers).to_csv(f"{OUT_DIR}/dim_customer.csv", index=False)

# 2. dim_product
categories = ["Electronics","Home","Clothing","Sports","Beauty"]
products = []
for pid in range(1, NUM_PRODUCTS+1):
    price = round(random.uniform(5,1000),2)
    cost = round(price * random.uniform(0.4,0.85),2)
    products.append({
        "product_id": pid,
        "sku": f"SKU{100000+pid}",
        "product_name": fake.word().capitalize(),
        "category": random.choice(categories),
        "subcategory": fake.word(),
        "brand": fake.company(),
        "price": price,
        "cost": cost,
        "stock_quantity": random.randint(0,1000),
        "active": int(random.random() < 0.95),
        "created_at": fake.date_time_between(start_date='-6y', end_date='-1y').isoformat(sep=' ')
    })
pd.DataFrame(products).to_csv(f"{OUT_DIR}/dim_product.csv", index=False)

# 3. dim_order
orders = []
for oid in range(1, NUM_ORDERS+1):
    cust = random.randint(1, NUM_CUSTOMERS)
    order_date = fake.date_time_between(start_date='-2y', end_date='now')
    subtotal = round(random.uniform(10,2000),2)
    discount = round(subtotal * random.choice([0,0.05,0.1,0.15]),2)
    tax = round(subtotal * 0.12,2)
    shipping = round(random.uniform(0,50),2)
    total = round(subtotal - discount + tax + shipping,2)
    orders.append({
        "order_id": oid,
        "customer_id": cust,
        "order_date": order_date.isoformat(sep=' '),
        "order_status": random.choice(["Completed","Cancelled","Returned","Pending"]),
        "payment_status": random.choice(["Paid","Pending","Failed","Refunded"]),
        "payment_method": random.choice(["Card","PayPal","BankTransfer","Wallet"]),
        "currency": "USD",
        "subtotal": subtotal,
        "discount_amount": discount,
        "tax_amount": tax,
        "shipping_amount": shipping,
        "total_amount": total,
        "shipping_country": fake.country(),
        "shipping_city": fake.city(),
        "shipping_postcode": fake.postcode(),
        "device_type": random.choice(["Desktop","Mobile","Tablet"]),
        "traffic_source": random.choice(["Organic","Paid","Email","Referral","Direct"])
    })
pd.DataFrame(orders).to_csv(f"{OUT_DIR}/dim_order.csv", index=False)

# 4. fact_order_items (streamed in chunks)
fact_path = f"{OUT_DIR}/fact_order_items.csv"
header_written = False
item_id = 1
for _ in tqdm(range(NUM_ORDER_ITEMS // CHUNK_SIZE + (1 if NUM_ORDER_ITEMS % CHUNK_SIZE else 0)), desc="Writing fact chunks"):
    rows = []
    for _ in range(min(CHUNK_SIZE, NUM_ORDER_ITEMS - (item_id-1))):
        order_id = random.randint(1, NUM_ORDERS)
        product_id = random.randint(1, NUM_PRODUCTS)
        customer_id = orders[order_id-1]["customer_id"]
        qty = random.randint(1,5)
        unit_price = products[product_id-1]["price"]
        line_total = round(qty * unit_price,2)
        rows.append({
            "order_item_id": item_id,
            "order_id": order_id,
            "product_id": product_id,
            "customer_id": customer_id,
            "quantity": qty,
            "unit_price": unit_price,
            "line_total": line_total,
            "order_date": orders[order_id-1]["order_date"],
            "currency": "USD",
            "device_type": orders[order_id-1]["device_type"],
            "traffic_source": orders[order_id-1]["traffic_source"],
            "promo_id": random.choice([None] + list(range(1,51)))
        })
        item_id += 1
    df_chunk = pd.DataFrame(rows)
    df_chunk.to_csv(fact_path, mode='a', index=False, header=not header_written)
    header_written = True

# 5. dim_session
sessions = []
for sid in range(1, NUM_SESSIONS+1):
    cust = random.randint(1, NUM_CUSTOMERS)
    start = fake.date_time_between(start_date='-2y', end_date='now')
    duration = random.randint(10,7200)
    end = (pd.to_datetime(start) + pd.Timedelta(seconds=duration)).isoformat(sep=' ')
    sessions.append({
        "session_id": sid,
        "customer_id": cust,
        "session_start": start.isoformat(sep=' '),
        "session_end": end,
        "device_type": random.choice(["Desktop","Mobile","Tablet"]),
        "traffic_source": random.choice(["Organic","Paid","Email","Referral","Direct"]),
        "landing_page": fake.uri_path(),
        "page_views": random.randint(1,25),
        "bounce": int(random.random() < 0.25),
        "converted": int(random.random() < 0.08),
        "duration_seconds": duration
    })
pd.DataFrame(sessions).to_csv(f"{OUT_DIR}/dim_session.csv", index=False)

print("CSV generation complete. Files in:", OUT_DIR)
