# Bank Log Analyzer — Shell

A Bash-based Linux log-analysis tool that processes bank database server logs and produces security, query, transaction, session, and system-activity reports using standard Unix command-line utilities.

## Features
- Failed-login analysis grouped by IP address and user
- Brute-force detection for repeated failed login attempts
- Query activity summary for SELECT, INSERT, UPDATE, and DELETE operations
- Slow-query detection
- Transaction reporting for deposits, withdrawals, declines, and rollbacks
- Critical-event extraction
- User-specific activity reports
- Login/logout session tracking and duration calculation
- Events-per-hour analysis
- General log summary and busiest-module detection
- Interactive report menu

## Linux Tools & Concepts
- Bash / Shell scripting
- `grep`, `awk`, `sed`, `cut`, `sort`, `uniq`
- `date`
- Pipes and text-processing pipelines
- Functions, loops, conditionals, and string processing
- File validation and error handling

## Usage
```bash
chmod +x bank_loganalyzer.sh
./bank_loganalyzer.sh
```

The script expects `bank_server.log` in the current directory.

## Log Format
```text
[TIMESTAMP] [LOG_LEVEL] [SESSION_ID] [USER] [CLIENT_IP] [MODULE] - MESSAGE
```

## What I Learned
This project strengthened my understanding of Linux text-processing tools and how shell pipelines can transform raw server logs into operational and security reports. It also reinforced modular shell scripting, validation, session analysis, and command-line automation.

## Author
**Ameer Daibes**  
Computer Engineering Student — Birzeit University

[LinkedIn](https://www.linkedin.com/in/ameer-daibes-1510aa207)
