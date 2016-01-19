APKFILE="";
KEYSTOREFILE="";
SCRIPTPATH="";
KEYSTORE_FILENAME="";
APK_FILENAME="";

function init {
	pushd `dirname $0` > /dev/null
	SCRIPTPATH=`pwd`
	popd > /dev/null

	cd SCRIPTPATH;

	ECHO "Welcome to APK signing";
}

function validateAndroidSDK {
	ECHO "VERYFING ANDROID SDK INSTALLATION";

	command -v jarsigner >/dev/null 2>&1 || { 
		echo >&2 "Android SDK has not been insalled properly. Please install the Android SDK and add the build and platformtools to your PATH variable";
		exit 1;
	}

	ECHO "ANDROID SDK PRESENT";
}

function checkKeystore {
	ECHO "LOOKING FOR KEYSTORE";
	read -r -p "Do you have a keystore present? [y/N] " keyStorePresent
	if [[ $keyStorePresent =~ ^([yY][eE][sS]|[yY])$ ]]
	then
	    validateKeystore;
	else
	    createKeystore;
	fi
}

function createKeystore {
	read -r -p "Would you like to create a keystore? [y/N] " keyStorePresent
	if [[ $keyStorePresent =~ ^([yY][eE][sS]|[yY])$ ]]
	then
		ECHO "Ooooh yes we are going to create one real good!";
	else
	    ECHO "You have chosen not to create a keystore. I can not continue without one. Exiting.";
	    exit 1;
	fi

	if [ ! -d $SCRIPTPATH"/files" ]
		then
			mkdir $SCRIPTPATH"/files";
	fi

	cd $SCRIPTPATH"/files";

	ECHO "Please enter a name for your keystore file (without .keystore extension): ";
	read name;

	ECHO "Please enter the alias you want to use for your keystore";
	read aliasName;

	fullName=$name".keystore";
	keytool -genkey -alias "$aliasName" -v -keystore "$fullName" -keyalg RSA -keysize 2048 -validity 10000

	if [ $? -eq 0 ];
	then
		ECHO "Keystore created successfully. Continuing!";
		KEYSTOREFILE=$SCRIPTPATH"/files/"$fullName;
		KEYSTORE_FILENAME=$fullName;
		jarSign;
	else
		ECHO "Keystore creation failed. Please restart the program";
		exit 1;
	fi
}

function validateKeystore {
	ECHO "Please enter the name of your keystore (must be located in /files): ";
	read keystoreFileName;
	finalKeystore=$SCRIPTPATH"/files/"$keystoreFileName;

	if [ ! -f $finalKeystore ];
		then
		    ECHO "Keystore has not been found. Please check your file and restart the prompt.";
		else
		    ECHO "Keystore is found and valid. Continuing!";
		    KEYSTOREFILE=$finalKeystore;
		    KEYSTORE_FILENAME=$keystoreFileName;
		    jarSign;
	fi
}

function jarSign {
	read -r -p "Would you like to sign an app? [y/N] " signMe
		if [[ $signMe =~ ^([yY][eE][sS]|[yY])$ ]]
			then
				ECHO "Woohoo. Lets go signing!";
			else
			    ECHO "Thanks for playing. Bybye!";
			    exit 1;
		fi

	ECHO "Please enter your unsigned apk name (with .apk extension): ";
	read apkName;
	ECHO "APK name: $apkName";
	finalAPK=$SCRIPTPATH"/files/"$apkName;

	if [ ! -f $finalAPK ];
		then
			ECHO "File $apkName not found. I need an APK to sign you doofus! Please find yours and place it in /files folder";
			exit 1;
		else
			ECHO "Found your APK! Lets go sign that sun' b****!";
			APKFILE=$finalAPK;
			APK_FILENAME=$apkName;
	fi

	ECHO "Please provide an alias for the signer: ";
	read apkAlias;

	cd $SCRIPTPATH"/files";
	jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE_FILENAME $APK_FILENAME $apkAlias;

	if [ $? -eq 0 ];
	then
		ECHO "SIGNED. Lets align that zipper and then we're done!";
		zip;
	else
		ECHO "Something went wrong with signing. Running verbose to give you info on what went wrong. But, you're on your own after that!";
		jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE_FILENAME $APK_FILENAME $apkAlias;
		exit 1;
	fi
}

function zip {
	ECHO "Please enter the name your signed and zipaligned apk should carry (without .apk please!): ";
	read fileName;

	cd $SCRIPTPATH"/files";
	zipalign -v 4 $APKFILE $fileName".apk";

	if [ $? -eq 0 ];
	then
		ECHO "SIGNED. Lets align that zipper and then we're done!";
		zip;
	else
		ECHO "Something went wrong with the zipper. Hope it didn't get stuck in something :x. Running verbose to give you info on what went wrong. But, you're on your own after that!";
		zipalign -v 4 $APKFILE $fileName".apk";
		exit 1;
	fi

	ECHO "All done! Happy release :)";
}

init;
validateAndroidSDK;
checkKeystore;