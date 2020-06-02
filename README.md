# nopaystation\_scripts

A shell script collection which downloads nopaystation PS Vita stuff.
There are several scripts. One to download all \*.tsv files of NoPayStation. The other are for downloading games, updates
or all DLC of a PS Vita game.

## Supported Operating Systems
* GNU/Linux
* FreeBSD
* Windows 10 with WSL should also work but it's untested

## Requirements
* a working internet connection
* posix shell (bash, ksh, zsh, sh)
* curl or wget
* [*pkg2zip*](https://github.com/mmozeiko/pkg2zip)
* latest [*torrent7z*](https://github.com/BubblesInTheTub/torrent7z)
* python3 + python3-lxml (install it via package manager or pip)
* (Optional) latest [*mktorrent*](https://github.com/Rudde/mktorrent)


## Compiling dependencies from source
This section assumes that "${HOME}/bin" is in your shells "${PATH}".
If you don't want to install the generating programs in $HOME. Just
change it in the howto below to something like "/usr/local/bin" etc.

### mktorrent
If your package manager doesn't already have v1.1 you can compile it by yourself.
mktorrent v1.1 is only needed for source flag. If you don't need it you also can use v1.0.
You also need some sort of compiler (e.g. gcc) and "make" is needed.
```bash
git clone https://github.com/Rudde/mktorrent.git
cd mktorrent/ && PREFIX=$HOME make
PREFIX="${HOME}" make install
rm -rf ~/mktorrent
```

### t7z
Compile t7z from source (gcc and make is needed).
```bash
git clone https://github.com/BubblesInTheTub/torrent7z
cd torrent7z/linux_src/p7zip_4.65/
make
install -Dm 0755 bin/t7z "${HOME}/bin"
```

## nopaystation\_scripts Installation
```bash
git clone -b t7z https://github.com/sigmaboy/nopaystation_scripts.git && cd nopaystation_scripts
chmod +x nps_*.sh pyNPU.py
test -d "${HOME}/bin" && ln -s "$(pwd)"/nps_*.sh "$(pwd)"/pyNPU.py "${HOME}/bin"
```

If you don't have *${HOME}/bin* in your *${PATH}*, try the following.
```bash
test -d "/usr/local/bin" && sudo ln -s "$(pwd)"/nps_*.sh $(pwd)"/pyNPU.py "/usr/local/bin/"
```

## Script examples

### nps\_tsv.sh
It downloads every \*.tsv file from NoPayStation.com and creates a tar archive with the current date for it.
```bash
./nps_tsv.sh /path/to/the/output_directory
```
If you don't add the output directory as the first parameter, it uses the current working directory.
You need the \*.tsv file(s) for mostly every other script in this toolset.

### nps\_game.sh
With this script you can download a PS Vita game.
The first parameter is the path to your \*.tsv file and the second is the game's title ID.
It places the \*.7z (torrent7z) file in the current directory.
It also changes the region name into TV format (NTSC, PAL, ...)
For example:
```bash
./nps_game.sh /home/tux/Downloads/GAME.tsv PCSE00986
```
I can recommend [this](http://renascene.com/psv/) site for searching title IDs.

### nps\_update.sh
With this script you can download the latest or all available PS Vita game updates.
There is a optional first parameter "-a" and the second is the game's title ID.
It places the files in a created directory from the current working directory named <\TITLE\_ID\_update>.
For example:
```bash
./nps_update.sh [-a] PCSE00986
```

### nps\_dlc.sh
This script downloads every DLC found for a specific title ID with available zRIF key.
Every update is placed in a created directory from the current working directory named <\TITLE\_ID\_update>.
For example:
```bash
./nps_dlc.sh /home/tux/Downloads/DLC.tsv PCSE00986
```
Every DLC is placed in a created directory from the current working directory named <\TITLE\_ID\_dlc>.

### nps\_psp.sh
With this script you can download a PSP game.
The first parameter is the path to your \*.tsv file and the second is the game's title ID.
It places the \*.iso file in the current directory.
For example:
```bash
./nps_psp.sh /home/tux/Downloads/PSP_GAMES.tsv NPUZ00001
```
I can recommend [this](http://renascene.com/psp/) site for searching title IDs.

### nps\_bundle.sh
Requirements:
* pkg2zip and the optionally mktorrent If you want to use the source flag, you need mktorrent >= 1.1

This script downloads the game, every update and dlc found for a specific title ID with available zRIF key.
It puts the DLC and the Updates in a dedicated folder named like the generated zip and optionally creates a torrent for the game,
updates and dlc folders. In fact it uses the three scripts from above, combines them and download everything available for a game.
You need to have nps\_game.sh, nps\_update.sh, nps\_dlc.sh in your $PATH variable to get it working.

You need to symlink them to **${HOME}/bin/**, **/usr/local/bin** or **/usr/bin/**.
This is explained in the *Installation* Section above

If you want to do some additional steps after running *nps_bundle.sh*, you can add a post script named *nps_bundle_post.sh* to the directory where you run *nps_bundle.sh* from the command line.
It has to be executable to run. *nps_bundle.sh* runs the post script with the game name as the first parameter.
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

If you call the script with "-a", it will download all updates instead of the latest only. Additionally you can set the parameter [-c]
to enable torrent creating. If you use this you can add source flag after it.
when creating torrent files with to use with private trackers.
To use this feature you need to have mktorrent installed in version 1.1+!
For example:
```bash
./nps_bundle.sh [-a] -t PCSE00986 -c "http://announce.url" -d "/path/to/directory/containing/the/tsv/files" [-c] [<SOURCE FLAG>]
```

## nps\_region.sh
This works pretty much the same as **download2torrent.sh** but downloads all base games of a specific region.
It creates a subdirectory in your current working directory for the region you mentioned. Valid regions are *US* *JP* *EU* *ASIA*.
There is also a post hook implemented with the file name *./nps_region_post.sh*
For more informations and help about the script just call it with the *--help* parameter.

Example:
```bash
$ ./nps_region.sh -r ASIA -t game -d /path/to/directory/containing/the/tsv/files [-c http://announce.url] [-s <SOURCE>] [-a]
```

### pyNPU.py
This little python program helps you downloading updates and generating changelogs for your games.
Just use the "-h" parameter to get all parameters and examples. It's useful for checking changelogs and generating download links.

# ToDos
* create a script to download PSM games
* add command line parameters to control the behaviour of the download scripts (downloading/compressing only)
* compare the whole download + compression process of pkg2zip vs. pkg2zip without zipping + torrent7z compressing
