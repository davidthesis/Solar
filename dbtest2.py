import mysql.connector

mydb = mysql.connector.connect(
host='localhost', database='solar', user='solar', password='solar56%pass'
)

mycursor = mydb.cursor()

mycursor.execute("SELECT Pdc1 FROM solardata")

myresult = mycursor.fetchall()

for x in myresult:
  print(x)
