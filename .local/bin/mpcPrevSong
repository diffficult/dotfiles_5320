test=$(mpc --host=0.0.0.0 --port=6600 | grep -Eo '[0-9]+:[0-9][0-9]/' | sed 's|\([0-9].*\):\([0-9][0-9]\)/|\1\2|')
if [ "$test" -ge 5 ]; then
 mpc --host=0.0.0.0 --port=6600 seek 0
else
 mpc --host=0.0.0.0 --port=6600 prev
fi