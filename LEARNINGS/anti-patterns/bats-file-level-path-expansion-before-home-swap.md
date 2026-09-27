# Anti-pattern: bats file-level path expansion before HOME-swap setup

A `.bats` file-level assignment (`MANIFEST="$HOME/.config/..."`) executes at
PARSE time, before `setup()` swaps HOME to a TMP_HOME — so helpers using it
silently read/write the REAL user environment while the test believes it is
isolated. #610's first prune test appended a zombie entry toward the real
user manifest (caught only because the injection itself failed). Rule:
resolve every environment-dependent path INSIDE the test or a helper invoked
by it, after setup(); never at file level.
