#!/bin/bash
# log_usage.sh

# This line specifies the interpreter to be used for executing the script.
# In this case, it indicates that the script should be run using the Bash shell.

# Define log file
LOG_FILE="/home/marteck/eksamen8/log_usage.log"
# This line defines a variable named LOG_FILE that holds the path to the log file.
# The log file will be used to store the output of the CPU usage and disk space commands.

# Log CPU usage
echo "CPU Usage:" >> "$LOG_FILE"
# This line appends the string "CPU Usage:" to the log file.
# The '>>' operator is used to append text to the file, so it won't overwrite existing content.

top -bn1 | awk '/Cpu\(s\)/ {print}' >> "$LOG_FILE"
# This line runs the 'top' command to get a snapshot of system processes.
# The '-b' option makes 'top' run in batch mode (suitable for logging).
# The '-n1' option tells 'top' to only run for one iteration (one snapshot).
# The output of 'top' is then piped (|) to 'awk'.
# 'awk' searches for lines that match the pattern '/Cpu\(s\)/', which looks for the line containing "Cpu(s)".
# The '{print}' action tells 'awk' to print those matching lines.
# Finally, the output is appended to the log file specified by LOG_FILE.

# Log Disk Space Availability
echo "Disk Space Availability:" >> "$LOG_FILE"
# This line appends the string "Disk Space Availability:" to the log file.
# Again, '>>' is used to append the text.

df -h >> "$LOG_FILE"
# This line runs the 'df' command, which reports file system disk space usage.
# The '-h' option makes the output human-readable (e.g., showing sizes in KB, MB, or GB).
# The output of the 'df' command is appended to the log file specified by LOG_FILE.

# Add a timestamp
echo "Logged at: $(date)" >> "$LOG_FILE"
# This line appends a timestamp to the log file.
# The 'date' command is executed within the command substitution syntax $(...) to get the current date and time.
# The output is appended to the log file.

echo "-----------------------------------" >> "$LOG_FILE"
# This line appends a separator line of dashes to the log file.
# This helps visually separate different log entries, making it easier to read the log file.
