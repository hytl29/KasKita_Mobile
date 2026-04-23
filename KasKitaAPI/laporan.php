<?php
include 'config.php';
header('Content-Type: application/json');

$periode = $_POST['periode'] ?? '6';
$tampilan = $_POST['tampilan'] ?? 'ringkasan';
$tanggalMulai = date('Y-m-d', strtotime("-{$periode} months"));

// 1. Summary Global
$qSum = mysqli_query($conn, "SELECT 
    SUM(CASE WHEN jenis='Masuk' THEN jumlah ELSE 0 END) as in_total,
    SUM(CASE WHEN jenis='Keluar' THEN jumlah ELSE 0 END) as out_total FROM transaksi");
$s = mysqli_fetch_assoc($qSum);
$in = (int) $s['in_total'];
$out = (int) $s['out_total'];

// 2. Persentase Pemasukan Per Bulan (Ringkasan)
$qMurid = mysqli_query($conn, "SELECT COUNT(*) as total FROM murid");
$totalMurid = (int) mysqli_fetch_assoc($qMurid)['total'];

$qMasukKat = mysqli_query($conn, "SELECT bulan as kategori, SUM(jumlah) as total_uang, COUNT(DISTINCT nisn) as jumlah_murid_bayar FROM transaksi WHERE jenis='Masuk' AND tanggal >= '$tanggalMulai' GROUP BY bulan, tahun ORDER BY MIN(tanggal) ASC");
$dataMasukKat = [];
while ($r = mysqli_fetch_assoc($qMasukKat))
    $dataMasukKat[] = $r;

// 3. Pengeluaran Per Kategori (Ringkasan)
$qKeluarKat = mysqli_query($conn, "SELECT keterangan as kategori, SUM(jumlah) as total FROM transaksi WHERE jenis='Keluar' AND tanggal >= '$tanggalMulai' GROUP BY keterangan");
$dataKeluarKat = [];
while ($r = mysqli_fetch_assoc($qKeluarKat))
    $dataKeluarKat[] = $r;

// 4. Detail Bulanan (Ringkasan)
$qDetail = mysqli_query($conn, "SELECT DATE_FORMAT(tanggal, '%b %Y') as label, SUM(CASE WHEN jenis='Masuk' THEN jumlah ELSE 0 END) as masuk, SUM(CASE WHEN jenis='Keluar' THEN jumlah ELSE 0 END) as keluar FROM transaksi WHERE tanggal >= '$tanggalMulai' GROUP BY DATE_FORMAT(tanggal, '%Y-%m') ORDER BY tanggal ASC");
$dataDetail = [];
while ($r = mysqli_fetch_assoc($qDetail))
    $dataDetail[] = $r;

// 5. Detail Pemasukan (Detail)
$detailIn = [];
$qIn = mysqli_query($conn, "
    SELECT 
        m.nama, 
        t.bulan, 
        t.tahun, 
        SUM(t.jumlah) as total, 
        GROUP_CONCAT(DISTINCT t.minggu ORDER BY t.minggu ASC SEPARATOR ', ') as minggu_list, 
        t.tanggal 
    FROM transaksi t 
    JOIN murid m ON t.nisn=m.nisn 
    WHERE t.jenis='Masuk' AND t.tanggal >= '$tanggalMulai' 
    GROUP BY t.nisn, t.tanggal, t.bulan, t.tahun 
    ORDER BY t.tanggal DESC
");
while ($r = mysqli_fetch_assoc($qIn))
    $detailIn[] = $r;

// 6. Detail Pengeluaran (Detail)
$detailOut = [];
$qOut = mysqli_query($conn, "SELECT t.tanggal, t.keterangan, t.jumlah, m.nama FROM transaksi t JOIN murid m ON t.nisn=m.nisn WHERE t.jenis='Keluar' AND t.tanggal >= '$tanggalMulai' ORDER BY t.tanggal DESC");
while ($r = mysqli_fetch_assoc($qOut))
    $detailOut[] = $r;

echo json_encode([
    "saldo_bersih" => $in - $out,
    "total_pemasukan" => $in,
    "total_pengeluaran" => $out,
    "total_murid" => $totalMurid,
    "pemasukan_per_bulan" => $dataMasukKat,
    "pengeluaran_per_kategori" => $dataKeluarKat,
    "monthly_details" => $dataDetail,
    "detail_pemasukan" => $detailIn,
    "detail_pengeluaran" => $detailOut
]);
?>