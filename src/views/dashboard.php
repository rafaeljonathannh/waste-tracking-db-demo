<?php include 'layouts/header.php'; ?>

<!-- Stats Cards -->
<div class="row mb-4">
    <div class="col-md-2">
        <div class="card stats-card bg-primary text-white">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h6 class="card-title">Total Students</h6>
                        <h3 class="mb-0" id="total-students">-</h3>
                    </div>
                    <div class="align-self-center">
                        <i class="fas fa-users fa-2x opacity-75"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-2">
        <div class="card stats-card bg-success text-white">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h6 class="card-title">Active Students</h6>
                        <h3 class="mb-0" id="active-students">-</h3>
                    </div>
                    <div class="align-self-center">
                        <i class="fas fa-user-check fa-2x opacity-75"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-2">
        <div class="card stats-card bg-warning text-white">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h6 class="card-title">Total Points</h6>
                        <h3 class="mb-0" id="total-points">-</h3>
                    </div>
                    <div class="align-self-center">
                        <i class="fas fa-coins fa-2x opacity-75"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stats-card bg-info text-white">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h6 class="card-title">Total Activities</h6>
                        <h3 class="mb-0" id="total-activities">-</h3>
                    </div>
                    <div class="align-self-center">
                        <i class="fas fa-recycle fa-2x opacity-75"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stats-card bg-dark text-white">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h6 class="card-title">Verified Activities</h6>
                        <h3 class="mb-0" id="verified-activities">-</h3>
                    </div>
                    <div class="align-self-center">
                        <i class="fas fa-check-double fa-2x opacity-75"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Main Tabs -->
