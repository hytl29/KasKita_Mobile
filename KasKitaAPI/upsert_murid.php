<?php
include 'config.php';$nisn = $_POST['nisn'];
$nama = $_POST['nama'];
$pass = $_POST['password'];
$stat = $_POST['status'];
$role = $_POST['role'];
$isEdit = $_POST['is_edit'];

if ($isEdit == '1') {
    $q = mysqli_query($conn, "UPDATE murid SET nama='$nama', password='$pass', status='$stat', role='$role' WHERE nisn='$nisn'");
} else {
    $q = mysqli_query($conn, "INSERT INTO murid VALUES ('$nisn', '$pass', '$nama', 'XI PPLG 2', '$stat', '$role')");
}

echo json_encode(["status" => $q ? "success" : "error"]);
?>