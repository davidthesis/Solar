import mysql.connector
import matplotlib.pyplot as plt
import numpy as np


mydb = mysql.connector.connect(
host='localhost', database='solar', user='solar', password='solar56%pass'
)

mycursor = mydb.cursor()

mycursor.execute("SELECT Day,Month,Year,Hour,Minute,Second FROM solardata")

myresult = mycursor.fetchall()
old = 0
print(type(myresult))
for x in myresult:
  z = int(x[0])
  if (old != z):
    print("************")
    print(x)
    print(old)
    old = z
