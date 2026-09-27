#!/bin/bash

LOG_FILE="bank_server.log"

# Function to check if log file exists
check_file() {
    if [ ! -f "$LOG_FILE" ]; then
        echo "Error: $LOG_FILE not found."
        exit 1
    fi
}

# Generate a report of failed login attempts
failed_login_report() {
    echo "=========================================="
    echo "          FAILED LOGIN REPORT             "
    echo "=========================================="
    check_file
	#get failed login lines
    FAILED_LINES=$(grep '\[ERROR\].*\[AUTH\].*Failed login attempt' "$LOG_FILE")
	# count failed logins
    total=$(echo "$FAILED_LINES" | wc -l)
    echo "Total failed login attempts: $total"
    echo ""
	# count by IP
    echo "--- Failed attempts by IP ---"
    echo "$FAILED_LINES" | awk '{print $6}' | tr -d '[]' | sort | uniq -c | sort -nr
    echo ""
	# count by user
    echo "--- Failed attempts by User ---"
    echo "$FAILED_LINES" | awk '{print $14}' | sort | uniq -c | sort -nr
    echo ""
	# show suspicious IPs
    echo "--- Possible brute-force IPs (3 or more attempts) ---"
    echo "$FAILED_LINES" | awk '{print $6}' | tr -d '[]' | sort | uniq -c | sort -nr | awk '$1 >= 3 {print "WARNING: IP " $2 " has " $1 " failed attempts"}'
}

	# query activity report
query_activity_summary() {
    echo "=========================================="
    echo "         QUERY ACTIVITY SUMMARY           "
    echo "=========================================="
    check_file
	# get all query lines
    QUERY_LINES=$(grep '\[QUERY\]' "$LOG_FILE")
	# count all queries
    total=$(echo "$QUERY_LINES" | grep -c '^')
    echo "Total QUERY events: $total"
    echo ""
	# count each query type
    echo "--- Breakdown by Query Type ---"
    echo "SELECT queries: $(echo "$QUERY_LINES" | grep -c 'SELECT')"
    echo "INSERT queries: $(echo "$QUERY_LINES" | grep -c 'INSERT')"
    echo "UPDATE queries: $(echo "$QUERY_LINES" | grep -c 'UPDATE')"
    echo "DELETE queries: $(echo "$QUERY_LINES" | grep -c 'DELETE')"
}

	# slow query report
slow_query_detector() {
    echo "=========================================="
    echo "           SLOW QUERY DETECTOR            "
    echo "=========================================="
    check_file
	# find slow queries
    echo "--- Slow Query Warnings ---"
    grep -E '\[WARN|Warning\]' "$LOG_FILE" | grep -i 'slow query' | awk -F' - ' '{print $1, $2}'
}

	# transaction_report
transaction_report() {
    echo "=========================================="
    echo "           TRANSACTION REPORT             "
    echo "=========================================="
    check_file
	# count transaction types
    echo "Deposits:     $(grep -ic 'deposit' "$LOG_FILE")"
    echo "Withdrawals:  $(grep -ic 'withdraw' "$LOG_FILE")"
    echo "Declined:     $(grep -ic 'declin' "$LOG_FILE")"
    echo "Rollbacks:    $(grep -ic 'rollback' "$LOG_FILE")"
    echo ""
	# calculate total amounts
    dep_sum=$(grep -i 'deposit' "$LOG_FILE" | awk -F'$' 'BEGIN {sum=0} {sum += $2} END {print sum}')
    with_sum=$(grep -i 'withdraw' "$LOG_FILE" | awk -F'$' 'BEGIN {sum=0} {sum += $2} END {print sum}')

    echo "Total Deposited: \$$dep_sum"
    echo "Total Withdrawn: \$$with_sum"
}

	# critical events report
critical_events_report() {
    echo "=========================================="
    echo "         CRITICAL EVENTS REPORT           "
    echo "=========================================="
    check_file
	# show critical events
    grep '\[CRITICAL\]' "$LOG_FILE"
}

	# user activity report
user_activity_report() {
    echo "=========================================="
    echo "          USER ACTIVITY REPORT            "
    echo "=========================================="
    check_file
	# get username
    read -p "Enter username: " username

	# check empty username
    if [ -z "$username" ]; then
        echo "Username cannot be empty!"
        return
    fi
	# check if user exists
    if ! grep -qi "\[$username\]" "$LOG_FILE"; then
        echo "Username not found."
        return
    fi

	# show user activity
    echo "------------------------------------------"
    grep -i "\[$username\]" "$LOG_FILE"  | sort

}

	# session report
