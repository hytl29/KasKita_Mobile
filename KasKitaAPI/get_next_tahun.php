<?php
include 'config.php';
$nisn = $_POST['nisn'] ?? '';if (!$nisn) {
    echo json_encode(['next_tahun' => 2025]);
    exit;
}

// Cari tahun pertama yang belum lunas (kurang dari 48 minggu)
$q = mysqli_query($conn, "
    SELECT tahun, COUNT(DISTINCT CONCAT(bulan, '-', minggu)) AS total_minggu
    FROM transaksi
    WHERE nisn = '$nisn' AND jenis = 'Masuk'
    GROUP BY tahun
    ORDER BY tahun ASC
");

while ($row = mysqli_fetch_assoc($q)) {
    if ((int) $row['total_minggu'] < 48) {
        echo json_encode(['next_tahun' => (int) $row['tahun']]);
        exit;
    }
}

// Jika belum pernah bayar sama sekali
$qTerakhir = mysqli_query($conn, "SELECT MAX(tahun) AS tahun_terakhir FROM transaksi WHERE nisn = '$nisn' AND jenis = 'Masuk'");
$rowTerakhir = mysqli_fetch_assoc($qTerakhir);

if ($rowTerakhir['tahun_terakhir']) {
    echo json_encode(['next_tahun' => (int) $rowTerakhir['tahun_terakhir'] + 1]);
} else {
    echo json_encode(['next_tahun' => 2025]);
}
?>