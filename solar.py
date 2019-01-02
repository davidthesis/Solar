# Load the Pandas libraries with alias 'pd'
import pandas as pd
import pymysql
import sys
# Read data from file 'filename.csv'
# (in the same directory that your python process is based)
# Control delimiters, rows, column names with read_csv (see later)
data = pd.read_csv("all_split2.csv")
# Preview the first 5 lines of the loaded data
data.head()
print(data["Month"])
M_list = data["Month"]
print(M_list)
print(data[:1,4])
