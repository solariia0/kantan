<?php
$dsn = "pgsql:host=localhost;port=5432;dbname=mydb;";
$user = "myuser";
$password = "mypassword";

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $pdo->prepare("SELECT * FROM users WHERE id = :id");
    $stmt->execute(['id' => 1]);

    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    print_r($user);

} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
}

function getFirstRadical(PDO $pdo) {
    $stmt = $pdo->query("SELECT * FROM usr_radicals LIMIT 1");
    return $stmt->fetch(PDO::FETCH_ASSOC);
}


