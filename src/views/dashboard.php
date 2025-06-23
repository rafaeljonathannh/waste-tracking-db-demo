<?php
// Fixed dashboard.php - Replace entire content
include __DIR__ . '/layouts/header.php';
?>

<div class="container-fluid">
    <div class="row">
        <div class="col-md-12">
            <h1 class="mb-4">🗂️ Waste Tracking Database Demo</h1>

            <!-- Stats Cards -->
            <div class="row mb-4">
                <div class="col-md-3">
                    <div class="card bg-primary text-white">
                        <div class="card-body">
                            <h5>📊 Total Users</h5>
                            <h2 id="stat-users"><?= $stats['total_users'] ?? 0 ?></h2>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-success text-white">
                        <div class="card-body">
                            <h5>⚙️ Functions</h5>
                            <h2 id="stat-functions"><?= $stats['total_functions'] ?? 0 ?></h2>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-info text-white">
                        <div class="card-body">
                            <h5>🔧 Procedures</h5>
                            <h2 id="stat-procedures"><?= $stats['total_procedures'] ?? 0 ?></h2>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-warning text-white">
                        <div class="card-body">
                            <h5>📋 Tables</h5>
                            <h2 id="stat-tables"><?= $stats['total_tables'] ?? 0 ?></h2>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Navigation Tabs -->
            <ul class="nav nav-tabs" id="mainTabs" role="tablist">
                <li class="nav-item" role="presentation">
                    <button class="nav-link active" id="functions-tab" data-bs-toggle="tab" data-bs-target="#functions" type="button">
                        ⚙️ Test Functions
                    </button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link" id="procedures-tab" data-bs-toggle="tab" data-bs-target="#procedures" type="button">
                        🔧 Test Procedures
                    </button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link" id="data-tab" data-bs-toggle="tab" data-bs-target="#data" type="button">
                        📊 Data Viewer
                    </button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link" id="monitor-tab" data-bs-toggle="tab" data-bs-target="#monitor" type="button">
                        📈 Monitor Triggers
                    </button>
                </li>
            </ul>

            <!-- Tab Content -->
            <div class="tab-content" id="mainTabContent">

                <!-- Functions Tab -->
                <div class="tab-pane fade show active" id="functions" role="tabpanel">
                    <div class="card mt-3">
                        <div class="card-header">
                            <h5>⚙️ Database Functions Tester</h5>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <form id="function-form">
                                        <div class="mb-3">
                                            <label class="form-label">Select Function:</label>
                                            <select class="form-select" name="function_name" required>
                                                <option value="">Choose a function...</option>
                                                <?php foreach ($functions as $func => $desc): ?>
                                                    <option value="<?= htmlspecialchars($func) ?>"><?= htmlspecialchars($desc) ?></option>
                                                <?php endforeach; ?>
                                            </select>
                                        </div>

                                        <div class="mb-3">
                                            <label class="form-label">Parameters:</label>
                                            <input type="text" class="form-control" name="param1" placeholder="Parameter 1">
                                            <input type="text" class="form-control mt-2" name="param2" placeholder="Parameter 2 (optional)">
                                            <input type="text" class="form-control mt-2" name="param3" placeholder="Parameter 3 (optional)">
                                        </div>

                                        <button type="submit" class="btn btn-primary">Execute Function</button>
                                    </form>
                                </div>
                                <div class="col-md-6">
                                    <h6>Function Result:</h6>
                                    <div id="function-result" class="border p-3 bg-light" style="min-height: 200px;">
                                        <em>Select a function and click Execute to see results...</em>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Procedures Tab -->
                <div class="tab-pane fade" id="procedures" role="tabpanel">
                    <div class="card mt-3">
                        <div class="card-header">
                            <h5>🔧 Stored Procedures Tester</h5>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <form id="procedure-form">
                                        <div class="mb-3">
                                            <label class="form-label">Select Procedure:</label>
                                            <select class="form-select" name="procedure_name" required>
                                                <option value="">Choose a procedure...</option>
                                                <?php foreach ($procedures as $proc => $desc): ?>
                                                    <option value="<?= htmlspecialchars($proc) ?>"><?= htmlspecialchars($desc) ?></option>
                                                <?php endforeach; ?>
                                            </select>
                                        </div>

                                        <div class="mb-3">
                                            <label class="form-label">Parameters:</label>
                                            <input type="text" class="form-control" name="param1" placeholder="Parameter 1">
                                            <input type="text" class="form-control mt-2" name="param2" placeholder="Parameter 2 (optional)">
                                            <input type="text" class="form-control mt-2" name="param3" placeholder="Parameter 3 (optional)">
                                            <input type="text" class="form-control mt-2" name="param4" placeholder="Parameter 4 (optional)">
                                            <input type="text" class="form-control mt-2" name="param5" placeholder="Parameter 5 (optional)">
                                            <input type="text" class="form-control mt-2" name="param6" placeholder="Parameter 6 (optional)">
                                            <input type="text" class="form-control mt-2" name="param7" placeholder="Parameter 7 (optional)">
                                            <input type="text" class="form-control mt-2" name="param8" placeholder="Parameter 8 (optional)">
                                        </div>

                                        <button type="submit" class="btn btn-success">Execute Procedure</button>
                                    </form>
                                </div>
                                <div class="col-md-6">
                                    <h6>Procedure Result:</h6>
                                    <div id="procedure-result" class="border p-3 bg-light" style="min-height: 200px;">
                                        <em>Select a procedure and click Execute to see results...</em>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Data Viewer Tab -->
                <div class="tab-pane fade" id="data" role="tabpanel">
                    <div class="card mt-3">
                        <div class="card-header">
                            <h5>📊 Database Tables Viewer</h5>
                        </div>
                        <div class="card-body">
                            <div class="mb-3">
                                <label class="form-label">Select Table:</label>
                                <select class="form-select" id="table-select" onchange="loadTable(this.value)">
                                    <option value="">Choose a table...</option>
                                    <?php foreach ($tables as $table): ?>
                                        <option value="<?= htmlspecialchars($table) ?>"><?= htmlspecialchars($table) ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div id="table-content">
                                <em>Select a table to view its data...</em>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Monitor Tab -->
                <div class="tab-pane fade" id="monitor" role="tabpanel">
                    <div class="card mt-3">
                        <div class="card-header">
                            <h5>📈 Real-time Trigger Monitor</h5>
                        </div>
                        <div class="card-body">
                            <div class="alert alert-info">
                                <strong>Monitor Active:</strong> Watching for database trigger activities...
                            </div>
                            <div id="monitor-content">
                                <em>Monitor data will appear here...</em>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        console.log('🚀 Dashboard loaded successfully');

        const functionForm = document.getElementById('function-form');
        if (functionForm) {
            functionForm.addEventListener('submit', function(e) {
                e.preventDefault();

                const resultDiv = document.getElementById('function-result');
                resultDiv.innerHTML = '⏳ Executing function...';

                const formData = new FormData(this);
                const functionName = formData.get('function_name');

                fetch('?action=test_function', {
                        method: 'POST',
                        body: formData
                    })
                    .then(response => response.json())
                    .then(data => {
                        console.log('Function result:', data);
                        resultDiv.innerHTML = formatResult(data, functionName);
                    })
                    .catch(error => {
                        console.error('Function error:', error);
                        resultDiv.innerHTML = '<div class="alert alert-danger">Request failed: ' + error + '</div>';
                    });
            });
        }

        // Procedure Form Handler
        const procedureForm = document.getElementById('procedure-form');
        if (procedureForm) {
            procedureForm.addEventListener('submit', function(e) {
                e.preventDefault();

                const resultDiv = document.getElementById('procedure-result');
                resultDiv.innerHTML = '⏳ Executing procedure...';

                const formData = new FormData(this);
                const procedureName = formData.get('procedure_name');

                fetch('?action=test_procedure', {
                        method: 'POST',
                        body: formData
                    })
                    .then(response => response.json())
                    .then(data => {
                        console.log('Procedure result:', data);
                        resultDiv.innerHTML = formatResult(data, procedureName);
                    })
                    .catch(error => {
                        console.error('Procedure error:', error);
                        resultDiv.innerHTML = '<div class="alert alert-danger">Request failed: ' + error + '</div>';
                    });
            });
        }
    });

    // Quick test function
    function quickTestFunction(functionName, params) {
        console.log('Quick test:', functionName, params);

        const resultDiv = document.getElementById('function-result');
        resultDiv.innerHTML = '⏳ Testing ' + functionName + '...';

        const formData = new FormData();
        formData.append('function_name', functionName);
        formData.append('param1', params);

        fetch('?action=test_function', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                console.log('Quick test result:', data);
                resultDiv.innerHTML = formatResult(data, functionName);
            })
            .catch(error => {
                console.error('Quick test error:', error);
                resultDiv.innerHTML = '<div class="alert alert-danger">Request failed: ' + error + '</div>';
            });
    }

    // Load table data
    function loadTable(tableName) {
        if (!tableName) return;

        const contentDiv = document.getElementById('table-content');
        contentDiv.innerHTML = '⏳ Loading ' + tableName + ' data...';

        fetch('?action=view_table&table=' + tableName)
            .then(response => {
                console.log('Fetch Response Status:', response.status);
                console.log('Fetch Response Headers:', [...response.headers.entries()]);
                return response.json();
            })
            .then(data => {
                console.log('Table data (parsed JSON):', data);

                if (data.success && Array.isArray(data.data) && data.data.length > 0) {
                    let html = '<h6>Table: ' + tableName + ' (' + data.count + ' rows)</h6>';
                    html += '<div class="table-responsive"><table class="table table-striped table-sm">';
                    html += '<thead class="table-dark"><tr>';

                    Object.keys(data.data[0]).forEach(key => {
                        html += '<th>' + htmlspecialchars(key) + '</th>';
                    });
                    html += '</tr></thead><tbody>';

                    data.data.slice(0, 20).forEach(row => {
                        html += '<tr>';
                        Object.values(row).forEach(value => {
                            html += '<td>' + htmlspecialchars(value || '-') + '</td>';
                        });
                        html += '</tr>';
                    });

                    html += '</tbody></table></div>';
                    if (data.count > 20) {
                        html += '<p class="text-muted">Showing first 20 of ' + data.count + ' rows</p>';
                    }
                    contentDiv.innerHTML = html;
                } else {
                    let message = 'No data found.';
                    if (data.error) {
                        message = 'Error: ' + htmlspecialchars(data.error);
                    } else if (data.success === false) {
                        message = 'Operation failed with no specific error message.';
                    }
                    contentDiv.innerHTML = '<div class="alert alert-warning">' + message + '</div>';
                }
            })
            .catch(error => {
                console.error('Table load error:', error);
                contentDiv.innerHTML = '<div class="alert alert-danger">Failed to load table data: ' + htmlspecialchars(error.message || error) + '</div>';
            });
    }


    function htmlspecialchars(str) {
        if (typeof str != 'string' && typeof str != 'number') return str;
        str = String(str);
        var map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return str.replace(/[&<>"']/g, function(m) {
            return map[m];
        });
    }

    function formatResult(data, routineName = null) {
        if (!data) return '<div class="alert alert-danger">No response received</div>';

        let html = '';

        if (data.success) {
            html += '<div class="alert alert-success"><strong>✅ SUCCESS</strong></div>';

            // Custom messages for Stored Procedures
            if (routineName && routineName.startsWith('sp_')) {
                html += '<h6>Executed Stored Procedure: ' + htmlspecialchars(routineName) + '</h6>';
                html += '<div class="mb-2"><strong>Parameters:</strong> <pre class="p-2 bg-dark text-white rounded">' + htmlspecialchars(JSON.stringify(data.params, null, 2)) + '</pre></div>';

                switch (routineName) {
                    case 'sp_redeem_reward':
                        html += '<div class="mb-2"><strong>Action:</strong> Poin pengguna dikurangi dan penukaran reward dicatat. Status awal penukaran: Pending.</div>';
                        break;
                    case 'sp_laporkan_aktivitas_sampah':
                        html += '<div class="mb-2"><strong>Action:</strong> Aktivitas pelaporan sampah baru telah dicatat. Poin akan ditambahkan setelah verifikasi.</div>';
                        break;
                    case 'sp_ikut_kampanye':
                        html += '<div class="mb-2"><strong>Action:</strong> Pengguna berhasil didaftarkan ke kampanye.</div>';
                        break;
                    case 'sp_update_user_status':
                        html += '<div class="mb-2"><strong>Action:</strong> Status pengguna dengan ID <code>' + htmlspecialchars(data.params[0] || 'N/A') + '</code> telah diperbarui berdasarkan aktivitas terakhir.</div>';
                        break;
                    case 'sp_create_campaign_with_coordinator_check':
                        html += '<div class="mb-2"><strong>Action:</strong> Kampanye keberlanjutan baru telah berhasil dibuat.</div>';
                        break;
                    case 'sp_generate_user_summary':
                        html += '<div class="mb-2"><strong>Action:</strong> Ringkasan pengguna telah dihasilkan.</div>';
                        if (data.results && data.results.length > 0 && data.results[0].length > 0) {
                            html += '<h6>Summary:</h6><pre class="p-2 bg-dark text-white rounded">' + htmlspecialchars(JSON.stringify(data.results[0][0], null, 2)) + '</pre>';
                        } else {
                            html += '<div class="alert alert-info">No summary data returned.</div>';
                        }
                        break;
                    case 'sp_add_recycling_bin':
                        html += '<div class="mb-2"><strong>Action:</strong> Tempat sampah daur ulang baru telah ditambahkan.</div>';
                        break;
                    case 'sp_complete_redemption':
                        html += '<div class="mb-2"><strong>Action:</strong> Penukaran reward dengan ID <code>' + htmlspecialchars(data.params[0] || 'N/A') + '</code> telah ditandai sebagai \'processed\'.</div>';
                        break;
                    case 'sp_verifikasi_aktivitas':
                        html += '<div class="mb-2"><strong>Action:</strong> Proses verifikasi aktivitas sampah telah dilakukan untuk ID <code>' + htmlspecialchars(data.params[0] || 'N/A') + '</code>. Cek tabel aktivitas atau log monitor untuk status akhir.</div>';
                        break;
                    case 'sp_tambah_stok_reward':
                        html += '<div class="mb-2"><strong>Action:</strong> Permintaan penambahan stok reward telah diproses untuk ID <code>' + htmlspecialchars(data.params[0] || 'N/A') + '</code> dengan jumlah <code>' + htmlspecialchars(data.params[1] || 'N/A') + '</code>. Cek data Reward Item untuk stok terbaru.</div>';
                        break;
                    default:
                        html += '<div class="mb-2"><strong>Procedure Results:</strong> <pre class="p-2 bg-dark text-white rounded">' + htmlspecialchars(JSON.stringify(data.results, null, 2)) + '</pre></div>';
                        break;
                }
            } else { // For Functions
                html += '<h6>Executed Function: ' + htmlspecialchars(routineName || 'N/A') + '</h6>';
                html += '<div class="mb-2"><strong>Result:</strong> <pre class="p-2 bg-dark text-white rounded">' + htmlspecialchars(JSON.stringify(data.result, null, 2)) + '</pre></div>';
                if (data.params && data.params.length > 0) {
                    html += '<div class="mb-2"><strong>Parameters:</strong> <pre class="p-2 bg-dark text-white rounded">' + htmlspecialchars(JSON.stringify(data.params, null, 2)) + '</pre></div>';
                }
            }

            if (data.query) {
                html += '<div class="mb-2"><strong>Query:</strong> <pre class="p-2 bg-dark text-white rounded">' + htmlspecialchars(data.query) + '</pre></div>';
            }

        } else {
            html += '<div class="alert alert-danger"><strong>❌ ERROR</strong></div>';
            html += '<div class="mb-2"><strong>Error:</strong> <pre class="p-2 bg-dark text-white rounded">' + htmlspecialchars(data.error || 'Unknown error') + '</pre></div>';
            if (data.query) {
                html += '<div class="mb-2"><strong>Query:</strong> <pre class="p-2 bg-dark text-white rounded">' + htmlspecialchars(data.query) + '</pre></div>';
            }
        }

        return html;
    }

    // Auto-update stats every 30 seconds
    setInterval(function() {
        fetch('?action=get_stats')
            .then(response => response.json())
            .then(data => {
                if (data.success && data.data) {
                    const stats = data.data;
                    document.getElementById('stat-users').textContent = stats.total_users || 0;
                    document.getElementById('stat-functions').textContent = stats.total_functions || 0;
                    document.getElementById('stat-procedures').textContent = stats.total_procedures || 0;
                    document.getElementById('stat-tables').textContent = stats.total_tables || 0;
                }
            })
            .catch(error => console.log('Stats update failed:', error));
    }, 30000);

    console.log('🎯 All JavaScript loaded successfully');
</script>

<?php include __DIR__ . '/layouts/footer.php'; ?>