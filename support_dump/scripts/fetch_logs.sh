containers=()
app=$1
namespace=$2
days_since="48h"
#Get all pods 
matching_pods=(`kubectl -n $namespace get pods --output=jsonpath='{.items[*].metadata.name}' | xargs -n1`)
matching_pods_size=${#matching_pods[@]}
#Get all containers 
all_pods_containers=$(echo -e `kubectl -n $namespace get pods --output=jsonpath="{range .items[*]}{.metadata.name} {.spec['containers', 'initContainers'][*].name} \n{end}"`)

#Loop through each pod and it's containers 
for pod in ${matching_pods[@]}; 
do
	pod_containers=($(echo -e "$all_pods_containers" | grep $pod | cut -d ' ' -f2- | xargs -n1))

	for container in ${pod_containers[@]}; 
	do

		if [ ${#pod_containers[@]} -eq 1 ]; then
			display_name="${pod}"
		else
			display_name="${pod}"_"${container}"
		fi
		
		file_path=/aifabric/support_bundle/$app/$namespace/$display_name".txt"
		
		
		# extract the file + dir names
		FILE="`basename "${file_path}"`"
		DIR="`dirname "${file_path}"`"

		# create the dir, then the file
		mkdir -p "${DIR}"

		kubectl -n $namespace logs ${pod} ${container} --since=$days_since > $file_path
		
		if [ $? -eq 0 ]
		then
			echo "logs successfully fetched from pod $pod and container $container"
		else
			kubectl -n $namespace describe pod $pod > $file_path
		fi
		
		# show result
		ls -l "$file_path"
		
	done
done