session_report() {
    echo "======================================================"
    echo "               SESSION ACTIVITY REPORT                "
    echo "======================================================"
    check_file

    echo "SESSION | LOGIN TIME | LOGOUT TIME | DURATION"
    echo "------------------------------------------------------"
	# get all login sessions
    for sess in $(grep "logged in" "$LOG_FILE" | grep -o 'SESSION_[0-9]*' | sort -u); do
		# get login and logout times
        login=$(grep "$sess" "$LOG_FILE" | grep "logged in" | awk '{print $1, $2}' | head -n 1)
        logout=$(grep "$sess" "$LOG_FILE" | grep "logged out" | awk '{print $1, $2}' | head -n 1)

		# check if session is still active
        if [ -z "$logout" ]; then
            logout="Still Active"
            duration="N/A"
        else
		# remove brackets from time
            t1=$(echo "$login" | tr -d '[]')
            t2=$(echo "$logout" | tr -d '[]')
		# convert time to seconds
            s1=$(date -d "$t1" +%s 2>/dev/null)
            s2=$(date -d "$t2" +%s 2>/dev/null)

		# calculate duration
            if [ -n "$s1" ] && [ -n "$s2" ]; then
                duration="$(( (s2 - s1) / 60 )) min"
            else
                duration="N/A"
            fi
        fi

        echo "$sess | $login | $logout | $duration"
    done
}

	# events per hour report
events_per_hour() {
    echo "=========================================="
    echo "            EVENTS PER HOUR               "
    echo "=========================================="
    check_file

    echo "HOUR    | EVENT COUNT"
    echo "------------------------------------------"

	# count events in each hour
    grep '^\[' "$LOG_FILE" | awk '{print $2}' | cut -d':' -f1 | sort | uniq -c | while read count hour; do
        echo "$hour:00  | $count events"
    done
}

	# general log summary
general_summary() {
    echo "=========================================="
    echo "           GENERAL LOG SUMMARY            "
    echo "=========================================="
    check_file
	# count total lines
    echo "Total Lines: $(wc -l < "$LOG_FILE")"

    echo "------------------------------------------"
    echo "EVENTS BY LOG LEVEL:"
	# count each log level
    grep '^\[' "$LOG_FILE" | awk '{print $3}' | tr -d '[]' | sort | uniq -c

    echo "------------------------------------------"
    echo -n "Busiest Module: "
	# find busiest module
    grep '^\[' "$LOG_FILE" | awk '{print $7}' | tr -d '[]' | sort | uniq -c | sort -n | tail -n 1
}

# 10. Run All Reports
run_all() {
    failed_login_report
    echo ""
    query_activity_summary
    echo ""
    slow_query_detector
    echo ""
    transaction_report
    echo ""
    critical_events_report
    echo ""
    user_activity_report
    echo ""
    session_report
    echo ""
    events_per_hour
    echo ""
    general_summary
}

# Main Menu Loop
while true; do
    echo ""
    echo "=========================================="
    echo "          BANK LOG ANALYZER               "
    echo "=========================================="
    echo "1. Failed Login Report"
    echo "2. Query Activity Summary"
    echo "3. Slow Query Detector"
    echo "4. Transaction Report"
    echo "5. Critical Events Report"
    echo "6. User Activity Report"
    echo "7. Login/Logout Session Report"
    echo "8. Events-per-Hour Report"
    echo "9. General Log Summary"
    echo "10. Run All Reports"
    echo "0. Exit"
    echo "=========================================="
	# user input
    read -p "Enter your choice: " choice

    case $choice in
        1) failed_login_report ;;
        2) query_activity_summary ;;
        3) slow_query_detector ;;
        4) transaction_report ;;
        5) critical_events_report ;;
        6) user_activity_report ;;
        7) session_report ;;
        8) events_per_hour ;;
        9) general_summary ;;
        10) run_all ;;
        0) 
            echo "Goodbye!"
            exit 0 
            ;;
        *) 
            echo "Invalid choice. Please try again." 
            ;;
    esac
 
    echo ""
    read -p "Press Enter to continue..."
done
