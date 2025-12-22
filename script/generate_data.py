import csv
import random
from faker import Faker # You might need to pip install faker

fake = Faker()
num_rows = 50000 # Change this to generate more data

categories = ['Electronics', 'Home', 'Clothing', 'Office', 'Books']
products = {
    'Electronics': ['Mouse', 'Keyboard', 'Monitor', 'Headset'],
    'Home': ['Lamp', 'Rug', 'Chair', 'Table'],
    'Clothing': ['Shirt', 'Pants', 'Jacket', 'Hat'],
    'Office': ['Pen', 'Notebook', 'Stapler', 'Binder'],
    'Books': ['Novel', 'Textbook', 'Comic', 'Biography']
}

with open('data/sales_large.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['TRANS_ID', 'CUST_NAME', 'CUST_EMAIL', 'PROD_NAME', 'CATEGORY', 'PRICE', 'QTY', 'TXN_DATE'])
    
    for i in range(1, num_rows + 1):
        cat = random.choice(categories) if random.random() > 0.05 else '' # 5% chance of missing category
        prod = random.choice(products.get(cat, ['Generic Item']))
        
        writer.writerow([
            i,
            fake.name(),
            fake.email() if random.random() > 0.02 else 'invalid_email', # 2% bad emails
            prod,
            cat,
            round(random.uniform(10.0, 500.0), 2),
            random.randint(1, 20),
            fake.date_between(start_date='-1y', end_date='today')
        ])

print(f"Generated {num_rows} rows in data/sales_large.csv")