#!/bin/bash

# RuboCop Audit Summary
# Usage: ./rubocop_audit.sh [directory]

TARGET_DIR=${1:-.}
REPORT_FILE="rubocop.audit"
SUMMARY_FILE="rubocop.summary"

echo "Running RuboCop analysis on: $TARGET_DIR"
rubocop --format offenses "$TARGET_DIR" > "$REPORT_FILE"
echo "Generating tmp report..."

awk '
function print_section(title, array, total) {
    if (total > 0) {
        print "===== " title " ====="
        # Sort by count (descending)
        count = 0
        for (code in array) {
            counts[code] = array[code]
            codes[++count] = code
        }

        for (i = 1; i <= count; i++) {
            for (j = i + 1; j <= count; j++) {
                if (counts[codes[i]] < counts[codes[j]]) {
                    tmp = codes[i]
                    codes[i] = codes[j]
                    codes[j] = tmp
                }
            }
        }

        for (i = 1; i <= count; i++) {
            printf("%-45s - %4d\n", codes[i], counts[codes[i]])
        }
        print ""
    }
}

BEGIN {
    print "=============================================="
    print "              RUBOCOP AUDIT REPORT"
    print "=============================================="
    print ""
    print "Analyzing directory: '"$TARGET_DIR"'"
    print ""
    total_issues = 0
}
/^ *[0-9]+ +[A-Za-z]+\// {
    # Extract count and cop name
    count = $1 + 0  # Force numeric conversion
    cop = $2
    sub(/^ *[0-9]+ +/, "", cop)
    
    # Categorize cops
    if (cop ~ /^Security\//) { security[cop] += count; total_security += count }
    else if (cop ~ /^Lint\//) { lint[cop] += count; total_lint += count }
    else if (cop ~ /^Metrics\//) { metrics[cop] += count; total_metrics += count }
    else if (cop ~ /^Style\//) { style[cop] += count; total_style += count }
    else if (cop ~ /^Layout\//) { layout[cop] += count; total_layout += count }
    else if (cop ~ /^RSpec\//) { rspec[cop] += count; total_rspec += count }
    else if (cop ~ /^Bundler\//) { bundler[cop] += count; total_bundler += count }
    else if (cop ~ /^Gemspec\//) { gemspec[cop] += count; total_gemspec += count }
    else if (cop ~ /^Naming\//) { naming[cop] += count; total_naming += count }
    else if (cop ~ /^Rails\//) { rails[cop] += count; total_rails += count }
    else if (cop ~ /^Performance\//) { performance[cop] += count; total_performance += count }
    else if (cop ~ /^ThreadSafety\//) { threadsafety[cop] += count; total_threadsafety += count }
    else { other[cop] += count; total_other += count }
    
    total_issues += count
}
END {
    # Security Issues
    print_section("SECURITY ISSUES", security, total_security)

    # Lint Issues
    print_section("LINT ISSUES", lint, total_lint)

    # Metrics Issues
    print_section("METRICS ISSUES", metrics, total_metrics)

    # Style Issues
    print_section("STYLE ISSUES", style, total_style)

    # Layout Issues
    print_section("LAYOUT ISSUES", layout, total_layout)

    # RSpec Issues
    print_section("RSPEC ISSUES", rspec, total_rspec)

    # Rails Issues
    print_section("RAILS ISSUES", rails, total_rails)

    # Performance Issues
    print_section("PERFORMANCE ISSUES", performance, total_performance)

    # Thread Safety Issues
    print_section("THREAD SAFETY ISSUES", threadsafety, total_threadsafety)

    # Bundler Issues
    print_section("BUNDLER ISSUES", bundler, total_bundler)

    # Gemspec Issues
    print_section("GEMSPEC ISSUES", gemspec, total_gemspec)

    # Naming Issues
    print_section("NAMING ISSUES", naming, total_naming)

    # Other Issues
    print_section("OTHER ISSUES", other, total_other)

    # Summary
    print "===== SUMMARY STATS ====="
    if (total_security > 0) printf("%-25s - %4d (%.1f%%)\n", "Security Issues", total_security, (total_security/total_issues)*100)
    if (total_lint > 0) printf("%-25s - %4d (%.1f%%)\n", "Lint Issues", total_lint, (total_lint/total_issues)*100)
    if (total_metrics > 0) printf("%-25s - %4d (%.1f%%)\n", "Metrics Issues", total_metrics, (total_metrics/total_issues)*100)
    if (total_style > 0) printf("%-25s - %4d (%.1f%%)\n", "Style Issues", total_style, (total_style/total_issues)*100)
    if (total_layout > 0) printf("%-25s - %4d (%.1f%%)\n", "Layout Issues", total_layout, (total_layout/total_issues)*100)
    if (total_rspec > 0) printf("%-25s - %4d (%.1f%%)\n", "RSpec Issues", total_rspec, (total_rspec/total_issues)*100)
    if (total_rails > 0) printf("%-25s - %4d (%.1f%%)\n", "Rails Issues", total_rails, (total_rails/total_issues)*100)
    if (total_performance > 0) printf("%-25s - %4d (%.1f%%)\n", "Performance Issues", total_performance, (total_performance/total_issues)*100)
    if (total_threadsafety > 0) printf("%-25s - %4d (%.1f%%)\n", "Thread Safety Issues", total_threadsafety, (total_threadsafety/total_issues)*100)
    if (total_bundler > 0) printf("%-25s - %4d (%.1f%%)\n", "Bundler Issues", total_bundler, (total_bundler/total_issues)*100)
    if (total_gemspec > 0) printf("%-25s - %4d (%.1f%%)\n", "Gemspec Issues", total_gemspec, (total_gemspec/total_issues)*100)
    if (total_naming > 0) printf("%-25s - %4d (%.1f%%)\n", "Naming Issues", total_naming, (total_naming/total_issues)*100)
    if (total_other > 0) printf("%-25s - %4d (%.1f%%)\n", "Other Issues", total_other, (total_other/total_issues)*100)
    
    print "=============================="
    printf("TOTAL: %4d issues\n", total_issues)
    print ""
    print "Audit completed: " strftime("%Y-%m-%d %H:%M:%S")
}' "$REPORT_FILE" > "$SUMMARY_FILE"

echo "Generating audit report..."
rubocop --format simple "$TARGET_DIR" > "$REPORT_FILE"
echo "RuboCop audit report generated: $SUMMARY_FILE"