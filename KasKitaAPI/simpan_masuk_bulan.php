<?php
include 'config.php';
$nisn = $_POST['nisn'];
$tahun = $_POST['tahun'];
$bulanDipilih = json_decode($_POST['bulan_dipilih']);

foreach($bulanDipilih as $b) {
    // Ambil minggu yang sudah dibayar
    $q = mysqli_query($conn, "SELECT minggu FROM transaksi WHERE nisn='$nisn' AND tahun='$tahun' AND bulan='$b' AND jenis='Masuk'");
    $sudah = [];
    while($r = mysqli_fetch_assoc($q)) { $sudah[] = (int)$r['minggu']; }

    // Simpan hanya minggu yang belum ada
    for($m=1; $m<=4; $m++) {
        if(!in_array($m, $sudah)) {
            mysqli_query($conn, "INSERT INTO transaksi (nisn, tanggal, tahun, bulan, minggu, jenis, jumlah, keterangan) 
            VALUES ('$nisn', NOW(), '$tahun', '$b', '$m', 'Masuk', 5000, 'Bayar Bulanan')");
        }
    }
}
echo json_encode(["status" => "success"]);
?>