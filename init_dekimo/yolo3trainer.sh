
# 17/01/2020
#for tracking?:   https://github.com/AlexeyAB/darknet

CurrentWd=""$(pwd)

# TODO: Generate anchor boxes

exitfn () {
	trap SIGINT              # Restore signal handling for SIGINT
	echo; echo 'Interupt signal cached.'    # Growl at user,
	exit                     #   then exit script.
}

trap "exitfn" INT            # Set up SIGINT trap to call function.


imagesDir=""
genDir=""
if [ ! -d ${CurrentWd}/data/all ]; then
	if [ ! -d ${CurrentWd}/data ]; then
		imagesDir=""
		genDir="_gen"
	else	
		cd ${CurrentWd}/data
		imagesDir=$(ls | grep -v _.* | head -1)
		cd ${CurrentWd}
		genDir="_${imagesDir}Gen"
	fi
else
	imagesDir="all"
	genDir="_gen"
fi

# find out a name for the collection
nameCollection=""
readNameCollection()
{
	if [ ! -d ${CurrentWd}/data/all ]; then
		nameCollection="${imagesDir}"
	else
		if [ -f ${CurrentWd}/data/_genConfig/collectionName.txt ]; then
			nameCollection=$(cat ${CurrentWd}/data/_genConfig/collectionName.txt)
		else
			echo ""
			echo "enter a name of your collection"
			echo "for example: 'coins' or 'items'(default)"
			read nameOfCollection
			if [ -z "${nameOfCollection}" ]; then
				nameCollection="items"
			else
				nameCollection="${nameOfCollection}"
			fi
			mkdir -p ${CurrentWd}/data/_genConfig
			echo "${nameCollection}" > ${CurrentWd}/data/_genConfig/collectionName.txt
		fi
	fi
}

