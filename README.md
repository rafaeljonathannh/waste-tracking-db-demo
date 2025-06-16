# 🗂️ Waste Tracking Database Demo

> **Demo website untuk menguji implementasi database functions, stored procedures, dan triggers dari sistem tracking sampah dan daur ulang kampus.**

![Demo Screenshot](https://img.shields.io/badge/Status-Working-brightgreen) ![PHP](https://img.shields.io/badge/PHP-8.1+-blue) ![MySQL](https://img.shields.io/badge/MySQL-8.0+-orange) ![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3-purple)

## 🚀 Cara Instal

### Step 1: Clone Repository
```bash
# Clone repository
git clone https://github.com/rafaeljonathannh/waste-tracking-db-demo.git
cd waste-tracking-db-demo

# Atau download ZIP dan extract ke folder htdocs
```

### Step 2: Setup Web Server
```bash
# Windows XAMPP
Copy folder ke: C:\xampp\htdocs\waste-tracking-db-demo\

# macOS XAMPP  
Copy folder ke: /Applications/XAMPP/htdocs/waste-tracking-db-demo/

# Linux LAMP
Copy folder ke: /var/www/html/waste-tracking-db-demo/
```

### Step 3: Start Services
```bash
# Start XAMPP Control Panel
1. Start Apache
2. Start MySQL
3. Verify services running (green indicators)
```

### Step 4: Setup Database

#### 4.1 Create Database
1. Open **phpMyAdmin**: `http://localhost/phpmyadmin`
2. Click **"New"** 
3. Database name: `fp_mbd`
4. Collation: `utf8mb4_general_ci`
5. Click **"Create"**

#### 4.2 Import Database and Schema
1. Select database `fp_mbd`
2. Click **"Import"** tab
3. Choose file: `database/fp_mbdFIX.sql`
4. Click **"Go"** - wait for completion
5. Import again: `database/schema_fixes.sql`
6. Click **"Go"**

#### 4.3 Import Function, Stored Procedure, and Trigger
1. Select database `fp_mbd`
2. Click **"Import"** tab
3. Choose file: `database/extra/func.sql`
4. Click **"Go"**
5. Choose file: `database/extra/sp.sql`
6. Click **"Go"**
7. Choose file: `database/extra/trigger.sql`
8. Click **"Go"**

#### 4.4 Verify Import
```sql
-- Run in phpMyAdmin SQL tab
SHOW FUNCTION STATUS WHERE Db = 'fp_mbd';
SHOW PROCEDURE STATUS WHERE Db = 'fp_mbd';
SHOW TRIGGERS; -- in the database
SHOW TABLES;

-- Test function
SELECT total_poin_mahasiswa(1) as test_result;
```

**Expected Results:**
- 12+ functions found
- 7+ procedures found  
- 15+ tables created
- Function test returns numeric value

### Step 5: Test Installation
1. **Access Website**: `http://localhost/waste-tracking-db-demo/public/`
2. **Verify Dashboard**: Should load without errors
3. **Test Function**: 
   - Tab "Test Functions"
   - Select `total_poin_mahasiswa`
   - Parameter: `1`
   - Click "Execute Function"
   - Should return numeric result

## 📁 Project Structure

```
waste-tracking-db-demo/
├── 📂 database/
│   ├── 📄 fp_mbdFIX.sql           # Main database schema & data
│   └── 📄 schema_fixes.sql        # Schema corrections & test data
├── 📂 src/
│   ├── 📂 config/
│   │   └── 📄 database.php        # Database connection config
│   ├── 📂 controllers/
│   │   └── 📄 MainController.php  # Main application controller
│   ├── 📂 models/
│   │   └── 📄 DatabaseModel.php   # Database operations model
│   └── 📂 views/
│       ├── 📂 layouts/
│       │   ├── 📄 header.php      # HTML header template
│       │   └── 📄 footer.php      # HTML footer template
│       └── 📄 dashboard.php       # Main dashboard view
├── 📂 public/
│   ├── 📄 index.php              # Application entry point
│   └── 📄 .htaccess              # Apache URL rewriting
├── 📄 README.md                  # This documentation
└── 📄 .gitignore                 # Git ignore file
```

### Key Files Explained

- **`public/index.php`** - Application bootstrap, handles all requests
- **`src/controllers/MainController.php`** - Routes requests to appropriate methods
- **`src/models/DatabaseModel.php`** - Database functions, procedures, and data operations
- **`src/views/dashboard.php`** - Main UI with tabs and JavaScript functionality
- **`database/fp_mbdFIX.sql`** - Complete database with functions, procedures, triggers, and sample data

## 🔧 Configuration

### Database Configuration
Edit `src/config/database.php` if needed:

```php
<?php
class Database {
    private $host = "localhost";        // Database host
    private $db_name = "fp_mbd";        // Database name
    private $username = "root";         // MySQL username
    private $password = "";             // MySQL password (empty for XAMPP)
    
    // Connection settings
    public function getConnection() {
        // PDO connection with UTF-8 charset
        $this->conn = new PDO(
            "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8", 
            $this->username, 
            $this->password
        );
        $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $this->conn;
    }
}
?>
```

### Environment Settings
For **development** in `public/index.php`:
```php
error_reporting(E_ALL);
ini_set('display_errors', 1);
```

For **production**:
```php
error_reporting(0);
ini_set('display_errors', 0);
```

### Apache Configuration
The included `.htaccess` handles URL rewriting:
```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php [QSA,L]
```

## 🧪 Usage Examples

### Testing Functions

#### Example 1: Check Student Points
```sql
Function: total_poin_mahasiswa
Parameter: 1
Expected Result: Numeric value (e.g., 30, 150, 225)
```

#### Example 2: Count Active Students  
```sql
Function: jumlah_mahasiswa_aktif_fakultas
Parameter: 1
Expected Result: Count of active students in faculty 1
```

#### Example 3: Student Status Check
```sql
Function: status_mahasiswa  
Parameter: 1
Expected Result: "active" or "inactive"
```

### Testing Procedures

#### Example 1: Report Waste Activity
```sql
Procedure: sp_laporkan_aktivitas_sampah
Parameters: 1,1,5.0,verified
Result: Inserts new recycling activity + auto-calculates points
```

#### Example 2: Redeem Reward
```sql
Procedure: sp_redeem_reward
Parameters: 1,1
Result: Deducts points + creates redemption record
```

### Monitoring Triggers

1. Execute procedure `sp_laporkan_aktivitas_sampah`
2. Switch to "Monitor Triggers" tab
3. Watch points automatically added via trigger
4. Data updates every 30 seconds

### Demo Scenarios

#### Scenario 1: Complete Student Flow
```bash
1. Test: total_poin_mahasiswa(1) → Check initial points
2. Execute: sp_laporkan_aktivitas_sampah(1,1,3.0,'verified') → Add waste activity  
3. Monitor: Watch points increase via trigger
4. Test: total_poin_mahasiswa(1) → Verify points updated
```

#### Scenario 2: Reward System
```bash
1. Test: total_poin_mahasiswa(1) → Check available points
2. Execute: sp_redeem_reward(1,1) → Redeem reward
3. Test: total_poin_mahasiswa(1) → Verify points deducted
4. View: rewardredemption table → See redemption record
```

## 🐛 Troubleshooting

### Common Issues & Solutions

#### ❌ **"Connection failed"**
**Symptoms:** Database connection errors
**Solutions:**
```bash
1. Verify XAMPP MySQL is running (green light)
2. Check database name: must be 'fp_mbd'
3. Verify credentials in src/config/database.php
4. Test connection: http://localhost/phpmyadmin
```

#### ❌ **"Function doesn't exist"**
**Symptoms:** Function test returns "doesn't exist" error
**Solutions:**
```sql
-- Check if functions imported
SHOW FUNCTION STATUS WHERE Db = 'fp_mbd';

-- If empty, re-import database
DROP DATABASE fp_mbd;
CREATE DATABASE fp_mbd;
-- Import fp_mbdFIX.sql again
```

#### ❌ **"Website shows blank page"**
**Symptoms:** White screen or no content
**Solutions:**
```bash
1. Check Apache is running in XAMPP
2. Verify folder permissions (755 for directories, 644 for files)
3. Check PHP error log: C:\xampp\php\logs\php_error_log
4. Enable error reporting in public/index.php
```

#### ❌ **"Function returns 0 or null"**
**Symptoms:** Functions execute but return empty results
**Solutions:**
```sql
-- Check if test data exists
SELECT * FROM byn WHERE user_id = 1;
SELECT * FROM student WHERE stud_id = 1;

-- If empty, insert test data
INSERT INTO byn (user_id, campaign_id, point_amount, timestamp) VALUES
(1, 71, 100, NOW()), (1, 84, 75, NOW());
```

#### ❌ **"JavaScript errors in console"**
**Symptoms:** F12 console shows red errors
**Solutions:**
```bash
1. Clear browser cache (Ctrl+F5)
2. Check Bootstrap CDN is accessible
3. Verify dashboard.php syntax
4. Check browser console for specific error details
```

#### ❌ **"AJAX requests fail"**  
**Symptoms:** Function/procedure tests don't respond
**Solutions:**
```bash
1. Check Apache URL rewriting is enabled
2. Verify .htaccess file exists in public/
3. Test direct endpoint: public/?action=test_function
4. Check browser network tab for failed requests
```

### Debug Tools

#### Built-in Debug Script
```bash
# Create debug file for troubleshooting
http://localhost/waste-tracking-db-demo/debug_check.php
```

#### Manual Verification
```sql
-- Test database functions directly
SELECT total_poin_mahasiswa(1) as result;
SELECT jumlah_kampanye_mahasiswa(1) as result;

-- Check table data
SELECT COUNT(*) FROM student;
SELECT COUNT(*) FROM byn;
SELECT COUNT(*) FROM sustainability_campaign;
```

#### Performance Monitoring
```sql
-- Check slow queries
SHOW PROCESSLIST;

-- Analyze query performance  
EXPLAIN SELECT total_poin_mahasiswa(1);
```

## 📈 Performance Tips

### Database Optimization
1. **Add Indexes** for frequently queried columns:
```sql
ALTER TABLE byn ADD INDEX idx_user_timestamp (user_id, timestamp);
ALTER TABLE recyclingactivity ADD INDEX idx_user_status (user_id, status);
ALTER TABLE student ADD INDEX idx_status (status);
```

2. **Monitor Query Performance:**
```sql
-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
```

3. **Optimize Functions:**
```sql
-- Use DETERMINISTIC where possible
-- Cache function results for repeated calls
-- Minimize subqueries in functions
```

### Frontend Optimization
1. **Reduce Auto-refresh Interval** (if needed):
```javascript
// In dashboard.php, change from 30000 to 60000 (60 seconds)
setInterval(function() { ... }, 60000);
```

2. **Implement Pagination** for large datasets:
```php
// Add LIMIT and OFFSET to table queries
$sql = "SELECT * FROM {$table} LIMIT ? OFFSET ?";
```

3. **Enable Compression** in `.htaccess`:
```apache
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/css text/javascript
</IfModule>
```

### Caching Strategy
```php
// Simple cache implementation
class SimpleCache {
    private static $cache = [];
    
    public static function get($key) {
        return self::$cache[$key] ?? null;
    }
    
    public static function set($key, $value, $ttl = 300) {
        self::$cache[$key] = $value;
    }
}
```
