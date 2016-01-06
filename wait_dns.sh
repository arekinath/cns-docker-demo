name="$1"
count="$2"
echo "waiting for ${name} to be updated in DNS..."
while true; do
	ncount=`dig +short A ${name} | wc -l`
	if [[ $ncount -ge $count ]]; then
		break
	fi
	sleep 1
done
