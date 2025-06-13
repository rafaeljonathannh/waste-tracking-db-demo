# Waste Tracking Database Demo

Demo website untuk menguji implementasi database functions, stored procedures, dan triggers dari sistem tracking sampah dan daur ulang kampus.

## 🚀 Quick Start

### Prerequisites
- XAMPP (dengan PHP 8.1+ dan MySQL 8.0+)
- Web browser modern
- Git (optional)

### Installation

1. **Clone/Download Repository**
   ```bash
   git clone https://github.com/your-username/waste-tracking-db-demo.git
   cd waste-tracking-db-demo
   ```

2. **Setup Database**
   - Start XAMPP (Apache + MySQL)
   - Buka http://localhost/phpmyadmin
   - Import `database/fp_mbdFIX.sql`
   - Jalankan `database/schema_fixes.sql`

3. **Setup Web Server**
   - Copy folder project ke `C:\xampp\htdocs\`
   - Atau buat virtual host (opsional)

4. **Akses Website**
   - Buka http://localhost/waste-tracking-db-demo/public/
   - Website akan auto-refresh data setiap 5 detik

## 📁 Project Structure

```
waste-tracking-db-demo/
├── database/
│   ├── fp_mbdFIX.sql           # Database utama
│   └── schema_fixes.sql        # Perbaikan schema
├── src/
│   ├── config/
│   │   └── database.php        # Konfigurasi database
│   ├── controllers/
│   │   └── MainController.php  # Controller utama
│   ├── models/
│   │   └── DatabaseModel.php   # Model database
│   └── views/
│       ├── layouts/
│       │   ├── header.php      # Header template
│       │   └── footer.php      # Footer template
│       └── dashboard.php       # Dashboard utama
├── public/
│   ├── index.php              # Entry point
│   └── .htaccess              # URL rewriting
└── README.md                  # Dokumentasi ini
```

## 🧪 Features

### 1. **Function Tester**
- Test semua database functions
- Input parameter dinamis
- Real-time results display
- Quick test buttons untuk demo cepat

**Available Functions:**
- `total_poin_mahasiswa(stud_id)` - Total poin mahasiswa
- `jumlah_kampanye_mahasiswa(stud_id)` - Jumlah kampanye yang diikuti
- `total_sampah_disetor(stud_id)` - Total sampah disetor
- `jumlah_mahasiswa_aktif_fakultas(faculty_id)` - Mahasiswa aktif per fakultas
- `status_mahasiswa(stud_id)` - Status mahasiswa
- `fn_konversi_berat_ke_poin(weight)` - Konversi berat ke poin
- Dan lain-lain...

### 2. **Procedure Runner**
- Execute stored procedures dengan parameter
- Monitor hasil eksekusi
- Error handling yang informatif

**Available Procedures:**
- `sp_redeem_reward(user_id, reward_id)` - Penukaran reward
- `sp_laporkan_aktivitas_sampah(user_id, bin_id, weight, status)` - Laporan aktivitas
- `sp_generate_student_summary(user_id)` - Summary mahasiswa
- `sp_update_student_status(user_id)` - Update status
- Dan lain-lain...

### 3. **Trigger Monitor**
- Real-time monitoring database changes
- Live activity feed
- Points history tracking
- Auto-refresh every 5 seconds

**Monitored Triggers:**
- `trg_verifikasi_aktivitas_to_poin` - Auto point calculation
- `trg_status_reward_out_of_stock` - Stock management
- `trg_auto_set_student_active_on_activity` - Status updates
- `trg_decrease_reward_stock_after_redemption` - Stock reduction

### 4. **Data Viewer**
- Browse all database tables
- Searchable and sortable data
- Responsive table display
- Real-time data updates

## 🎯 Usage Examples

### Testing Functions
1. Pilih tab "Test Functions"
2. Pilih function dari dropdown
3. Masukkan parameter (contoh: untuk `total_poin_mahasiswa`, masukkan student ID)
4. Klik "Execute Function"
5. Lihat hasil di panel sebelah kanan

### Testing Procedures
1. Pilih tab "Test Procedures"
2. Pilih procedure dari dropdown
3. Masukkan parameter sesuai kebutuhan
4. Klik "Execute Procedure"
5. Monitor perubahan data di tab "Monitor Triggers"

### Monitoring Triggers
1. Pilih tab "Monitor Triggers"
2. Execute procedure yang memicu trigger
3. Watch real-time changes di activity feed
4. Data updates otomatis setiap 5 detik

## 🔧 Configuration

### Database Settings
Edit `src/config/database.php`:
```php
private $host = "localhost";
private $db_name = "fp_mbd";
private $username = "root";
private $password = "";
```

### Error Reporting
Untuk production, ubah di `public/index.php`:
```php
// Development
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Production
error_reporting(0);
ini_set('display_errors', 0);
```

## 📊 Demo Scenarios

### Scenario 1: Student Activity Flow
1. Execute: `sp_laporkan_aktivitas_sampah(1, 1, 5.0, 'verified')`
2. Watch: Points automatically added via trigger
3. Check: `total_poin_mahasiswa(1)` untuk verifikasi

### Scenario 2: Reward Redemption
1. Execute: `sp_redeem_reward(1, 1)`
2. Watch: Points deducted, stock reduced via trigger
3. Check: Reward stock in data viewer

### Scenario 3: Status Management
1. Execute: `sp_update_student_status(1)`
2. Watch: Status updated based on last activity
3. Check: Student status in real-time

## 🐛 Troubleshooting

### Common Issues

**Error: "Connection failed"**
- Pastikan XAMPP MySQL running
- Check database credentials di `database.php`
- Verify database `fp_mbd` exists

**Error: "Function doesn't exist"**
- Import `fp_mbdFIX.sql` terlebih dahulu
- Jalankan `schema_fixes.sql`
- Check MySQL error log

**Website tidak bisa diakses**
- Pastikan Apache running di XAMPP
- Check file permissions
- Verify `.htaccess` syntax

**Data tidak update real-time**
- Check browser console untuk JavaScript errors
- Verify AJAX endpoints working
- Check network connectivity

### Performance Tips

1. **Database Optimization**
   - Add indexes untuk query yang sering digunakan
   - Monitor slow query log
   - Use EXPLAIN untuk analyze queries

2. **Frontend Optimization**
   - Reduce auto-refresh interval jika diperlukan
   - Use pagination untuk large datasets
   - Implement caching untuk static data

## 📝 API Documentation

### AJAX Endpoints

- `GET /?action=get_stats` - Dashboard statistics
- `GET /?action=get_recent_activities` - Recent activities
- `GET /?action=get_points_history` - Points history
- `GET /?action=view_table&table=<name>` - Table data
- `POST /?action=test_function` - Execute function
- `POST /?action=test_procedure` - Execute procedure

### Response Format
```json
{
  "success": true|false,
  "data": {...},
  "error": "error message if any"
}
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/improvement`)
3. Commit changes (`git commit -am 'Add improvement'`)
4. Push to branch (`git push origin feature/improvement`)
5. Create Pull Request

## 📞 Support

Jika ada pertanyaan atau issues:
1. Check troubleshooting section
2. Review database logs
3. Check browser console
4. Create GitHub issue dengan detail error

## 📄 License

Project ini dibuat untuk keperluan edukasi dan demo database implementation.

---

**Happy Testing! 🚀**