<div class="row">
    <div class="col-12">
        <!-- Tab Navigation -->
        <ul class="nav nav-tabs" id="mainTabs" role="tablist">
            <li class="nav-item" role="presentation">
                <button class="nav-link active" id="functions-tab" data-bs-toggle="tab" data-bs-target="#functions" role="tab">
                    <i class="fas fa-function me-2"></i>Test Functions
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="procedures-tab" data-bs-toggle="tab" data-bs-target="#procedures" role="tab">
                    <i class="fas fa-cogs me-2"></i>Test Procedures
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="triggers-tab" data-bs-toggle="tab" data-bs-target="#triggers" role="tab">
                    <i class="fas fa-bolt me-2"></i>Monitor Triggers
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="data-tab" data-bs-toggle="tab" data-bs-target="#data" role="tab">
                    <i class="fas fa-table me-2"></i>View Data
                </button>
            </li>
        </ul>

        <!-- Tab Content -->
        <div class="tab-content" id="mainTabsContent">
            
            <!-- FUNCTIONS TAB -->
            <div class="tab-pane fade show active" id="functions" role="tabpanel">
                <div class="row">
                    <div class="col-md-6">
                        <h5><i class="fas fa-function me-2"></i>Test Database Functions</h5>
                        <form id="function-form">
                            <div class="mb-3">
                                <label class="form-label">Select Function</label>
                                <select class="form-select" name="function_name" required>
                                    <option value="">Choose a function...</option>
                                    <?php foreach ($functions as $name => $description): ?>
                                        <option value="<?= $name ?>"><?= $description ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Parameters (separated by comma if multiple)</label>
                                <input type="text" class="form-control" name="param1" placeholder="Parameter 1">
                                <input type="text" class="form-control mt-2" name="param2" placeholder="Parameter 2 (optional)">
                                <input type="text" class="form-control mt-2" name="param3" placeholder="Parameter 3 (optional)">
                            </div>
                            
                            <button type="submit" class="btn btn-primary">
                                <i class="fas fa-play me-2"></i>Execute Function
                            </button>
                        </form>
                    </div>
                    
                    <div class="col-md-6">
                        <h5><i class="fas fa-terminal me-2"></i>Function Result</h5>
                        <div class="code-block" id="function-result">
                            <em>No function executed yet...</em>
                        </div>
                        
                        <div class="mt-3">
                            <h6>Quick Test Examples:</h6>
                            <div class="btn-group-vertical d-grid gap-2">
                                <button class="btn btn-outline-primary btn-sm" onclick="quickTestFunction('total_poin_mahasiswa', '1')">
                                    Total Points for Student ID 1
                                </button>
                                <button class="btn btn-outline-primary btn-sm" onclick="quickTestFunction('jumlah_mahasiswa_aktif_fakultas', '1')">
                                    Active Students in Faculty 1
                                </button>
                                <button class="btn btn-outline-primary btn-sm" onclick="quickTestFunction('fn_konversi_berat_ke_poin', '5.5')">
                                    Convert 5.5kg to Points
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- PROCEDURES TAB -->
            <div class="tab-pane fade" id="procedures" role="tabpanel">
                <div class="row">
                    <div class="col-md-6">
                        <h5><i class="fas fa-cogs me-2"></i>Test Stored Procedures</h5>
                        <form id="procedure-form">
                            <div class="mb-3">
                                <label class="form-label">Select Procedure</label>
                                <select class="form-select" name="procedure_name" required>
                                    <option value="">Choose a procedure...</option>
                                    <?php foreach ($procedures as $name => $description): ?>
                                        <option value="<?= $name ?>"><?= $description ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Parameters</label>
                                <input type="text" class="form-control" name="param1" placeholder="Parameter 1">
                                <input type="text" class="form-control mt-2" name="param2" placeholder="Parameter 2 (optional)">
                                <input type="text" class="form-control mt-2" name="param3" placeholder="Parameter 3 (optional)">
                                <input type="text" class="form-control mt-2" name="param4" placeholder="Parameter 4 (optional)">
                            </div>
                            
                            <button type="submit" class="btn btn-success">
                                <i class="fas fa-play me-2"></i>Execute Procedure
                            </button>
                        </form>
                    </div>
                    
                    <div class="col-md-6">
                        <h5><i class="fas fa-terminal me-2"></i>Procedure Result</h5>
                        <div class="code-block" id="procedure-result">
                            <em>No procedure executed yet...</em>
                        </div>
                        
                        <div class="mt-3">
                            <h6>Quick Test Examples:</h6>
                            <div class="btn-group-vertical d-grid gap-2">
                                <button class="btn btn-outline-success btn-sm" onclick="quickTestProcedure('sp_generate_student_summary', '1')">
                                    Generate Summary for Student 1
                                </button>
                                <button class="btn btn-outline-success btn-sm" onclick="quickTestProcedure('sp_laporkan_aktivitas_sampah', '1,101,2.5,verified')">
                                    Report Recycling Activity
                                </button>
                                <button class="btn btn-outline-success btn-sm" onclick="quickTestProcedure('sp_update_student_status', '1')">
                                    Update Student Status
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- TRIGGERS TAB -->
            <div class="tab-pane fade" id="triggers" role="tabpanel">
                <div class="row">
                    <div class="col-md-6">
                        <h5><i class="fas fa-bolt me-2"></i>Trigger Monitoring</h5>
                        <p class="text-muted">
                            This section shows real-time changes triggered by database operations.
                            Data updates automatically every 5 seconds.
                        </p>
                        
                        <div class="card">
                            <div class="card-header">
                                <h6 class="card-title mb-0">
                                    <i class="fas fa-clock me-2"></i>Recent Activities
                                    <span class="badge bg-primary ms-2 real-time-indicator">LIVE</span>
                                </h6>
                            </div>
                            <div class="card-body activity-log" id="recent-activities">
                                <div class="text-center">
                                    <div class="spinner-border spinner-border-sm me-2" role="status"></div>
                                    Loading activities...
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-6">
                        <div class="card">
                            <div class="card-header">
                                <h6 class="card-title mb-0">
                                    <i class="fas fa-coins me-2"></i>Points History
                                    <span class="badge bg-success ms-2 real-time-indicator">LIVE</span>
                                </h6>
                            </div>
                            <div class="card-body activity-log" id="points-history">
                                <div class="text-center">
                                    <div class="spinner-border spinner-border-sm me-2" role="status"></div>
                                    Loading points history...
                                </div>
                            </div>
                        </div>
                        
                        <div class="mt-3">
                            <h6>Test Triggers:</h6>
                            <div class="btn-group-vertical d-grid gap-2">
                                <button class="btn btn-outline-warning btn-sm" onclick="testTrigger('points')">
                                    Test Point Addition Trigger
                                </button>
                                <button class="btn btn-outline-warning btn-sm" onclick="testTrigger('redemption')">
                                    Test Reward Redemption Trigger
                                </button>
                                <button class="btn btn-outline-warning btn-sm" onclick="testTrigger('status')">
                                    Test Status Update Trigger
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- DATA TAB -->
            <div class="tab-pane fade" id="data" role="tabpanel">
                <div class="row">
                    <div class="col-md-3">
                        <h5><i class="fas fa-table me-2"></i>Database Tables</h5>
                        <div class="list-group">
                            <?php foreach ($tables as $table => $name): ?>
                                <button class="list-group-item list-group-item-action" onclick="loadTable('<?= $table ?>')">
                                    <i class="fas fa-table me-2"></i><?= $name ?>
                                </button>
                            <?php endforeach; ?>
                        </div>
                    </div>
                    
                    <div class="col-md-9">
                        <div id="table-content">
                            <div class="text-center py-5">
                                <i class="fas fa-table fa-3x text-muted"></i>
                                <h5 class="mt-3 text-muted">Select a table to view data</h5>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- JavaScript for interactions -->
