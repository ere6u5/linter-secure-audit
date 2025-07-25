#!/bin/bash

# ESLint Security Audit Summary
# Usage: ./eslint_audit.sh [directory]

TARGET_DIR=${1:-.}
REPORT_FILE="eve.audit"
SUMMARY_FILE="eve.summary"

echo "Running security-focused ESLint analysis on: $TARGET_DIR"
npm run lint > "$REPORT_FILE"
echo "Generating security audit report..."

awk -F': ' '
function clean_error_message(msg) {
    # Remove line numbers and "error" keyword
    sub(/^[0-9]+:[0-9]+ +error +/, "", msg)
    sub(/^[^:]+:[0-9]+:[0-9]+ +error +/, "", msg)
    # Remove file paths
    if (msg ~ /^\//) {
        return "File path reported"
    }
    # Remove npm/command line output
    if (msg ~ /^[><✖]|^[0-9]+ problems?/) {
        return "Command line output"
    }
    # Remove rule names at the end
    sub(/ +[a-zA-Z0-9-]+$/, "", msg)
    # Trim whitespace and special characters
    gsub(/^[ \t"'\''\[\]\\^\-]+|[ \t"'\''\[\]\\^\-]+$/, "", msg)
    # Skip empty messages
    if (msg == "") {
        return "Empty message"
    }
    return msg
}

function generalize_message(msg) {
    # Replace specific variable names with "variable"
    if (msg ~ /[a-zA-Z_][a-zA-Z0-9_]*/) {
        sub(/[a-zA-Z_][a-zA-Z0-9_]*/, "variable", msg)
    }
    # Replace string literals
    if (msg ~ /'\''.*'\''/) {
        sub(/'\''.*'\''/, "'\''string'\''", msg)
    }
    # Replace template literals
    if (msg ~ /`.*`/) {
        sub(/`.*`/, "`template`", msg)
    }
    # Replace numbers
    if (msg ~ /[0-9]+/) {
        sub(/[0-9]+/, "N", msg)
    }
    return msg
}

function print_section(title, severity, array, total) {
    if (total > 0) {
        print "\n" " " title " (" severity ")"
        print "----------------------------------------------"

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
            if (counts[codes[i]] > 0) {
                printf("  %-50s - %4d\n", codes[i], counts[codes[i]])
            }
        }
    }
}

