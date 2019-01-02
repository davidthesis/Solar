import mysql.connector
import matplotlib.pyplot as plt
import numpy as np



mydb = mysql.connector.connect(
host='localhost', database='solar', user='solar', password='solar56%pass'
)

mycursor = mydb.cursor()

mycursor.execute("SELECT Day,Month,Year,Hour,Minute,Second FROM solardata")

myresult = mycursor.fetchall()

for x in myresult:
  print(x[0])

plt.plot(myresult)
plt.xlabel('time ')
plt.ylabel('Power (W)')
plt.title('All data')
plt.grid(True)
plt.savefig("test.png")
plt.show()
