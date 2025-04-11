#!/usr/bin/env python3

import sqlite3
import os
from prettytable import PrettyTable

# Path to your SQLite database
DB_FILE = "/home/ubuntu/microblog/app.db"

# Connect to the database
conn = sqlite3.connect(DB_FILE)
cursor = conn.cursor()

# Get all tables
cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
tables = cursor.fetchall()

# Create output file
with open('database_tables.txt', 'w') as f:
    f.write(f"Database Tables Summary for {DB_FILE}\n")
    f.write("=" * 80 + "\n\n")
    
    # Generate table summary
    summary_table = PrettyTable()
    summary_table.field_names = ["Table Name", "Columns", "Rows", "Indexes"]
    
    for table in tables:
        table_name = table[0]
        
        # Get column count
        cursor.execute(f"PRAGMA table_info({table_name});")
        columns = cursor.fetchall()
        column_count = len(columns)
        
        # Get row count
        cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
        row_count = cursor.fetchone()[0]
        
        # Get indexes
        cursor.execute(f"PRAGMA index_list({table_name});")
        indexes = cursor.fetchall()
        index_count = len(indexes)
        
        summary_table.add_row([table_name, column_count, row_count, index_count])
    
    f.write(summary_table.get_string() + "\n\n")
    
    # Generate detailed information for each table
    for table in tables:
        table_name = table[0]
        f.write(f"Table: {table_name}\n")
        f.write("-" * 80 + "\n\n")
        
        # Get schema
        cursor.execute(f"PRAGMA table_info({table_name});")
        columns = cursor.fetchall()
        
        column_table = PrettyTable()
        column_table.field_names = ["ID", "Name", "Type", "NotNull", "Default", "PK"]
        
        for col in columns:
            column_table.add_row([col[0], col[1], col[2], col[3], col[4] or "NULL", col[5]])
        
        f.write(column_table.get_string() + "\n\n")
        
        # Get indexes
        cursor.execute(f"PRAGMA index_list({table_name});")
        indexes = cursor.fetchall()
        
        if indexes:
            f.write("Indexes:\n")
            index_table = PrettyTable()
            index_table.field_names = ["Name", "Unique", "Columns"]
            
            for idx in indexes:
                # Get columns in this index
                cursor.execute(f"PRAGMA index_info({idx[1]});")
                index_columns = cursor.fetchall()
                columns_str = ", ".join([str(ic[2]) for ic in index_columns])
                
                index_table.add_row([idx[1], "Yes" if idx[2] else "No", columns_str])
            
            f.write(index_table.get_string() + "\n\n")
        
        # Get sample data
        try:
            cursor.execute(f"SELECT * FROM {table_name} LIMIT 5;")
            rows = cursor.fetchall()
            
            if rows:
                f.write("Sample Data (up to 5 rows):\n")
                
                # Get column names
                column_names = [description[0] for description in cursor.description]
                
                data_table = PrettyTable()
                data_table.field_names = column_names
                
                for row in rows:
                    # Truncate long values for display
                    display_row = []
                    for val in row:
                        if isinstance(val, str) and len(val) > 50:
                            display_row.append(val[:47] + "...")
                        else:
                            display_row.append(val)
                    data_table.add_row(display_row)
                
                f.write(data_table.get_string() + "\n\n")
        except:
            # Some tables might not support direct SELECT
            f.write("Cannot retrieve sample data for this table.\n\n")
        
        f.write("\n")

print(f"Database tables exported to database_tables.txt")

# Close the connection
conn.close()