<script>
// Function Form Handler
$('#function-form').on('submit', function(e) {
    e.preventDefault();
    showLoading('function-result');
    
    $.post('?action=test_function', $(this).serialize())
        .done(function(data) {
            $('#function-result').html(formatResult(data));
        })
        .fail(function() {
            $('#function-result').html('<div class="result-error">Request failed</div>');
        });
});

// Procedure Form Handler
$('#procedure-form').on('submit', function(e) {
    e.preventDefault();
    showLoading('procedure-result');
    
    $.post('?action=test_procedure', $(this).serialize())
        .done(function(data) {
            $('#procedure-result').html(formatResult(data));
        })
        .fail(function() {
            $('#procedure-result').html('<div class="result-error">Request failed</div>');
        });
});

// Quick test functions
function quickTestFunction(functionName, params) {
    const paramArray = params.split(',');
    const formData = new FormData();
    formData.append('function_name', functionName);
    paramArray.forEach((param, index) => {
        formData.append(`param${index + 1}`, param.trim());
    });
    
    showLoading('function-result');
    
    $.ajax({
        url: '?action=test_function',
        method: 'POST',
        data: formData,
        processData: false,
        contentType: false,
        success: function(data) {
            $('#function-result').html(formatResult(data));
        },
        error: function() {
            $('#function-result').html('<div class="result-error">Request failed</div>');
        }
    });
}

function quickTestProcedure(procedureName, params) {
    const paramArray = params.split(',');
    const formData = new FormData();
    formData.append('procedure_name', procedureName);
    paramArray.forEach((param, index) => {
        formData.append(`param${index + 1}`, param.trim());
    });
    
    showLoading('procedure-result');
    
    $.ajax({
        url: '?action=test_procedure',
        method: 'POST',
        data: formData,
        processData: false,
        contentType: false,
        success: function(data) {
            $('#procedure-result').html(formatResult(data));
        },
        error: function() {
            $('#procedure-result').html('<div class="result-error">Request failed</div>');
        }
    });
}

// Load table data
function loadTable(tableName) {
    $('#table-content').html(`
        <div class="text-center">
            <div class="spinner-border" role="status"></div>
            <p class="mt-2">Loading ${tableName} data...</p>
        </div>
    `);
    
    $.get('?action=view_table&table=' + tableName)
        .done(function(data) {
            if (data.success && data.data.length > 0) {
                let html = `
                    <h5>Table: ${tableName} (${data.count} rows)</h5>
                    <div class="table-responsive">
                        <table class="table table-striped table-sm data-table">
                            <thead class="table-dark">
                                <tr>
                `;
                
                // Headers
                Object.keys(data.data[0]).forEach(key => {
                    html += `<th>${key}</th>`;
                });
                html += `</tr></thead><tbody>`;
                
                // Data rows
                data.data.forEach(row => {
                    html += '<tr>';
                    Object.values(row).forEach(value => {
                        html += `<td>${value || '-'}</td>`;
                    });
                    html += '</tr>';
                });
                
                html += `</tbody></table></div>`;
                $('#table-content').html(html);
                
                // Reinitialize DataTable
                $('.data-table').DataTable({
                    pageLength: 25,
                    responsive: true,
                    scrollX: true
                });
            } else {
                $('#table-content').html('<div class="alert alert-warning">No data found or error occurred</div>');
            }
        })
        .fail(function() {
            $('#table-content').html('<div class="alert alert-danger">Failed to load table data</div>');
        });
}

// Test triggers
function testTrigger(type) {
    switch(type) {
        case 'points':
            quickTestProcedure('sp_laporkan_aktivitas_sampah', '1,1,3.0,verified');
            break;
        case 'redemption':
            quickTestProcedure('sp_redeem_reward', '1,1');
            break;
        case 'status':
            quickTestProcedure('sp_update_student_status', '1');
            break;
    }
}
</script>

<?php include 'layouts/footer.php'; ?>