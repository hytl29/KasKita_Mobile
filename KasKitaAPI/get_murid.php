<?php
include 'config.php';
$q = mysqli_query($conn, "SELECT nisn, nama FROM murid WHERE status='Aktif' ORDER BY nama ASC");
$res = [];
while($r = mysqli_fetch_assoc($q)) { $res[] = $r; }
echo json_encode($res);
?>