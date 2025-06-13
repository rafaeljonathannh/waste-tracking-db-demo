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
                            <h5>📊 Total Students</h5>
                            <h2 id="stat-students"><?= $stats['total_students'] ?? 0 ?></h2>
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
                                                    <option value="<?= $func ?>"><?= $desc ?></option>
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
                                        
                                        <div class="mt-3">
                                            <h6>Quick Tests:</h6>
                                            <button type="button" class="btn btn-sm btn-outline-primary" onclick="quickTestFunction('total_poin_mahasiswa', '1')">
                                                total_poin_mahasiswa(1)
                                            </button>
                                            <button type="button" class="btn btn-sm btn-outline-primary" onclick="quickTestFunction('jumlah_kampanye_mahasiswa', '1')">
                                                jumlah_kampanye_mahasiswa(1)
                                            </button>
                                            <button type="button" class="btn btn-sm btn-outline-primary" onclick="quickTestFunction('status_mahasiswa', '1')">
                                                status_mahasiswa(1)
                                            </button>
                                        </div>
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
                                                    <option value="<?= $proc ?>"><?= $desc ?></option>
                                                <?php endforeach; ?>
                                            </select>
                                        </div>
                                        
                                        <div class="mb-3">
                                            <label class="form-label">Parameters:</label>
                                            <input type="text" class="form-control" name="param1" placeholder="Parameter 1">
                                            <input type="text" class="form-control mt-2" name="param2" placeholder="Parameter 2 (optional)">
                                            <input type="text" class="form-control mt-2" name="param3" placeholder="Parameter 3 (optional)">
                                            <input type="text" class="form-control mt-2" name="param4" placeholder="Parameter 4 (optional)">
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
                                        <option value="<?= $table ?>"><?= $table ?></option>
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
// Wait for document ready
document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 Dashboard loaded successfully');
    
    // Function Form Handler  
    const functionForm = document.getElementById('function-form');
    if (functionForm) {
        functionForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const resultDiv = document.getElementById('function-result');
            resultDiv.innerHTML = '⏳ Executing function...';
            
            const formData = new FormData(this);
            
            fetch('?action=test_function', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                console.log('Function result:', data);
                resultDiv.innerHTML = formatResult(data);
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
            
            fetch('?action=test_procedure', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                console.log('Procedure result:', data);
                resultDiv.innerHTML = formatResult(data);
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
        resultDiv.innerHTML = formatResult(data);
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
    .then(response => response.json())
    .then(data => {
        console.log('Table data:', data);
        if (data.success && data.data.length > 0) {
            let html = '<h6>Table: ' + tableName + ' (' + data.count + ' rows)</h6>';
            html += '<div class="table-responsive"><table class="table table-striped table-sm">';
            html += '<thead class="table-dark"><tr>';
            
            // Headers
            Object.keys(data.data[0]).forEach(key => {
                html += '<th>' + key + '</th>';
            });
            html += '</tr></thead><tbody>';
            
            // Data rows (limit to 20 for display)
            data.data.slice(0, 20).forEach(row => {
                html += '<tr>';
                Object.values(row).forEach(value => {
                    html += '<td>' + (value || '-') + '</td>';
                });
                html += '</tr>';
            });
            
            html += '</tbody></table></div>';
            if (data.count > 20) {
                html += '<p class="text-muted">Showing first 20 of ' + data.count + ' rows</p>';
            }
            contentDiv.innerHTML = html;
        } else {
            contentDiv.innerHTML = '<div class="alert alert-warning">No data found</div>';
        }
    })
    .catch(error => {
        console.error('Table load error:', error);
        contentDiv.innerHTML = '<div class="alert alert-danger">Failed to load table data</div>';
    });
}

// Format result display
function formatResult(data) {
    if (!data) return '<div class="alert alert-danger">No response received</div>';
    
    let html = '';
    
    if (data.success) {
        html += '<div class="alert alert-success"><strong>✅ SUCCESS</strong></div>';
        html += '<div class="mb-2"><strong>Result:</strong> <code>' + JSON.stringify(data.result) + '</code></div>';
        if (data.query) {
            html += '<div class="mb-2"><strong>Query:</strong> <code>' + data.query + '</code></div>';
        }
        if (data.params && data.params.length > 0) {
            html += '<div class="mb-2"><strong>Parameters:</strong> <code>' + JSON.stringify(data.params) + '</code></div>';
        }
    } else {
        html += '<div class="alert alert-danger"><strong>❌ ERROR</strong></div>';
        html += '<div class="mb-2"><strong>Error:</strong> <code>' + (data.error || 'Unknown error') + '</code></div>';
        if (data.query) {
            html += '<div class="mb-2"><strong>Query:</strong> <code>' + data.query + '</code></div>';
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
            document.getElementById('stat-students').textContent = stats.total_students || 0;
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