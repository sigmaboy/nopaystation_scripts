# nopaystation_scripts

A linux bash script collection which downloads nopaystation PS Vita stuff.
There are four Scripts. One to download all \*.tsv files of NoPayStation. The other three are for downloading games, updates or all DLC of a PS Vita game.

## Requirements
* bash
* curl
* [*pkg2zip*](https://github.com/mmozeiko/pkg2zip)
If you use openSUSE you can install pkg2zip from the Packman repository.
```bash
# zypper install curl pkg2zip
```
Make sure that executable bit is set on the scripts.
```bash
$ chmod +x download_*.sh
```

## Script examples

### download_game.sh
With this script you can download a PS Vita game.
The first parameter is the path to your \*.tsv file and the second is the game's media ID.
It places the \*.zip file in the current directory.
For example:
```bash
$ ./download_game.sh /home/tux/Downloads/UPDATE.tsv PCSE00986
```
I can recommend [this](http://renascene.com/psv/) Site for searching media IDs.

### download_update.sh
With this script you can download all available PS Vita game updates.
The first parameter is the path to your \*.tsv file and the second is the game's media ID.
It places the files in a created directory from the current working directory named $MEDIAID\_update.
For example:
```bash
$ ./download_update.sh /home/tux/Downloads/GAME.tsv PCSE00986
```

### download_dlc.sh
This script downloads every DLC found for a specific media ID with available zRIF key.
It places the files in a created directory from the current working directory named $MEDIAID\_dlc.
For example:
```bash
$ ./download_dlc.sh /home/tux/Downloads/DLC.tsv PCSE00986
```
Every DLC is placed in a created directory named like the media id relative to the current directory.

### download_tsv.sh
It downloads every \*.tsv file from NoPayStation.com and creates a tar archive with the current date for it.
```bash
$ ./download_tsv.sh /path/to/the/output_directory
```
If you don't add the output directory as the first parameter, it uses the current working directory.
