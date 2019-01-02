import mysql.connector, csv
from mysql.connector import Error
try:
    connection = mysql.connector.connect(host='localhost',
                             database='solar',
                             user='solar',
                             password='solar56%pass')
    if connection.is_connected():
       db_Info = connection.get_server_info()
       print("Connected to MySQL database... MySQL Server version on ",db_Info)
       cursor = connection.cursor()
       cursor.execute("select database();")
       record = cursor.fetchone()
       print ("Your connected to - ", record)
       cursor.execute("SHOW TABLES")
       for (table_name,) in cursor:
        print(table_name)


mycursor = connector.cursor()

mycursor.execute("SELECT * FROM customers")

myresult = mycursor.fetchall()

for x in myresult:
  print(x)


cursor.execute("SELECT * FROM solardata;")
for row in cursor:
  print(row)




except Error as e :
    print ("Error while connecting to MySQL", e)
finally:
    #closing database connection.
    if(connection.is_connected()):
        cursor.close()
        connection.close()
        print("MySQL connection is closed")
