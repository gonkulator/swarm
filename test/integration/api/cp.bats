@test "docker cp" {
	start_docker 3
	swarm_manage

	test_file="/bin/busybox"
	# create a temporary destination directory
	temp_dest=`mktemp -d`

	# create the container
	run docker_swarm run -d --name test_container busybox sleep 500
	[ "$status" -eq 0 ]

	# make sure container is up and no comming file
	run docker_swarm ps -l
	[ "${#lines[@]}" -eq 2 ]
	[[ "${lines[1]}" == *"test_container"* ]]
	[[ "${lines[1]}" == *"Up"* ]]

	# grab the checksum of the test file inside the container.
	run docker_swarm exec test_container md5sum $test_file
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -ge 1 ]

	# get the checksum number
	container_checksum=`echo ${lines[0]} | awk '{print $1}'`

	# host file
	host_file=$temp_dest/`basename $test_file`
	[ ! -f $host_file ]

	# copy the test file from the container to the host.
	run docker_swarm cp test_container:$test_file $temp_dest
	[ "$status" -eq 0 ]
	[ -f $host_file ]

	# compute the checksum of the copied file.
	run md5sum $host_file
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -ge 1 ]
	host_checksum=`echo ${lines[0]} | awk '{print $1}'`

	# Verify that they match.
	[[ "${container_checksum}" == "${host_checksum}" ]]
	# after ok, remove temp directory and file 
	rm -rf $temp_dest
}