classes=""
findClasses()
{
	if [ -z "${classes}" ]; then
		for f in ${CurrentWd}/data/${imagesDir}/*.xml; do
			while read -r class
			do
				if [[ ! "${classes}" == *"\"${class}\""* ]]; then
					if [ -z "${classes}" ]; then
						classes="\"${class}\""
					else
						classes="${classes}, \"${class}\""
					fi
					printf "\rlabels found so far: ${classes}..."
				fi
			done <<< $(cat ${f} | grep \<name\> | cut -c9- | rev | cut -c8- | rev)
		done;
		echo ""
	fi	
}


printHelp=""
if [ -z "${1}" ]; then
	printHelp="true"
elif [ ${1} == "p" ]; then

	trainEvalRatio=80  # max = 100(%)

	if [ -z "${imagesDir}" ]; then
		mkdir -p ./data/all
		echo "put all your pictures in voc-xml files './data/all' or './data/[collectionName]'"
		echo "like this:"
		echo "_________________________"
		echo " data"
		echo "   |---all"
		echo "        |---1.png "
		echo "        |---1.xml "
		echo "        |---2.png "
		echo "        |---2.xml "
		echo "        |---3.png "
		echo "        |---3.xml "
		echo "_________________________"
		echo "and press enter to continue"

		read cont
	fi

	readNameCollection

	echo "clearing destination folders..."
	rm -rdf ./data/${genDir}/train_annot_folder
	rm -rdf ./data/${genDir}/train_image_folder
	rm -rdf ./data/${genDir}/valid_annot_folder
	rm -rdf ./data/${genDir}/valid_image_folder
	mkdir -p ./data/${genDir}/train_annot_folder
	mkdir -p ./data/${genDir}/train_image_folder
	mkdir -p ./data/${genDir}/valid_annot_folder
	mkdir -p ./data/${genDir}/valid_image_folder

	numTrainingImages=0
	numEvalImages=0
	echo "copying images..."
	cd ./data/${imagesDir}

	numTotalImages=0
	imageIndex=0
	for f in *.jpg ; do
		numTotalImages=$((numTotalImages+1))
	done

	for f in *.jpg ; do
		fileNameWithoutExt=${f::-4}
		xmlFileName="${fileNameWithoutExt}.xml"
		imageFileName="${f}"
		if [ -f ${xmlFileName} ]; then
			randomNum=$(tr -cd 0-9 </dev/urandom | head -c 2)
			if [[ "${randomNum}" == "0"* ]]; then
				randomNum=${randomNum:1}
			fi
			imageDestPath=""
			xmlDestPath=""
			if (( ${trainEvalRatio} > ${randomNum} )); then
				imageDestPath=../${genDir}/train_image_folder/${imageFileName}
				xmlDestPath=../${genDir}/train_annot_folder/${xmlFileName}
				numTrainingImages=$((numTrainingImages+1))
			else
				imageDestPath=../${genDir}/valid_image_folder/${imageFileName}
				xmlDestPath=../${genDir}/valid_annot_folder/${xmlFileName}
				numEvalImages=$((numEvalImages+1))
			fi
			cp ${imageFileName} ${imageDestPath}
			cp ${xmlFileName} ${xmlDestPath}
			mogrify -strip "${imageDestPath}"
			printf "\r(${imageIndex}/${numTotalImages}) training images: ${numTrainingImages}, eval images: ${numEvalImages}"
		else
			echo ""
			echo "xml file: '${xmlFileName}' is missing"
		fi
		imageIndex=$((imageIndex+1))
	done;
	echo ""
	echo "done!"


elif [ "${1}" == "ps" ]; then
	# init
	if [ ! -d ./data/${genDir}/train_annot_folder ]; then
		./yolo3trainer.sh -p
	fi
	if [ ! -d ./data/${genDir}/train_annot_folder ]; then
		exit
	fi
	if [ ! -d ./keras-yolo3 ]; then
		git clone https://github.com/experiencor/keras-yolo3.git
		mkdir -p ./keras-yolo3/${genDir}/backup
		cp ./keras-yolo3/config.json ./keras-yolo3/${genDir}/backup/originalConfig.json
	fi
	cd ./keras-yolo3

	if [ ! -d ./${genDir}/tools/gdown ]; then
		echo "downloading 'gdown' for downloading google drive files..."
		mkdir -p ./${genDir}/tools/gdown
		cd ./${genDir}/tools/gdown
		git clone https://github.com/circulosmeos/gdown.pl.git
		cd ../../../
	fi

	if [ ! -f ./${genDir}/backendweights/backend.h5 ]; then
		mkdir -p ./${genDir}/backendweights
		cd ./${genDir}/tools/gdown/gdown.pl
		echo "Downloading pretrained weights 'backend.h5'..."
		./gdown.pl 'https://drive.google.com/open?id=1o_PM_zB6FxJRdLpEx8lEAhL29IMe1KzI' 'backend.h5'
		mv ./backend.h5 ../../../backendweights/backend.h5
		cd ../../../../
	fi

	readNameCollection
	echo "collection name set to '${nameCollection}'"

	# find labels
	echo "scanning for labels..."
	findClasses

	# copy pretrained weights
	if [ ! -f ./backend.h5 ]; then
		echo "copying 'backend.h5' to '${nameCollection}.h5'..."
		cp ./${genDir}/backendweights/backend.h5 ./${nameCollection}.h5
	fi

	echo "updating config..."
	# update config	
	sed -i '/["]train_image_folder["][:]/c\        "train_image_folder":   "'${CurrentWd}'/data/'${genDir}'/train_image_folder/",' ./config.json
	sed -i '/["]train_annot_folder["][:]/c\        "train_annot_folder":   "'${CurrentWd}'/data/'${genDir}'/train_annot_folder/",' ./config.json	
	sed -i '/["]valid_image_folder["][:]/c\        "valid_image_folder":   "'${CurrentWd}'/data/'${genDir}'/valid_image_folder/",' ./config.json
	sed -i '/["]valid_annot_folder["][:]/c\        "valid_annot_folder":   "'${CurrentWd}'/data/'${genDir}'/valid_annot_folder/",' ./config.json
	sed -i '/["]labels["][:]/c\        "labels":               ['"${classes}"']' ./config.json

	sed -i '/["]saved_weights_name["][:]/c\        "saved_weights_name":   "'${nameCollection}'.h5",' ./config.json

	cacheNameLineNumber=$(cat ./config.json | grep -n "cache_name" | head -1 | awk -F ':' '{print $1}')
	sed -i ''${cacheNameLineNumber}'s/.*/        "cache_name":           "'${nameCollection}'_train.pkl",/' ./config.json
	cacheNameLineNumber2=$(cat ./config.json | grep -n "cache_name" | tail -1 | awk -F ':' '{print $1}')
	sed -i ''${cacheNameLineNumber2}'s/.*/        "cache_name":           "'${nameCollection}'_valid.pkl",/' ./config.json

	echo "done!"

elif [ "${1}" == "pl" ]; then
	if [ ! -d ./keras-yolo3 ]; then
		echo "first run 'yolo3trainer.sh -l' at east once. ( you can terminate right after if you like )"
		exit
	fi
	cd ./keras-yolo3
	python3 train.py -c config.json

elif [ "${1}" == "pr" ]; then

	cd ./keras-yolo3
	for f in *.h5; do
		rm ${f}
		echo "'${f}' removed"
	done;

	echo "reset done"

elif [ "${1}" == "pa" ]; then
	if [ ! -d ./keras-yolo3 ]; then
		echo "first run 'yolo3trainer.sh -l' at east once. ( you can terminate right after if you like )"
		exit
	fi
	cd ./keras-yolo3
	anchorsStr=$(cat ./config.json | grep "\"anchors\":" | awk -F '[' '{print $2}' | rev | cut -c3- | rev) #width, height,   width, height ect.
	maxInputSize=$(cat ./config.json | grep max_input_size | awk -F ':' '{print $2}' | xargs | rev | cut -c2- | rev)

	mkdir -p ./${genDir}/temp
	if [ -f ./${genDir}/temp/tempCanvas.png ]; then
		rm ./${genDir}/temp/tempCanvas.png
	fi

	width=${maxInputSize}
	height=${maxInputSize}
	centerX=$((width/2))
	centerY=$((width/2))


	canvasFile=./${genDir}/temp/tempCanvas.png
	convert -size ${width}x${height} xc:white ${canvasFile}
	
	echo "max input size is set to: ${maxInputSize}x${maxInputSize}"

	nextBoxIndex=0
	while true; do
		nextBoxIndex=$((nextBoxIndex+1))
		boxSize=$(cut -d' ' -f${nextBoxIndex} <<<${anchorsStr})
		if [ -z "$boxSize" ]; then
			break
		fi
		boxWidth=$(cut -d',' -f1 <<<${boxSize})
		boxHeight=$(cut -d',' -f2 <<<${boxSize})
		boxWidthHalf=$((boxWidth/2))
		boxHeightHalf=$((boxHeight/2))
		minX=$((centerX-boxWidthHalf))
		minY=$((centerY-boxHeightHalf))
		echo "${nextBoxIndex}. box size: ${boxWidth}x${boxHeight}"
		convert ${canvasFile} -fill none -stroke black -strokewidth 1 -draw "translate ${centerX},${centerY} rectangle -${boxWidthHalf},-${boxHeightHalf} ${boxWidthHalf},${boxHeightHalf}" ${canvasFile}
	done

	xdg-open ${canvasFile}


elif [ "${1}" == "cs" ]; then

	trainingType="${2}"
	if [ -z "${trainingType}" ]; then
		echo "please specify a training type ('yolov3', 'yolov3_tiny')"
		exit
	fi

	if [ "${trainingType}" == "yolov3_tiny" ]; then
		sourceTrainingTypeConfigPretrained=yolov3-tiny.cfg
		sourceTrainingTypeConfig=yolov3-tiny_obj.cfg
		pretrainedWeightsFile="yolov3-tiny.weights"
		pretrainedWeightsLayer="yolov3-tiny.conv.15"
		pretrainedWeightsLayerIndex=15
	elif [ "${trainingType}" == "yolov3" ]; then
		sourceTrainingTypeConfigPretrained=yolov3.cfg
		sourceTrainingTypeConfig=yolov3.cfg
		pretrainedWeightsFile="darknet53.conv.74"
		pretrainedWeightsLayer="darknet53.conv.74"
		pretrainedWeightsLayerIndex=74
	else
		echo "unknown training type: '${trainingType}'"
		exit
	fi


	# init
	if [ ! -d ./data/${genDir}/train_annot_folder ]; then
		./yolo3trainer.sh -p
	fi
	if [ ! -d ./data/${genDir}/train_annot_folder ]; then
		exit
	fi
	if [ ! -d ./darknet ]; then
		#git clone https://github.com/pjreddie/darknet
		git clone https://github.com/AlexeyAB/darknet
		cd ./darknet
		echo "Enabling OpenMP..."
		sed -i '/OPENMP[=]0/c\OPENMP=1' ./Makefile
		echo "Enabling OpenCV..."
		sed -i '/OPENCV[=]0/c\OPENCV=1' ./Makefile
		echo "Enabling AVX...  ( turn off if this creates errors... )"
		sed -i '/AVX[=]0/c\AVX=1' ./Makefile

		echo "Edit the yolo3trainer to enable CUDA as well when needed" # or detect that somehow
		make
		cd ../
	fi
	cd ./darknet
	
	if [ -d ./gen/voc_label ]; then
		if [ ! -d ./gen/pretrained ]; then
			mkdir ./gen/pretrained
		fi
		if [ -d ./gen/voc_label/pretrained ]; then
			mv ./gen/voc_label/pretrained/* ./gen/pretrained
		fi
		rm -rdf ./gen/voc_label
	fi
	mkdir -p ./gen/voc_label
	cd ./gen/voc_label

	readNameCollection
	findClasses
	echo "collection name set to '${nameCollection}'"

	echo "import xml.etree.ElementTree as ET" 							> ./voc_label.py
	echo "import pickle" 										>> ./voc_label.py
	echo "import os" 										>> ./voc_label.py
	echo "from os import listdir, getcwd" 								>> ./voc_label.py
	echo "from os.path import join" 								>> ./voc_label.py
	echo "" 											>> ./voc_label.py
	echo "sets=[('${nameCollection}', 'train'), ('${nameCollection}', 'valid')]"			>> ./voc_label.py
	echo "" 											>> ./voc_label.py
	echo "classes = [${classes}]"									>> ./voc_label.py
	echo ""												>> ./voc_label.py
	echo "def convert(size, box):" 									>> ./voc_label.py
	echo "    dw = 1./size[0]" 									>> ./voc_label.py
	echo "    dh = 1./size[1]" 									>> ./voc_label.py
	echo "    x = (box[0] + box[1])/2.0" 								>> ./voc_label.py
	echo "    y = (box[2] + box[3])/2.0" 								>> ./voc_label.py
	echo "    w = box[1] - box[0]" 									>> ./voc_label.py
	echo "    h = box[3] - box[2]" 									>> ./voc_label.py
	echo "    x = x*dw" 										>> ./voc_label.py
	echo "    w = w*dw" 										>> ./voc_label.py
	echo "    y = y*dh" 										>> ./voc_label.py
	echo "    h = h*dh" 										>> ./voc_label.py
	echo "    return (x,y,w,h)" 									>> ./voc_label.py
	echo ""												>> ./voc_label.py	
	echo "def convert_annotation(dbName, image_set, image_id):"					>> ./voc_label.py
	echo "    in_file = open('gen/%s/%s_annot_folder/%s.xml'%(dbName, image_set, image_id))"	>> ./voc_label.py
	echo "    out_file1 = open('gen/%s/labels/%s.txt'%(dbName, image_id), 'w')"			>> ./voc_label.py
	echo "    out_file2 = open('gen/%s/%s_image_folder/%s.txt'%(dbName, image_set, image_id), 'w')"	>> ./voc_label.py
	echo "    tree=ET.parse(in_file)"								>> ./voc_label.py
	echo "    root = tree.getroot()"								>> ./voc_label.py
	echo "    size = root.find('size')"								>> ./voc_label.py
	echo "    w = int(size.find('width').text)"							>> ./voc_label.py
	echo "    h = int(size.find('height').text)"							>> ./voc_label.py
	echo "    "											>> ./voc_label.py
	echo "    for obj in root.iter('object'):"							>> ./voc_label.py
	echo "        difficult = obj.find('difficult').text"						>> ./voc_label.py
	echo "        cls = obj.find('name').text"							>> ./voc_label.py
	echo "        if cls not in classes or int(difficult) == 1:"					>> ./voc_label.py
	echo "            continue"									>> ./voc_label.py
	echo "        cls_id = classes.index(cls)"							>> ./voc_label.py
	echo "        xmlbox = obj.find('bndbox')"							>> ./voc_label.py
	echo "        b = (float(xmlbox.find('xmin').text), float(xmlbox.find('xmax').text), float(xmlbox.find('ymin').text), float(xmlbox.find('ymax').text))"									>> ./voc_label.py
	echo "        bb = convert((w,h), b)"								>> ./voc_label.py
	echo "        out_file1.write(str(cls_id) + \" \" + \" \".join([str(a) for a in bb]) + '\n')"	>> ./voc_label.py
	echo "        out_file2.write(str(cls_id) + \" \" + \" \".join([str(a) for a in bb]) + '\n')"	>> ./voc_label.py
	echo ""												>> ./voc_label.py
	echo "wd = getcwd()"										>> ./voc_label.py
	echo ""												>> ./voc_label.py
	echo "for dbName, image_set in sets:"								>> ./voc_label.py
	echo "    if not os.path.exists('gen/%s/labels/'%(dbName)):"					>> ./voc_label.py
	echo "        os.makedirs('gen/%s/labels/'%(dbName))"						>> ./voc_label.py
	echo "    "											>> ./voc_label.py
	echo "    image_ids = os.listdir('./gen/%s/%s_image_folder/'%(dbName, image_set))"		>> ./voc_label.py
	echo "    list_file = open('%s_%s.txt'%(dbName, image_set), 'w')"				>> ./voc_label.py
	echo "    for image_id_w_ext in image_ids:"							>> ./voc_label.py
	echo "        image_id=\".\".join(image_id_w_ext.split(\".\")[:-1])"				>> ./voc_label.py
	echo "        list_file.write('%s/gen/%s/%s_image_folder/%s.jpg\n'%(wd, dbName, image_set, image_id))"	>> ./voc_label.py
	echo "        convert_annotation(dbName, image_set, image_id)"					>> ./voc_label.py
	echo "    list_file.close()"									>> ./voc_label.py
	chmod u+x ./voc_label.py

	mkdir ./gen

	echo "copying image/xml files..."
	cp -r "${CurrentWd}"/data/${genDir} ./gen/${nameCollection}

	echo "generating .txt files..."
	python3 ./voc_label.py

	mkdir -p ./gen/${nameCollection}/cfg

	trainPath="${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/cfg/train.txt"
	evalPath="${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/cfg/valid.txt"
	classesPath="${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/cfg/names.names"
	cfgPath="${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/cfg/input.data"
	pretrainedLayersNamePath="${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/cfg/pretrainedLayer.txt"
	backupDir="${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/backup"
	trainingConfigPath="${CurrentWd}/darknet_${sourceTrainingTypeConfig}"

	mv ./${nameCollection}_train.txt ${trainPath}
	mv ./${nameCollection}_valid.txt ${evalPath}

	# create .names file
	echo "creating ${nameCollection}.names..."
	numClasses=0
	if [ -f $classesPath ]; then
		rm $classesPath
	fi
	while true; do
		numClasses=$((numClasses+1))
		class=$(cut -d',' -f${numClasses} <<<${classes} | xargs)
		if [ -z "$class" ]; then
			numClasses=$((numClasses-1))
			break
		fi
		echo "${class}" >> $classesPath
	done
	echo "num classes found: ${numClasses}"

	cp ../../cfg/voc.data ${cfgPath}

	echo "${pretrainedWeightsLayer}" > ${pretrainedLayersNamePath}
	
	# setup learning conf
	tempConfPath="${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/cfg/temp.cgf"
	cp ../../cfg/${sourceTrainingTypeConfig} ${tempConfPath}

	sed -i '/classes[=]/c\classes='${numClasses} ${tempConfPath}


	if [ "${trainingType}" == "yolov3_tiny" ]; then
		# anchors must be smaller than image size
		#max_batches=8000    = ( to (classes*2000 but not less than 4000) )
		#steps=6400,7200     = change line steps to 80% and 90% of max_batches
		#filters=27          = (num/3)*(numClasses+5)	
		#num=6               = num anchors

		# TODO: Calculate anchors : 	./darknet detector calc_anchors /home/jvandis/projects/MoneyCounter/Yolo3Trainer/darknet/gen/voc_label/gen/coins/cfg/input.data -num_of_clusters 9 -width 416 -height 416

		maxBatches=$((numClasses*2000))
		steps_1=$((maxBatches*100/125)) # 80% of 'maxBatches'
		steps_2=$((maxBatches*100/111)) # 90% of 'maxBatches'
		num=6 # num anchors  ( be sure 'anchors=' matches that )
		filters=$((3*(numClasses+5)))
		batch=64
		subdivisions=16
		sed -i '/max_batches.*[=]/c\max_batches='${maxBatches} ${tempConfPath}
		sed -i '/steps.*[=]/c\steps='${steps_1}','${steps_2} ${tempConfPath}
		sed -i '/num.*[=]/c\num='${num} ${tempConfPath}

		commentedBatch=$(cat ${tempConfPath} | grep -n "batch=" | grep "#" | awk -F ':' '{print $1}')
		commentedSubdivisions=$(cat ${tempConfPath} | grep -n "subdivisions=" | grep "#" | awk -F ':' '{print $1}')
		uncommentedBatch=$(cat ${tempConfPath} | grep -n "batch=" | grep -v "#" | awk -F ':' '{print $1}')
		uncommentedSubdivisions=$(cat ${tempConfPath} | grep -n "subdivisions=" | grep -v "#" | awk -F ':' '{print $1}')

		sed -i ''${uncommentedBatch}'s/.*/batch='${batch}'/' ${tempConfPath}
		sed -i ''${uncommentedSubdivisions}'s/.*/subdivisions='${subdivisions}'/' ${tempConfPath}
		sed -i ''${commentedBatch}'s/.*/#batch=1/' ${tempConfPath}
		sed -i ''${commentedSubdivisions}'s/.*/#subdivisions=1/' ${tempConfPath}

		previousFilterLineNumber=0
		while read -r result
		do
			lineNumber=$(echo ${result} | awk -F ':' '{print $1}')
			lineValue=$(echo ${result} | awk -F ':' '{print $2}')
			if [[ "${lineValue}" == "filters="* ]]; then
				previousFilterLineNumber=${lineNumber}
			else
				if [[ ! "${previousFilterLineNumber}" == "0" ]]; then
					sed -i ''${previousFilterLineNumber}'s/.*/filters='${filters}'/' ${tempConfPath}
				else
					echo "error: found no filter before the 'classes' line in '${sourceTrainingTypeConfig}'"
					exit
				fi
			fi
		done <<< $(cat ${tempConfPath} | grep -n "classes\|filters")

	elif [ "${trainingType}" == "yolov3" ]; then
		# anchors must be smaller than image size
		#max_batches=8000    = ( to (classes*2000 but not less than 4000) )
		#steps=6400,7200     = change line steps to 80% and 90% of max_batches
		#filters=27          = (num/3)*(numClasses+5)	
		#num=9               = num anchors

		maxBatches=$((numClasses*2000))
		steps_1=$((maxBatches*100/125)) # 80% of 'maxBatches'
		steps_2=$((maxBatches*100/111)) # 90% of 'maxBatches'
		num=9 # num anchors  ( be sure 'anchors=' matches that )
		filters=$(((num/3)*(numClasses+5)))
		batch=64
		subdivisions=16
		sed -i '/max_batches.*[=]/c\max_batches='${maxBatches} ${tempConfPath}
		sed -i '/steps.*[=]/c\steps='${steps_1}','${steps_2} ${tempConfPath}
		sed -i '/num.*[=]/c\num='${num} ${tempConfPath}

		commentedBatch=$(cat ${tempConfPath} | grep -n "batch=" | grep "#" | awk -F ':' '{print $1}')
		commentedSubdivisions=$(cat ${tempConfPath} | grep -n "subdivisions=" | grep "#" | awk -F ':' '{print $1}')
		uncommentedBatch=$(cat ${tempConfPath} | grep -n "batch=" | grep -v "#" | awk -F ':' '{print $1}')
		uncommentedSubdivisions=$(cat ${tempConfPath} | grep -n "subdivisions=" | grep -v "#" | awk -F ':' '{print $1}')

		sed -i ''${uncommentedBatch}'s/.*/batch='${batch}'/' ${tempConfPath}
		sed -i ''${uncommentedSubdivisions}'s/.*/subdivisions='${subdivisions}'/' ${tempConfPath}
		sed -i ''${commentedBatch}'s/.*/#batch=1/' ${tempConfPath}
		sed -i ''${commentedSubdivisions}'s/.*/#subdivisions=1/' ${tempConfPath}

		previousFilterLineNumber=0
		while read -r result
		do
			lineNumber=$(echo ${result} | awk -F ':' '{print $1}')
			lineValue=$(echo ${result} | awk -F ':' '{print $2}')
			if [[ "${lineValue}" == "filters="* ]]; then
				previousFilterLineNumber=${lineNumber}
			else
				if [[ ! "${previousFilterLineNumber}" == "0" ]]; then
					sed -i ''${previousFilterLineNumber}'s/.*/filters='${filters}'/' ${tempConfPath}
				else
					echo "error: found no filter before the 'classes' line in '${sourceTrainingTypeConfig}'"
					exit
				fi
			fi
		done <<< $(cat ${tempConfPath} | grep -n "classes\|filters")
	else
		echo "unknown training type: '${trainingType}'"
		exit
	fi

	trainingConfigFileName=$(ls "${CurrentWd}" | grep [.]cfg)
	copyNewConfig="y"
	if [ ! -z "${trainingConfigFileName}" ]; then
		configFileSum1=`md5sum ${CurrentWd}/${trainingConfigFileName} | awk -F ' ' '{print $1}'`
		configFileSum2=`md5sum ${tempConfPath} | awk -F ' ' '{print $1}'`

		if [ "$configFileSum1" = "$configFileSum2" ]; then
			# same content ( nothing manually changed )
			copyNewConfig="n"
		elif [ "${3}" == "n" ]; then
			copyNewConfig="n"
		else
			echo "replace existing '${trainingConfigFileName}' with generated 'darknet_${sourceTrainingTypeConfig}' config?"
			echo "y/n:"
			read yOrN
			if [ "${yOrN}" == "y" ]; then
				rm ${CurrentWd}/${trainingConfigFileName}
				copyNewConfig="y"
			else
				copyNewConfig="n"
			fi
		fi
	fi

	if [[ "${copyNewConfig}" == "y" ]]; then
		cp ${tempConfPath} ${trainingConfigPath}
		echo "'${trainingConfigPath}' updated"
	fi
	rm ${tempConfPath}

	#setup config.data
	echo "copying & updating 'config.data'..."
	
	sed -i '/classes.*[=]/c\classes = '${numClasses} ${cfgPath}
	sed -i '/train.*[=]/c\train = '${trainPath} ${cfgPath}
	sed -i '/valid.*[=]/c\valid = '${evalPath} ${cfgPath}
	sed -i '/names.*[=]/c\names = '${classesPath} ${cfgPath}
	sed -i '/backup.*[=]/c\backup = '${backupDir} ${cfgPath}

	if [ ! -d ${backupDir} ]; then
		mkdir -p ${backupDir}
	fi

	# setup pre-trained weights
	cd ${CurrentWd}/darknet/gen/voc_label/
	PreTrainedDir=${CurrentWd}/darknet/gen/voc_label/pretrained
	if [ ! -f ./pretrained/${pretrainedWeightsFile} ]; then
		if [ -f ../pretrained/${pretrainedWeightsFile} ]; then
			mkdir ./pretrained
			mv ../pretrained/* ./pretrained
			rm -rdf ../pretrained
		else
			echo "Downloading pretrained convolutional weights..."
			mkdir ./pretrained
			cd ./pretrained
			wget https://pjreddie.com/media/files/${pretrainedWeightsFile}
			cd ../
		fi
		if [[ "${pretrainedWeightsFile}" == *".weights" ]]; then
			cd ${CurrentWd}/darknet
			echo "extracting pretrained layer..."
			./darknet partial ${CurrentWd}/darknet/cfg/${sourceTrainingTypeConfigPretrained} ${PreTrainedDir}/${pretrainedWeightsFile} ${PreTrainedDir}/${pretrainedWeightsLayer} ${pretrainedWeightsLayerIndex}
			cd ${CurrentWd}/darknet/gen/voc_label/
		fi
	fi

	# resize
	cd ${CurrentWd}/darknet/gen/voc_label/
	targetImageWidth=$(cat ${trainingConfigPath} | grep width[=] | head -1 | awk -F '=' '{print $2}')
	targetImageHeight=$(cat ${trainingConfigPath} | grep height[=] | head -1 | awk -F '=' '{print $2}')
	

	echo "resizing images according to learning conf. (${targetImageWidth}x${targetImageHeight}) ignoring aspect ratio"
	cd ${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/train_image_folder	
	numTrainingImages=0
	currentNumTrainingImage=0
	for f in *.jpg ; do
		numTrainingImages=$((numTrainingImages+1))
	done
	cd ${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/valid_image_folder
	numValidationImages=0
	currentNumValidationImage=0
	for f in *.jpg ; do
		numValidationImages=$((numValidationImages+1))
	done


	numTotalImagesToResize=$((numTrainingImages+numValidationImages))
	totalImageIndex=0
	cd ${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/train_image_folder	
	for f in *.jpg ; do
		mogrify -resize ${targetImageWidth}x${targetImageHeight}\! ${f}
		printf "\r(${totalImageIndex}/${numTotalImagesToResize}) training images: ${currentNumTrainingImage}, validation images: ${currentNumValidationImage}"
		totalImageIndex=$((totalImageIndex+1))
		currentNumTrainingImage=$((currentNumTrainingImage+1))
	done;
	cd ${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/valid_image_folder
	for f in *.jpg ; do
		mogrify -resize ${targetImageWidth}x${targetImageHeight}\! ${f}
		printf "\r(${totalImageIndex}/${numTotalImagesToResize}) training images: ${currentNumTrainingImage}, validation images: ${currentNumValidationImage}"
		totalImageIndex=$((totalImageIndex+1))
		currentNumValidationImage=$((currentNumValidationImage+1))
	done;
	echo ""
	
	echo "done!"

elif [ "${1}" == "cv" ]; then
	if [ ! -d ./darknet/gen/voc_label ]; then
		echo "run 'yolo3trainer.sh -cs' first."
		exit
	fi

	cd ./darknet
	if [ ! -d ./Yolo_mark ]; then
		mkdir ./Yolo_mark
		cd ./Yolo_mark
		git clone https://github.com/AlexeyAB/Yolo_mark.git
		cd ./Yolo_mark
		mkdir ./build
		cd ./build
		cmake ../
		make	
		cd ../../../
	fi
	readNameCollection
	collectionFolder=${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}
	echo "checking 'train' images"
	./Yolo_mark/Yolo_mark/build/yolo_mark ${collectionFolder}/train_image_folder ${collectionFolder}/cfg/train.txt ${collectionFolder}/cfg/names.names
	echo "checking 'valid' images"
	./Yolo_mark/Yolo_mark/build/yolo_mark ${collectionFolder}/valid_image_folder ${collectionFolder}/cfg/valid.txt ${collectionFolder}/cfg/names.names


elif [ "${1}" == "cl" ]; then

	if [ ! -d ./darknet/gen/voc_label ]; then
		echo "run 'yolo3trainer.sh -cs' first."
		exit
	fi

	echo "starting to learn..."
	cd ./darknet

	readNameCollection

	inputConfigPath="${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/cfg/input.data"
	pretrainedLayersNamePath="${CurrentWd}/darknet/gen/voc_label/gen/${nameCollection}/cfg/pretrainedLayer.txt"
	pretrainedWeightsLayer=$(cat ${pretrainedLayersNamePath} | head -1)
	trainingConfigBasePath="${CurrentWd}"
	pretrainedWeightsPath="${CurrentWd}/darknet/gen/voc_label/pretrained/${pretrainedWeightsLayer}"
	trainingConfigFileName=$(ls "${CurrentWd}" | grep [.]cfg)
	trainingConfigPath="${trainingConfigBasePath}/${trainingConfigFileName}"

	#TODO: Sanity check:	

	# https://github.com/AlexeyAB/darknet#how-to-train-to-detect-your-custom-objects

	# anchors must be smaller than image size
	#max_batches=8000    = ( to (classes*2000 but not less than 4000) )
	#steps=6400,7200     = change line steps to 80% and 90% of max_batches
	#filters=27          = (num/3)*(numClasses+5)	
	#num=9               = num anchors

	echo "as long as 'loss' is not NaN, then everything is ok."
	echo "open 'http://localhost:8090' to see the progression"
	if [ ! -d ./workingDir ]; then
		mkdir ./workingDir
	fi
	cd ./workingDir # attempt to store the 'aug_...jpg' files in working dir but failed... leaving it here anyway 
	#../darknet detector train ${inputConfigPath} ${trainingConfigPath} ${pretrainedWeightsPath} -dont_show -map -show_imgs
	../darknet detector train ${inputConfigPath} ${trainingConfigPath} ${pretrainedWeightsPath} -map
else
	printHelp="true"
fi

if [ "${printHelp}" == "true" ]; then
	echo ""
	echo "usage:"
	echo "  'yolo3trainer.sh p'   =  load custom images"
	echo ""
	echo "  'yolo3trainer.sh cs yolov3'       =  [C++ Darknet] configure learning config - yolov3"
	echo "  'yolo3trainer.sh cs yolov3_tiny'  =  [C++ Darknet] configure learning config - yolov3-tiny"
	echo "  'yolo3trainer.sh cv'              =  [C++ Darknet] verify labels"
	echo "  'yolo3trainer.sh cl'              =  [C++ Darknet] start learning"
	echo ""
	#echo "  'yolo3trainer.sh -ps'  =  [Python]      auto-configure learning config"
	#echo "  'yolo3trainer.sh -pl'  =  [Python]      start learning"
	#echo "  'yolo3trainer.sh -pa'  =  [Python]      display anchors of current config"
	#echo "  'yolo3trainer.sh -pr'  =  [Python]      reset state"
	echo ""
fi





