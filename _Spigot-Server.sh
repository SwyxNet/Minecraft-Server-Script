# Verison du script
scriptVersion='2.0.0'

if [ ! -e config.yml ]
then
	echo "#Configuration
# Minecraft Spigot Used version
buildVersion=latest
# Dedicated Memory for the server
dedicatedRam='2G'
# Source of the Build Tools Build.
spigotSource='https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar'
# sftp user
sftpUser='default'
# sftp password
sftpPassword='default'
# sftp server
sftpServer='default'
# Initialisation des variables
autonomous=0
#End of configuration
" > config.yml
fi



source config.yml
showHelp()
{
	echo ""
	echo ""
	echo -e "\e[96m
	Spigot MC Easy Script by Swyx
	\e[39m"
	echo -e "\e[96m
	Version $scriptVersion
	\e[39m"
	echo -e "\e[96m
	Powered by Spigot, High Performance Minecraft Server
	https://www.spigotmc.org/

	Source of BuildTools.jar :
	$spigotSource
	\e[39m"
	echo -e "\e[96m
	Allowed Args
	\e[39m"
	echo -e "\e[96m
	-u or --update // Updates the build, then launches the server
	-c or --clean // Deletes builds folders
	-i or --install // Installs the servers pre requisits (start once)
	-a or --full-backup // Saves th full server in /home/pi/Minecraft/Backup folder
	-r or --runautonomous // Runs the server in perpetual mode
	-h or --help // Shows basic Help
	\e[39m"
	echo ""
	echo -e "\e[96m
	Spigot Target build bersion $buildVersion
	# You can edit this value by editing the _Spigot-Server.sh Config section
	\e[39m"
	echo -e "\e[96m
	Server allocated Memory $dedicatedRam
	# You can edit this value by editing the _Spigot-Server.sh Config section
	\e[39m"

	echo ""
}

maintenance()
{
	echo "
	_
	__
	___ Maintenance menu
	__
	_
	"

	PS3='>: '
    options=("Mettre à jour vers $buildVersion" "Archiver le serveur" "Pousser les backups sur un serveur distant" "Nettoyer le repertoire Build (corriger des problemes de droits lors de la MAJ" "Installer les pre-requis" "Afficher la configuration" "Purger les Backups" "Supprimer le serveur" "Menu Principal")
    select opt in "${options[@]}"
    do
        case $opt in
            "Mettre à jour vers $buildVersion")
                updateServer
                maintenance
		break
                ;;
            "Archiver le serveur")
                backupServer
                maintenance
		break
                ;;
            "Pousser les backups sur un serveur distant")
                pushBackup
                maintenance
		break                ;;
            "Nettoyer le repertoire Build (corriger des problemes de droits lors de la MAJ")
                cleanServer
                maintenance
		break
                ;;
            "Installer les pre-requis")
                installServer
                exit 0
		break
                ;;
            "Afficher la configuration")
                cat config.yml
                maintenance
		break
                ;;
            "Purger les Backups")
                purgeBackups
                maintenance
		break
                ;;
            "Supprimer le serveur")
                resetServer
                maintenance
		break
                ;;
            "Menu Principal")
        break
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done

}

mainMenu()
{
	echo "
	_
	__           
	___ Spigot MC Easy Script $scriptVersion by Swyx 
	__         
	_
	"
	
	PS3='>: '
    options=("Demarrer le serveur" "Lancer le serveur en mode perpetuel" "Maintenance" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Demarrer le serveur")
                runServ
                mainMenu
		break
                ;;
            "Lancer le serveur en mode perpetuel")
                autonomous=1
                runServ
                mainMenu
		break
                ;;
            "Maintenance")
                maintenance
                mainMenu
		break
                ;;
            "Quit")
                break
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
}

pushBackup()
{
    if [ $sftpServer = 'default' ]
    then
        echo "Option non configuree"
        sleep 5
    else
lftp -u $sftpUser,$sftpPassword sftp://$sftpUser@$sftpServer <<EOF
cd Home
mirror -R -n Backups/
quit
EOF
    fi
}

