<?php
ini_set("display_errors", 1);
ini_set("display_startup_errors", 1);
error_reporting(E_ALL);
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// login.php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Database configuration
\System.Management.Automation.Internal.Host.InternalHost = 'localhost';
\ = 'root';
\ = ''; // XAMPP default is empty
\ = 'student_attendance_system'; // Change this to your actual database name

// Create connection
\ = new mysqli(\System.Management.Automation.Internal.Host.InternalHost, \, \, \);

// Check connection
if (\->connect_error) {
    echo json_encode([
        'success' => false, 
        'message' => 'Database connection failed: ' . \->connect_error
    ]);
    exit;
}

// Get POST data
\ = json_decode(file_get_contents('php://input'), true);

// Support both JSON and form-data
if (\['REQUEST_METHOD'] === 'POST') {
    \ = \['email'] ?? \['email'] ?? '';
    \ = \['password'] ?? \['password'] ?? '';
    
    if (empty(\) || empty(\)) {
        echo json_encode([
            'success' => false, 
            'message' => 'Email and password required'
        ]);
        exit;
    }
    
    // Query user
    \ = \->prepare("SELECT user_id, email, password, role, status FROM users WHERE email = ?");
    \->bind_param("s", \);
    \->execute();
    \ = \->get_result();
    
    if (\ = \->fetch_assoc()) {
        // Verify password
        if (password_verify(\, \['password'])) {
            // Check if account is active
            if (\['status'] !== 'active') {
                echo json_encode([
                    'success' => false, 
                    'message' => 'Account is not active'
                ]);
                exit;
            }
            
            // Login successful
            echo json_encode([
                'success' => true,
                'message' => 'Login successful',
                'user' => [
                    'user_id' => \['user_id'],
                    'email' => \['email'],
                    'role' => \['role']
                ]
            ]);
        } else {
            echo json_encode([
                'success' => false, 
                'message' => 'Invalid password'
            ]);
        }
    } else {
        echo json_encode([
            'success' => false, 
            'message' => 'User not found'
        ]);
    }
    
    \->close();
} else {
    echo json_encode([
        'success' => false, 
        'message' => 'Only POST method allowed'
    ]);
}

\->close();
?>
