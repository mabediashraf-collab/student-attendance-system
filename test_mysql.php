<?php
$conn = mysqli_connect("localhost", "root", "");
if ($conn) {
    echo "MySQL is running!";
} else {
    echo "MySQL error: " . mysqli_connect_error();
}
?>