startSever()
{
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mStarting the server\e[39m"
	cd Server
	java -Xms$dedicatedRam -Xmx$dedicatedRam -jar spigot.jar --nogui
	cd ..
	echo -e "\e[33m>>Server Stopped\e[39m"
}

buildToolsUpdate()
{
	cd Build
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mUpdate : BuildTools to latest\e[39m"
	wget $spigotSource
	cd ..
}

buildUpdate()
{
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mUpdate : Spigot to" $buildVersion"\e[39m"
	cd Build
	java -jar BuildTools.jar --rev $buildVersion
	cd ..
}

updateServer()
{

	# Testing if the Server/ Directory exists
	if [ ! -d "Server/" ]
	then
		echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mCreating Server Directory\e[39m"
		mkdir Server
		# Auto Accepting eula
		echo "eula=true" > Server/eula.txt
	else
		echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mBackup : spigot.jar."$(date +%F-%H-%M-%S)".bak\e[39m"
		mv Server/spigot.jar Backups/$buildVersion-spigot.jar.$(date +%F-%H-%M-%S).bak
	fi

	# Testing if the Build/ Directory exists
	if [ ! -d "Build/" ]
	then
		echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mCreating Build Directory\e[39m"
		mkdir Build
		buildToolsUpdate
	else
		echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mBackup : BuildTools.jar."$(date +%F-%H-%M-%S)".bak\e[39m"
		mv Build/BuildTools.jar Backups/$buildVersion-BuildTools.jar.$(date +%F-%H-%M-%S).bak
		buildToolsUpdate
	fi

	buildUpdate

	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mCreating spigot.jar\e[39m"
	mv Build/spigot*.jar Server/spigot.jar
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mspigot.jar created\e[39m"
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mEnd of Update\e[39m"
}

installServer()
{
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mInstalling Pre-requisites\e[39m"
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mRepos Update\e[39m"
	sudo apt update
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mPackets Update\e[39m"
	sudo apt upgrade -y
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mInstallation of git, 7z and lftp\e[39m"
	sudo apt install git p7zip-full lftp
	# test if ppa is present
	if ! grep "^deb .*linuxuprising/java" /etc/apt/sources.list /etc/apt/sources.list.d/*; 
	then
		echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mJava is outdated\e[39m"
		sudo apt remove default-jdk
		echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mAdding new repository\e[39m"
		# commands to add the ppa ...
		sudo add-apt-repository ppa:linuxuprising/java
		echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mJava Update to v16\e[39m"
		sudo apt update
		# commands to install java 16 and put it as default jdk ...
		sudo apt install oracle-java16-installer --install-recommends -y
	else
		echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mJava is already in V16\e[39m"
	fi
    
	echo -e "\n\e[33m


	############################
	#                          #
	#    IMPORTANT ! ! !       #
	#                          #
	############################
	\e[39m"
	echo -e "\e[5m\e[33m
	>>Host reboot mandatory\e[0m\e[39m\n"
}

cleanServer()
{
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mDeleting : Build\e[39m"
	rm -rf Build/
}

backupWorld()
{

	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mBacking up Worlds\e[39m"
	7z a Backups/$buildVersion-worlds.$(date +%F-%H-%M-%S).7z Server/world*
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mDone\e[39m"
}

backupServer()
{
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mBacking up Full Server\e[39m"
	7z a -t7z -m0=lzma2 -mx=9 -aoa -- Backups/$buildVersion-MCServer.$(date +%F-%H-%M-%S).7z Server _Spigot-Server.sh config.yml
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mDone\e[39m"
}

resetServer()
{
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mSafety Backup Before Reset\e[39m"
	7z a Backups/$buildVersion-Reset.MCServer.$(date +%F-%H-%M-%S).7z Server
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mDone\e[39m"
	
	cleanServer

	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mDeleting : Server\e[39m"
	rm -rf Server/
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mServer reset Complete\e[39m"
}

purgeBackups()
{
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mDeleting : Backups\e[39m"
	rm -rf Backups/
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mBackups Deleted\e[39m"
}

getUpdate()
{
	if [ $sftpServer = 'default' ]
		then
			echo "Option non configuree"
			sleep 5
		else
		echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mUpdating : Script\e[39m"
lftp -u $sftpUser,$sftpPassword sftp://$sftpUser@$sftpServer <<EOF
cd Home
get -e _Spigot-Server.sh
quit
EOF
    fi
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mUpdated\e[39m"
	echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mSetting execution rights\e[39m"
	sleep 1
}

runServ()
{
    if [ $autonomous == 1 ]
    then
        while [ true ]
        do
            if [ ! -d "Server/" ]
            then
                    echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mFirst Server Start, Updating Build\e[39m"
                    sleep 5
                    updateServer
            fi
            echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mServer is running in autonomous mode\e[39m"
            startSever
            backupWorld
            echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mServer is running in autonomous mode, Ctrl+C to quit or restarting in 5 seconds\e[39m"		
            sleep 5
        done
    else
        if [ ! -d "Server/" ]
        then
                echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mFirst Server Start, Updating Build\e[39m"
                sleep 5
                updateServer
        fi
        startSever
        backupWorld
    fi
}

# Testing if first arg is NULL
if [ -z "$1" ]
then
    echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mNo parameter specified.\e[39m"
else
	if [ $1 == "-u" -o $1 == "--update" ]
	then
		updateServer
		exit 0
	elif [ $1 == "-i" -o $1 == "--install" ]
	then
		installServer
		exit 0
	elif [ $1 == "-r" -o $1 == "--runautonomous" ]
	then
		autonomous=1
		runServ
	elif [ $1 == "-c" -o $1 == "--clean" ]
	then
		cleanServer
		exit 0
	elif [ $1 == "-a" -o $1 == "--full-backup" ]
	then
		backupServer
		exit 0
	elif [ $1 == "-h" -o $1 == "--help" ]
	then
		showHelp
		exit 0
	elif [ $1 == "-g" -o $1 == "--get-update" ]
	then
		getUpdate
		chmod u+x *.sh
		echo -e "\e[5m\e[33m>>\e[0m\e[39m\e[96mDone\e[39m"
		exit 0
	else
		echo "Unknown parameter, try \"./_Spigot-Server.sh --help\""
		exit 0
	fi
fi

mainMenu
