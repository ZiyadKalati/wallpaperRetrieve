#!/bin/bash

pathToHere=$(dirname "$0")
client_id=$(cat $pathToHere/credentials-public.json | jq -r '.client_id')
client_secret=$(cat $pathToHere/credentials-public.json | jq -r '.client_secret')

accessTokenUrl="https://www.deviantart.com/oauth2/token?grant_type=client_credentials -d client_id=$client_id -d client_secret=$client_secret"
token=$(curl -s -S $accessTokenUrl | jq -r '.access_token')
sleep 2

endpointBaseUrl="https://www.deviantart.com/api/v1/oauth2"
endPGalleryAll="/gallery/all"
endPUserFriends="/user/friends"

allFriends=$(curl -s -S -H "Authorization: Bearer $token" "$endpointBaseUrl$endPUserFriends/$1?mature_content=true")
friends=($(echo $allFriends | jq -r '.results | .[] | .user | .username' ))
sleep 2

# Check if a downloads directory was given. If not then use directory of this bash file
if [ ! -z $2 ]
then
    imgDir="$2/newWalls"
else
    imgDir="$pathToHere/newWalls"
fi

landscape="/landscape"
portrait="/portrait"

for friend in ${friends[*]}
do
    results=$(curl -s -S -H "Authorization: Bearer $token" "$endpointBaseUrl$endPGalleryAll?username=$friend&mature_content=true")
    sleep 2
    echo "Downloading art by $friend..."
    publishedTimes=($(echo $results | jq -r '.results | .[] | .published_time'))
    
    # This while loop exists to make sure the rate limit of our requests has not been reached and to back off for 5 mins
    # if it has been reached before continuing
    while [ -z "$publishedTimes" ]
    do
        echo "Service is temporarily unavailable. Will re-try in 5 minutes."
        sleep 300
        results=$(curl -s -S -H "Authorization: Bearer $token" "$endpointBaseUrl$endPGalleryAll?username=$friend&mature_content=true")
	publishedTimes=($(echo $results | jq -r '.results | .[] | .published_time'))
    done

    if [ ! -s $pathToHere/tmp.json ]
    then
	jq -n "{\"$friend\":${publishedTimes[0]}}" > $pathToHere/tmp.json
    else
	jq -n "{\"$friend\":${publishedTimes[0]}} + $(cat $pathToHere/tmp.json)" > $pathToHere/tmptmp.json
	cp $pathToHere/tmptmp.json $pathToHere/tmp.json
    fi

    imgSrc=($(echo $results | jq -r '.results | .[] | .content | .src'))
    imgWidths=($(echo $results | jq -r '.results | .[] | .content | .width'))
    imgHeights=($(echo $results | jq -r '.results | .[] | .content | .height'))
    if [ -s $pathToHere/lastDownloads.json ]
    then
	if [ $(cat $pathToHere/lastDownloads.json | jq "has(\"$friend\")") == true ]
	then
	    latestDeviationTime=$(cat $pathToHere/lastDownloads.json | jq -r ".\"$friend\"")
	else
	    latestDeviationTime=0
	fi
    else
	touch $pathToHere/lastDownloads.json
	latestDeviationTime=0
    fi
    
    sleep 2
    ctr=0
    for i in ${imgSrc[*]}
    do
	if [ $latestDeviationTime -ge ${publishedTimes[$ctr]} ]
	then
	    break
	fi
            #get image height and width
            #if width is larger go to landcape directory
            #elif width is smaller then go to portrait directory
            #else download to both directories

	width=${imgWidths[$ctr]}
	height=${imgHeights[$ctr]}
	if [ $width -gt $height ]
	then
	    wget -q -P $imgDir$landscape --header="Authorization: Bearer $token" "$i"
	elif [ $width -lt $height ]
	then
	    wget -q -P $imgDir$portrait --header="Authorization: Bearer $token" "$i"
	else
	    wget -q -P $imgDir$landscape --header="Authorization: Bearer $token" "$i"
	    sleep 2
	    wget -q -P $imgDir$portrait --header="Authorization: Bearer $token" "$i"
	fi
	    
	ctr=$((ctr+1))
	sleep 2
	     #if the publication time of last downloaded image is not less than the current one means
	     #we have downloaded the image before and every image coming after it in the gallery has
	     #also been downloaded before. So we simply skip to the next artist because we have all
             #the most recent images for this current artist
    done

    if [ -s $pathToHere/lastDownloads.json ]
    then
        if [ $(cat $pathToHere/lastDownloads.json | jq "has(\"$friend\")") == true ]
        then
	    cat $pathToHere/lastDownloads.json | jq ".\"$friend\" = ${publishedTimes[0]}" > $pathToHere/tmptmp.json
	    cp $pathToHere/tmptmp.json $pathToHere/lastDownloads.json
        else
            cat $pathToHere/lastDownloads.json | jq ". + $(cat $pathToHere/tmp.json)" > $pathToHere/tmptmp.json
	    cp $pathToHere/tmptmp.json $pathToHere/lastDownloads.json
        fi
    else 
        cat $pathToHere/tmp.json > $pathToHere/lastDownloads.json
    fi

    fileName=($(find . | grep [\w]*.png))
    fileName=($(basename -- ${imgSrc[*]}))

    for i in ${fileName[*]}
    do
	imgName="${i%.*}"
	imgExt="${i##*.}" #Extension
	desiredExt="jpg"
	
	landscapePath=$imgDir$landscape/
	portraitPath=$imgDir$portrait/
	if [ $imgExt != $desiredExt ]
	then
	    if [ -s $landscapePath$imgName.$imgExt ]
	    then
		convert $landscapePath$imgName.$imgExt $landscapePath$imgName.$desiredExt
		rm $landscapePath$imgName.$imgExt
	    elif [ -s $portraitPath$imgName.$imgExt ]
            then
		convert $portraitPath$imgName.$imgExt $portraitPath$imgName.$desiredExt
		rm $portraitPath$imgName.$imgExt
	    fi
	fi
    done

    printf "Done.\n\n" # To notify the user that all art by $friend has been downloaded

done
rm $pathToHere/tmptmp.json $pathToHere/tmp.json