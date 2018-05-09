# nopaystation_scripts

A linux bash script which downloads nopaystation PS Vita stuff.
Therea are three Scripts. One to download all \*.tsv files of NoPayStation. The other two are for downloading games, update or all DLC of a PS Vita game.

## Requirements
* bash
* curl
* [*pkg2zip*](https://github.com/mmozeiko/pkg2zip)
If you use openSUSE you can install pkg2zip from the Packman repository.
    # zypper install curl pkg2zip

## Script examples

### download_game_or_update.sh
With this script you can download a PS Vita game or a PS Vita game update
The first parameter is the path to your \*.tsv file and the second is the game's media ID.
For example:
```bash
./download_game_or_update.sh /home/tux/Downloads/UPDATE.tsv PCSE00986
```
I can recommend [this](http://renascene.com/psv/) Site for searching media IDs.

### download_dlc.sh
This script downloads every DLC found for a specific media ID with available zRIF key.
For example:
```bash
./download_dlc.sh /home/tux/Downloads/DLC.tsv PCSE00986
```
Every DLC is placed in a created directory named like the media id relative to the current directory.

### download_tsv.sh
It downloads every \*.tsv file from NoPayStation.com and creates a tar archive with the current date for it.
```bash
./download_tsv.sh /path/to/the/output_directory
```
If you don't add the output directory as the first parameter, it uses the current working directory.
