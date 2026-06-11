<?php
$conn = new mysqli('localhost', 'root', '', 'student_attendance_system');

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$result = $conn->query("SHOW TABLES");
echo "Tables in database:\n";
while($row = $result->fetch_array()) {
    echo "- " . $row[0] . "\n";
}

$result = $conn->query("SELECT email, LEFT(password, 20) as pwd, role, status FROM users LIMIT 5");
echo "\nUsers:\n";
while($row = $result->fetch_assoc()) {
    echo "Email: " . $row['email'] . " | Role: " . $row['role'] . " | Status: " . $row['status'] . " | Hash: " . $row['pwd'] . "...\n";
}
?>