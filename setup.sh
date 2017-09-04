#!/bin/bash

# switch to root
cd ~

echo "Welcome to the setup of your home made Google Home!"

# Pre : the first thing to start the script 
# Post: check whether there is internet connection by testing Google.com, then update dependency
#		when available
checkInternet(){
	echo "Checking Internet....."

	wget -q --spider www.google.com

	if [ $? -eq 0 ]
	then
		echo "Internet connection OK, updating dependencies"
		#sudo apt-get update
	else
		# so if no internet
		read -p "Please check your internet connection. enter Y when done..... " response
		#read -r response
		if [ $response = "Y" ] || [ $response = "y" ]
		then
			checkInternet
		else
			exit 1
		fi
	fi # end of if statement
}

# Pre : whenever need to suggest users to adjust volumn of the speaker or mic
# Post: will bring up the alsamixer
AdjustVolumn(){
	read -p "Wanna to adjust volumn? (Y/N)" response
	if [ $response = "Y" ] || [ $response = "y" ]
	then
		alsamixer
	fi
}

# Pre : After the internt is secured, start testing audio input and output
# Post: make the correct audio config for user
AudioConfig(){
	echo "Start configuring audio devices....."

	# if any audio test failed
	testFail=false

	# start playing test sound for a 5 rounds
	retry=true
	while [ $retry = true ]
	do
		echo "Testing speakers...."
		speaker-test -l 5 -t wav
		AdjustVolumn
		read -p "Wanna try again? (Y/N)" response
		if [ $response = "Y" ] || [ $response = "y" ]
		then
			retry=true
		else
			retry=false
		fi
	done

	# need valid response before next step
	validResponse=false
	while [ $validResponse = false ]
	do
		read -p "Can you hear anything? (Y/N) " response
		if [ $response = "N" ] || [ $response = "n" ]
		then
			testFail=true
			validResponse=true
		elif [ $response = "Y" ] || [ $response = "y" ]
		then
			validResponse=true
		fi
	done

	# start mic testing
	retry=true
	while [ $retry = true ]
	do
		echo "Testing mic...."
		arecord --format=S16_LE --duration=5 --rate=16000 --file-type=raw out.raw
		aplay --format=S16_LE --rate=16000 out.raw
		AdjustVolumn		
		read -p "Wanna try again? (Y/N)" response
		if [ $response = "Y" ] || [ $response = "y" ]
		then
			retry=true
		else
			retry=false
		fi
	done

	# need valid response before next step
	validResponse=false
	while [ $validResponse = false ]
	do
		read -p "Does the mic work? (Y/N) " response
		if [ $response = "N" ] || [ $response = "n" ]
		then
			testFail=true
			validResponse=true
		elif [ $response = "Y" ] || [ $response = "y" ]
		then
			validResponse=true
		fi
	done

	# things to do if one of the audio device failed
	if [ $testFail = true ]
	then
		echo "Now you need to configure your audio device settings....."
		# find targeted speaker
		echo "Here are a list of speaker devices..."
		aplay -l
		while [[ $((speakerCard)) != $speakerCard ]] || [[ $((speakerDevice)) != $speakerDevice ]]
		do
			read -p "What is the card number you want to use? (on board port goes for 0, external sound card mostly 1) " speakerCard
			read -p "What is the device number you want to use? (on board port goes for 1, external sound card mostly 0) " speakerDevice
		done

		# find targeted mic
		echo "Here are a list of mic devices..."
		arecord -l
		while [[ $((micCard)) != $micCard ]] || [[ $((micDevice)) != $micDevice ]]
		do
			read -p "What is the card number you want to use? (on board port goes for 0, external sound card mostly 1) " micCard
			read -p "What is the device number you want to use? (on board port goes for 1, external sound card mostly 0) " micDevice
		done

		# clear the previous bad config
		rm -f /home/pi/.asoundrc
		# make .asoundrc in root
		touch /home/pi/.asoundrc
		echo "pcm.!default {
  type asym
  capture.pcm \"mic\"
  playback.pcm \"speaker\"
}
pcm.mic {
  type plug
  slave {
    pcm \"hw:${micCard},${micDevice}\"
  }
}
pcm.speaker {
 type plug
 slave {
 pcm \"hw:${speakerCard},${speakerDevice}\"
 }
}" >> /home/pi/.asoundrc

		# rerun the config
		echo "Start re-configure"
		AudioConfig
	else
		# clean up leftover files
		sudo rm -f out.raw
	fi
}

checkInternet

AudioConfig