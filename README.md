# nopaystation_scripts
Download nopaystation PS Vita stuff
We have three Scripts to download either the \*.tsv files of NoPayStation or to download games, update or all DLC of a PS Vita game.
## Requirements
You need "curl" and ["pkg2zip"](https://github.com/mmozeiko/pkg2zip) installed on your system. If you use openSUSE you can install pkg2zip from the Packman repository.
## script explanation
### download_game_or_update.sh
With this script you can download a PS Vita game or a PS Vita game update
The first parameter is the path to your \*.tsv file and the second media ID.
For example
```bash
./download_game_or_update.sh /home/tux/Downloads/UPDATE.tsv PCSE00986
```

### download_dlc.sh
This script downloads every DLC found for a specific media ID.
For example
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

## General
You can overwrite a lot of parameter in these script, just by calling them with other variables. But this not neccessary so it is for advanced users only. For example
```bash
BASE_URL="nopaystation.mirror.com" ./download_tsv.sh /path/to/the/output_directory
```
You can overwrite the base url for the script to use another server instead of "nopaystation.com".
