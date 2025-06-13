</div> <!-- End Container -->

    <!-- Footer -->
    <footer class="bg-dark text-light py-4 mt-5">
        <div class="container">
            <div class="row">
                <div class="col-md-6">
                    <h6>Waste Tracking Database Demo</h6>
                    <p class="mb-0">Testing stored procedures, functions, and triggers</p>
                </div>
                <div class="col-md-6 text-md-end">
                    <p class="mb-0">
                        <i class="fas fa-database me-2"></i>MySQL 8.0 
                        <i class="fas fa-code me-2 ms-3"></i>PHP 8.1+
                    </p>
                </div>
            </div>
        </div>
    </footer>

    <!-- jQuery -->
    <script src="https://code.jquery.com/jquery-3.7.0.min.js"></script>
    
    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <!-- DataTables JS -->
    <script src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.4/js/dataTables.bootstrap5.min.js"></script>
    
    <!-- Custom JavaScript -->
    <script>
        // Global functions
        function formatResult(data) {
            if (data.success) {
                return `<div class="result-success">
                    <i class="fas fa-check-circle me-2"></i>Success: ${JSON.stringify(data.result || data.results || 'OK')}
                </div>`;
            } else {
                return `<div class="result-error">
                    <i class="fas fa-times-circle me-2"></i>Error: ${data.error}
                </div>`;
            }
        }

        function showLoading(elementId) {
            $(`#${elementId}`).html(`
                <div class="text-center">
                    <div class="spinner-border spinner-border-sm me-2" role="status"></div>
                    Executing...
                </div>
            `);
        }

        // Auto-refresh functions
        function updateStats() {
            $.get('?action=get_stats', function(data) {
                if (data.success) {
                    const stats = data.stats;
                    $('#total-students').text(stats.total_students);
                    $('#active-students').text(stats.active_students);
                    $('#total-points').text(stats.total_points.toLocaleString());
                    $('#total-activities').text(stats.total_activities);
                    $('#verified-activities').text(stats.verified_activities);
                }
            }).fail(function() {
                console.error('Failed to update stats');
            });
        }

        function updateRecentActivities() {
            $.get('?action=get_recent_activities', function(data) {
                if (data.success && data.data.length > 0) {
                    let html = '';
                    data.data.slice(0, 5).forEach(activity => {
                        html += `
                            <div class="d-flex justify-content-between align-items-center border-bottom py-2">
                                <div>
                                    <strong>User ${activity.user_id}</strong> - ${activity.type}
                                    <br><small class="text-muted">Weight: ${activity.value}kg, Status: ${activity.status}</small>
                                </div>
                                <small class="text-muted">${activity.timestamp}</small>
                            </div>
                        `;
                    });
                    $('#recent-activities').html(html);
                }
            }).fail(function() {
                console.error('Failed to update activities');
            });
        }

        function updatePointsHistory() {
            $.get('?action=get_points_history', function(data) {
                if (data.success && data.data.length > 0) {
                    let html = '';
                    data.data.slice(0, 5).forEach(point => {
                        html += `
                            <div class="d-flex justify-content-between align-items-center border-bottom py-2">
                                <div>
                                    <strong>${point.student_name || 'User ' + point.user_id}</strong>
                                    <br><small class="text-muted">Campaign: ${point.campaign_id || 'Direct'}</small>
                                </div>
                                <div class="text-end">
                                    <strong class="text-success">+${point.point_amount} pts</strong>
                                    <br><small class="text-muted">${point.timestamp}</small>
                                </div>
                            </div>
                        `;
                    });
                    $('#points-history').html(html);
                }
            }).fail(function() {
                console.error('Failed to update points history');
            });
        }

        // Start auto-refresh when document is ready
        $(document).ready(function() {
            // Initial load
            updateStats();
            updateRecentActivities();
            updatePointsHistory();
            
            // Auto-refresh every 5 seconds
            setInterval(function() {
                updateStats();
                updateRecentActivities();
                updatePointsHistory();
            }, 5000);
            
            // Initialize DataTables with default settings
            $('.data-table').DataTable({
                pageLength: 25,
                responsive: true,
                order: [[0, 'desc']]
            });
        });
    </script>
</body>
</html>