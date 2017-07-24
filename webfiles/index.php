<script
  src="https://code.jquery.com/jquery-3.2.1.js"
  integrity="sha256-DZAnKJ/6XZ9si04Hgrsxu/8s717jcIzLy3oi35EouyE="
  crossorigin="anonymous"></script>
<link rel="stylesheet" type="text/css" href="//cdn.datatables.net/1.10.15/css/jquery.dataTables.css">
<script type="text/javascript" charset="utf8" src="//cdn.datatables.net/1.10.15/js/jquery.dataTables.js"></script>



<html>
<body>
<table id="ntable" class="display">
	<thead>
		<tr>
			<th></th>
			<th>Severity</th>
			<th>Source</th>
			<th>Timestamp</th>
			<th>IP</th>
			<th>Content</th>
		</tr>
	</thead>
	<tbody>
		
<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "NotificationDB";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);
// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
} 

$sql = "SELECT Source,Severity,Content,Timestamp,SourceIP FROM NotificationDB.notifications";
$result = $conn->query($sql);


if ($result->num_rows > 0) {
    // output data of each row
    while($row = $result->fetch_assoc()) {
		
		switch ($row["Severity"]) {
			case "Info":
				$imagepath = "info.png";
				break;
			case "Warning":
				$imagepath = "warning.png";
				break;
			case "Error":
				$imagepath = "error.png";
				break;
			case "Critical":
				$imagepath = "critical.png";
				break;
			default:
				$imagepath = "info.png";
		}
		
		echo "<tr>";
        echo "<td><img src=". $imagepath." style=width:30px;height:30px;></td>";
		echo "<td>". $row["Severity"]. "</td>";
		echo "<td>". $row["Source"]. "</td>";
		echo "<td>". $row["Timestamp"]. "</td>";
		echo "<td>". $row["SourceIP"]. "</td>";
		echo "<td>". $row["Content"]. "</td>";
		echo "</tr>";
    }
} else {
    echo "0 results";
}

$conn->close();
?> 
</tbody>
</table>
<script type="text/javascript">
            $(document).ready(function()
            {
                $('#ntable').DataTable({
					"order": [[ 3, "desc" ]],
					"pageLength": 50
			});
            });
</script>
</body>
</html>