BEGIN {
    print "=============================================="
    print "       ESLINT SECURITY AUDIT SUMMARY"
    print "=============================================="
    print "\nAnalyzing directory: '"$TARGET_DIR"'"
    print "\nLegend:"
    print "  Critical Security Risk (CRI)"
    print "  High Risk Issue (HRI)"
    print "  Code Quality Issue (CQI)"
    print "  Best Practice Violation (BP)"
    print "  Other Issues"
}
{
    # Extract error details
    error = clean_error_message($NF)
    if (error == "Empty message" || error == "Command line output") {
        other[error]++
        total_other++
        next
    }

    # Categorize based on your eslint.config.mjs rules
    if (error ~ /Object Injection Sink/) {
        cri["Object Injection"]++
        total_cri++
    }
    else if (error ~ /eval\(\)|eval-with-expression|implied-eval/) {
        cri["Code Injection"]++
        total_cri++
    }
    else if (error ~ /non-literal-(fs-filename|require|regexp)/) {
        cri["Non-literal Resource"]++
        total_cri++
    }
    else if (error ~ /detect-child-process/) {
        cri["Child Process Execution"]++
        total_cri++
    }
    else if (error ~ /no-secrets\/no-secrets/) {
        cri["Hardcoded Secret"]++
        total_cri++
    }
    else if (error ~ /is not defined/ && error !~ /window|document|jQuery|d3/) {
        hri["Undefined Variable"]++
        total_hri++
    }
    else if (error ~ /is defined but never used/) {
        cqi["Unused Variable"]++
        total_cqi++
    }
    else if (error ~ /no-unsafe-(assignment|call|member-access|argument|return)/) {
        hri["Unsafe Operation"]++
        total_hri++
    }
    else if (error ~ /no-explicit-any/) {
        hri["Explicit '\''any'\'' Type"]++
        total_hri++
    }
    else if (error ~ /promise\//) {
        bp["Promise Handling"]++
        total_bp++
    }
    else if (error ~ /no-prototype-builtins/) {
        bp["Prototype Builtins"]++
        total_bp++
    }
    else if (error ~ /'\''document'\'' is not defined/) {
        other["Undefined 'document'"]++
        total_other++
    }
    else if (error ~ /'\''window'\'' is not defined/) {
        other["Undefined 'window'"]++
        total_other++
    }
    else if (error ~ /'\''d3'\'' is not defined/) {
        other["Undefined 'd3'"]++
        total_other++
    }
    else if (error ~ /'\''jQuery'\'' is not defined/) {
        other["Undefined 'jQuery'"]++
        total_other++
    }
    else if (error ~ /File path reported/) {
        other["File path reported"]++
        total_other++
    }
    else if (error ~ /is assigned a value but never used/) {
        other["Unused variable"]++
        total_other++
    }
    else if (error ~ /is already defined/) {
        other["Variable already defined"]++
        total_other++
    }
    else if (error ~ /Expected a conditional expression/) {
        other["Assignment in conditional"]++
        total_other++
    }
    else if (error ~ /Empty block statement/) {
        other["Empty block statement"]++
        total_other++
    }
    else if (error ~ /Unreachable code/) {
        other["Unreachable code"]++
        total_other++
    }
    else if (error ~ /no-useless-escape/) {
        other["Useless escape character"]++
        total_other++
    }
    else if (error ~ /Expected a 'break' statement/) {
        other["Missing break statement"]++
        total_other++
    }
    else if (error ~ /Do not access Object\.prototype method/) {
        other["Object.prototype method access"]++
        total_other++
    }
    else if (error ~ /Use the isNaN function/) {
        other["Incorrect NaN comparison"]++
        total_other++
    }
    else if (error ~ /eval can be harmful/) {
        other["Use of eval()"]++
        total_other++
    }
    else {
        # Generalize remaining messages
        gen_error = generalize_message(error)
        other[gen_error]++
        total_other++
    }

    total_issues++
}
END {
    # Critical Security Risks (CRI)
    print_section("CRITICAL SECURITY RISKS", "CRI", cri, total_cri)

    # High Risk Issues (HRI)
    print_section("HIGH RISK ISSUES", "HRI", hri, total_hri)

    # Code Quality Issues (CQI)
    print_section("CODE QUALITY ISSUES", "CQI", cqi, total_cqi)

    # Best Practices (BP)
    print_section("BEST PRACTICE VIOLATIONS", "BP", bp, total_bp)

    # Other Issues - only show if more than threshold
    print "\nOTHER ISSUES"
    print "----------------------------------------------"
    threshold = 2  # Only show groups with more than this many occurrences
    other_count = 0
    for (err in other) {
        if (other[err] > threshold && err != "Empty message" && err != "Command line output") {
            printf("  %-50s - %4d\n", err, other[err])
            other_count += other[err]
        }
    }
    # Show remaining count
    remaining = total_other - other_count
    if (remaining > 0) {
        printf("  %-50s - %4d\n", "Other minor issues", remaining)
    }

    # Summary
    print "\nSUMMARY STATS"
    print "----------------------------------------------"
    printf("  %-25s %4d (%.1f%%)\n", "Critical Security Risks:", total_cri, (total_cri/total_issues)*100)
    printf("  %-25s %4d (%.1f%%)\n", "High Risk Issues:", total_hri, (total_hri/total_issues)*100)
    printf("  %-25s %4d (%.1f%%)\n", "Code Quality Issues:", total_cqi, (total_cqi/total_issues)*100)
    printf("  %-25s %4d (%.1f%%)\n", "Best Practice Violations:", total_bp, (total_bp/total_issues)*100)
    printf("  %-25s %4d (%.1f%%)\n", "Other Issues:", total_other, (total_other/total_issues)*100)
    print "----------------------------------------------"
    printf("  %-25s %4d\n", "TOTAL ISSUES:", total_issues)
    print "\nGenerated: " strftime("%Y-%m-%d %H:%M:%S")
}' "$REPORT_FILE" > "$SUMMARY_FILE"

echo "Security audit report generated: $SUMMARY_FILE"