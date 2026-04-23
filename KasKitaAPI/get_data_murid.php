<?php
include 'config.php';
header('Content-Type: application/json');

$q = mysqli_query($conn, "SELECT * FROM murid ORDER BY nama ASC");
$murid = [];
$aktif = 0; $non = 0;

while($r = mysqli_fetch_assoc($q)) {
    $murid[] = $r;
    ($r['status'] == 'Aktif') ? $aktif++ : $non++;
}

echo json_encode([
    "summary" => ["total" => count($murid), "aktif" => $aktif, "non_aktif" => $non],
    "murid" => $murid
]);
?>