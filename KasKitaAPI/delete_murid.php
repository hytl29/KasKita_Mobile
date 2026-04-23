<?php
include 'config.php';
$nisn = $_POST['nisn'];
$q = mysqli_query($conn, "DELETE FROM murid WHERE nisn='$nisn'");
echo json_encode(["status" => $q ? "success" : "error"]);
?>