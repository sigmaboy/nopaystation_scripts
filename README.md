# nopaystation\_scripts

A linux shell script collection which downloads nopaystation PS Vita stuff.
There are five scripts. One to download all \*.tsv files of NoPayStation. The other four are for downloading games, updates or all DLC of a PS Vita game.

## Requirements
* posix shell (bash, ksh, zsh, sh)
* curl or wget
* [*pkg2zip*](https://github.com/mmozeiko/pkg2zip)
* latest [*mktorrent*](https://github.com/Rudde/mktorrent)

(Optional) To compile+install mktorrent v1.1 (needed for source flag).
Check the version installed on your system.
```bash
$ mktorrent -v
$ git clone https://github.com/Rudde/mktorrent.git
$ cd mktorrent/ && PREFIX=$HOME make
$ PREFIX=$HOME make install
$ rm -rf ~/mktorrent
```
Make sure that executable bit is set on the scripts.
```bash
$ chmod +x download*.sh
```

## Script examples

### download\_game.sh
With this script you can download a PS Vita game.
The first parameter is the path to your \*.tsv file and the second is the game's media ID.
It places the \*.zip file in the current directory.
For example:
```bash
$ ./download_game.sh /home/tux/Downloads/GAME.tsv PCSE00986
```
I can recommend [this](http://renascene.com/psv/) Site for searching media IDs.

### download\_update.sh
With this script you can download all available PS Vita game updates.
The first parameter is the path to your \*.tsv file and the second is the game's media ID.
It places the files in a created directory from the current working directory named $MEDIAID\_update.
For example:
```bash
$ ./download_update.sh /home/tux/Downloads/UPDATE.tsv PCSE00986
```

### download\_dlc.sh
This script downloads every DLC found for a specific media ID with available zRIF key.
It places the files in a created directory from the current working directory named $MEDIAID\_dlc.
For example:
```bash
$ ./download_dlc.sh /home/tux/Downloads/DLC.tsv PCSE00986
```
Every DLC is placed in a created directory named like the media id relative to the current directory.

### download\_tsv.sh
It downloads every \*.tsv file from NoPayStation.com and creates a tar archive with the current date for it.
```bash
$ ./download_tsv.sh /path/to/the/output_directory
```
If you don't add the output directory as the first parameter, it uses the current working directory.

### download2torrent.sh
Requirements:
* pkg2zip and the latest mktorrent 1.1
  (1.0 is not working since it doesn't know the source option)

This script downloads the game, every update and dlc found for a specific media ID with available zRIF key.
It puts the DLC and the Updates in a dedicated folder named like the generated zip and creates a torrent for the game, updates and dlc folders.
In fact it uses the three scripts from above, combines them to share them easily via BitTorrent. You need to have download\_game.sh, download\_update.sh, download\_dlc.sh in your $PATH variable to get it working.
Either you can symlink them to /home/$YOURUSER/bin/ or copy them to /usr/local/bin/.

If you want to do some additional steps after running *download2torrent.sh*, you can add a post script named *download2torrent_post.sh* to the directory where you run *download2torrent.sh* from the command line.
It has to be executable to run. *download2torrent.sh* runs the post script with the game name as the first parameter.
Your script can handle the parameter with the variable **$1** in your (shell) script.
You can use this to automate your upload process with an script which adds the torrent to your client or move it and
set the correct permissions to the file.
All files are named like **$1**.
For example the update and dlc directories
* ${1}_update
* ${1}_dlc

or the torrent files
* ${1}.torrent
* ${1}_update.torrent
* ${1}_dlc.torrent

Additionally you can set the source tag as the end last command line parameter. This is the only optional parameter. All other are required.
To use this feature you need to have mktorrent installed in version 1.1+!
For example:
```bash
$ ./download2torrent.sh PCSE00986 http://announce.url /path/to/directory/containing/the/tsv/files SOURCE
```
