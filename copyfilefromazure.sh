#/bin/bash -e
while getopts "a:t:p:f:w:x:y:z:" opt; do
    case $opt in
        a)
            artifactsLocation=$OPTARG #base uri of the file including the container
        ;;
        t)
            token=$OPTARG #saToken for the uri - use "?" if the artifact is not secured via sasToken
        ;;
        p)
            pathToFile=$OPTARG #path to the file relative to artifactsLocation
        ;;
        f)
            fileToInstall=$OPTARG #comma separated list of filenames of the files to download from storage
        ;;
		u)
		    tenantId=$OPTARG #AzureTenant Id
		;;
		v)
		    appId=$OPTARG #Azure App Id
		;;
		w)
		    appPassword=$OPTARG #Azure App Password
		;;
		x)
			resourceGroup=$OPTARG #Azure Resource Group
		;;
		y)
			clusterName=$OPTARG #Azure Kubernetes Cluster Name
		;;
		z)
			nodeCount=$OPTARG # Azure Kubernetes Node Count
		;;
    esac
done

echo "artifactsLocation : $artifactsLocation"
echo "token : $token"
echo "pathToFile : $pathToFile"
echo "fileToInstall : $fileToInstall"
echo "tenantId : $tenantId"
echo "appId : $appId"
echo "appPassword : $appPassword"
echo "resourceGroup : $resourceGroup"
echo "clusterName : $clusterName"
echo "nodeCount : $nodeCount"

IFS=',' read -ra ADDR <<< "$fileToInstall"
for i in "${ADDR[@]}"; do
    # process "$i"
	echo "Processing: $i"
	fileUrl="$artifactsLocation/$pathToFile/$i$token"
	stagingDir="/staging"

	mkdir -v "$stagingDir"

	echo "...................."
	echo "path: $stagingDir/$i"
	echo "...................."
	echo "uri: $fileUrl"
	echo "...................."

	curl -v -o "$stagingDir/$i" $fileUrl
done

sed -i '1s/^\xEF\xBB\xBF//' /staging/setup.sh
sed -i 's/\r$//' /staging/setup.sh
bash /staging/setup-mgmt.sh "$tenantId" "$appId" "$appPassword" "$resourceGroup" "$clusterName" "$nodeCount"
