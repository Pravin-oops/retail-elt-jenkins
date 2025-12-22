import csv
import random
import os
from faker import Faker

# Initialize Faker
fake = Faker()

# --- CONFIGURATION ---
NUM_ROWS = 1000
# This path matches the volume map in your docker-compose.yml
#OUTPUT_FILE = '/var/jenkins_home/workspace/shared_data/sales_data.csv'
OUTPUT_FILE = '/opt/shared_data/sales_data.csv'
# Ensure the directory exists (in case Jenkins cleared the workspace)
os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

print(f"Starting data generation: {NUM_ROWS} rows...")

# Define Product Categories for realism
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
    
    # 1. HEADER ROW
    # These columns must match your Oracle External Table definition
    writer.writerow(['TRANS_ID', 'CUST_ID', 'CUST_NAME', 'PROD_ID', 'PROD_NAME', 'CATEGORY', 'PRICE', 'QUANTITY', 'TXN_DATE'])
    
    for i in range(1000, 1000 + NUM_ROWS):
        # --- MESSY DATA LOGIC ---
        
        # 5% Chance of a "Ghost" Category (NULL) -> Tests NVL() function
        cat = random.choice(CATEGORIES) if random.random() > 0.05 else ''
        
        # Select a product based on category (or generic if category is null)
        prod_name = random.choice(PRODUCTS.get(cat, ['Generic Item']))
        
        # 2% Chance of Negative Price (Data Quality Error) -> Tests Data Cleaning
        price = round(random.uniform(5.0, 500.0), 2)
        if random.random() < 0.02:
            price = price * -1 
            
        # 5% Chance of Future Date (Logical Error) -> Tests Date Validation
        if random.random() < 0.05:
            txn_date = fake.future_date()
        else:
            txn_date = fake.date_between(start_date='-1y', end_date='today')

        # --- WRITE ROW ---
        writer.writerow([
            i,                                          # TRANS_ID
            f"C{random.randint(1, 100):03d}",           # CUST_ID (e.g., C042)
            fake.name(),                                # CUST_NAME
            f"P{random.randint(1, 50):03d}",            # PROD_ID (e.g., P005)
            prod_name,                                  # PROD_NAME
            cat,                                        # CATEGORY
            price,                                      # PRICE
            random.randint(1, 10),                      # QUANTITY
            txn_date                                    # TXN_DATE
        ])

print(f"Success! Generated {NUM_ROWS} rows at: {OUTPUT_FILE}")