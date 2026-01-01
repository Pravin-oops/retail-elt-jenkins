import csv
import random
import os
from datetime import datetime
from faker import Faker

# --- CONFIGURATION (V1.1 Update) ---

# 1. Default to the Unified Docker Path (for Jenkins/Oracle)
DATA_DIR = '/data'

# 2. Fallback for Local Testing (Windows/Mac)
# If '/data' doesn't exist (which is true on your laptop), 
# use the project's local 'data' folder.
# Get the folder where THIS script is located (.../retail-etl-project/script/)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    
# Go up one level to the project root, then into 'data'
# Result: .../retail-etl-project/data/
DATA_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), 'data')

# Define the output file
OUTPUT_FILE = os.path.join(DATA_DIR, 'sales_data.csv')

# Ensure the directory exists
os.makedirs(DATA_DIR, exist_ok=True)

# Initialize Faker
fake = Faker()
NUM_ROWS = 1000

print(f"--- Starting Data Generation (V1.1) ---")
print(f"Target Path: {OUTPUT_FILE}")  # <--- CHECK THIS LINE IN YOUR OUTPUT

# Define Product Categories
CATEGORIES = ['Electronics', 'Home', 'Office', 'Books', 'Garden']
PRODUCTS = {
    'Electronics': ['Wireless Mouse', 'Gaming Monitor', 'USB-C Cable', 'Mechanical Keyboard'],
    'Home': ['Blender', 'Desk Lamp', 'Throw Pillow', 'Picture Frame'],
    'Office': ['Stapler', 'Whiteboard', 'Ballpoint Pens', 'File Organizer'],
    'Books': ['Python 101', 'History of Rome', 'Cooking for Beginners', 'Sci-Fi Novel'],
    'Garden': ['Shovel', 'Plant Pot', 'Garden Hose', 'Rake']
}

with open(OUTPUT_FILE, 'w', newline='') as f:
    writer = csv.writer(f)
    
    # HEADER
    writer.writerow(['TRANS_ID', 'CUST_ID', 'CUST_NAME', 'PROD_ID', 'PROD_NAME', 'CATEGORY', 'PRICE', 'QUANTITY', 'TXN_DATE'])
    
    for i in range(1000, 1000 + NUM_ROWS):
        # 5% Chance of NULL Category
        cat = random.choice(CATEGORIES) if random.random() > 0.05 else ''
        prod_name = random.choice(PRODUCTS.get(cat, ['Generic Item']))
        
        # 2% Chance of Negative Price
        price = round(random.uniform(5.0, 500.0), 2)
        if random.random() < 0.02:
            price = price * -1 
            
        # 5% Chance of Future Date
        if random.random() < 0.05:
            txn_date = fake.future_date()
        else:
            txn_date = fake.date_between(start_date='-1y', end_date='today')

        writer.writerow([
            i,
            f"C{random.randint(1, 100):03d}",
            fake.name(),
            f"P{random.randint(1, 50):03d}",
            prod_name,
            cat,
            price,
            random.randint(1, 10),
            txn_date
        ])

print(f"✅ Success! Generated {NUM_ROWS} rows.")