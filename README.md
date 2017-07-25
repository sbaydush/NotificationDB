# NotificationDB
Notification Database


This lets you setup a database that can be queried and written to using Curl commands and also view it as a sortable and searchable table. It uses MariaDB as a database backend and php to execute the queries to the database. This is being created as a way for me to keep track of my homeserver notifications for historical purposes and possibly so I can graph data in the future if need be.

EXAMPLES: (example server is using 192.168.1.100 as its IP)
Curl command to add row to database:

  curl http://192.168.1.100/api.php -X POST -d '{"Source":"Server1","Severity":"Error","Content": "'"This is an example error message"'."}'

View database via webpage:
  http://192.168.1.100/
