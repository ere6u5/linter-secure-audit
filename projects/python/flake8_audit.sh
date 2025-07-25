#!/bin/bash

# Flake8 code audit script
# Usage: ./flake8_audit.sh [directory]

TARGET_DIR=${1:-.}  # Use current directory if no argument provided
REPORT_FILE="webob.audit"
SUMMARY_FILE="webob.summary"

# Suppress pkg_resources deprecation warning
export PYTHONWARNINGS="ignore:DeprecationWarning:pkg_resources"

echo "Running flake8 analysis on: $TARGET_DIR"
flake8 "$TARGET_DIR" > "$REPORT_FILE"

echo "Generating formatted report..."

awk -F: '
function print_section(title, array, total) {
    if (total > 0) {
        print "===== " title " ====="
        # Manual sorting by count (descending)
        count = 0
        for (code in array) {
            counts[code] = array[code]
            codes[count++] = code
        }
        # Simple bubble sort (good enough for small datasets)
        for (i = 0; i < count; i++) {
            for (j = i + 1; j < count; j++) {
                if (counts[codes[i]] < counts[codes[j]]) {
                    tmp = codes[i]
                    codes[i] = codes[j]
                    codes[j] = tmp
                }
            }
        }
        # Print sorted results
        for (i = 0; i < count; i++) {
            printf("%-8s - %4d\n", codes[i], counts[codes[i]])
        }
        print ""
    }
}

BEGIN {
    print "=============================================="
    print "              FLAKE8 AUDIT REPORT"
    print "=============================================="
    print ""
    print "Analyzing directory: '"$TARGET_DIR"'"
    print ""
}
{
    # Get the error code (last field)
    code = $NF
    sub(/^[ \t]+/, "", code)  # Remove leading whitespace

    # Count by category
    if (code ~ /^S/) {sec[code]++; total_sec++} 
    else if (code ~ /^B/) {bug[code]++; total_bug++} 
    else if (code ~ /^G/) {dlog[code]++; total_dlog++}
    else if (code ~ /^D/) {doc[code]++; total_doc++}
    else if (code ~ /^P/) {pie[code]++; total_pie++}
    else {other[code]++; total_other++}
}
END {
    # Security Issues
    print_section("SECURITY (S) CRITICAL ISSUES", sec, total_sec)

    # Bug Risks
    print_section("BUG RISKS (B)", bug, total_bug)

    # Docstrings
    print_section("DOCSTRINGS (D)", doc, total_doc)

    # Logging
    print_section("LOGGING (G)", dlog, total_dlog)

    # PIE
    print_section("PIE (P)", pie, total_pie)

    # Other Issues
    print_section("OTHER ISSUES", other, total_other)

    # Summary
    print "===== SUMMARY STATS ====="
    printf("Security (S): %4d issues\n", total_sec)
    printf("Bug Risks (B): %4d issues\n", total_bug)
    printf("Docstrings (D): %4d issues\n", total_doc)
    printf("Logging (G): %4d issues\n", total_log)
    printf("PIE (P): %4d issues\n", total_pie)
    printf("Other: %4d issues\n", total_other)
    print "=============================="
    printf("TOTAL: %4d issues\n", total_sec+total_bug+total_doc+total_log+total_pie+total_other)
    print ""
    print "Audit completed"
}' "$REPORT_FILE" > "$SUMMARY_FILE"