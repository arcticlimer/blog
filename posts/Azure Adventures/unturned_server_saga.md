---
date: 2022-05-15
title: Unturned Server Saga
---

<!-- toc -->

# Intro
Some years ago I used to have a lot of fun in weekends with some friends playing [Unturned](https://store.steampowered.com/app/304930/Unturned/). It's a really funny game that I like to call the "poor man's Rust", cause it's free and has an incredibly funny and rust-like mechanic in PVP.
I've always used to say to them that some day I would host an Unturned server
and we would have a lot of fun playing and managing it. Since I've got some spare Azure credits, why not hosting one in some port of my virtual machine?

# Hosting

## Simple Setup

For a simple setup, you can follow [this guide](https://blog.yat1ma30.com/posts/host-dedicated-unturned-server) and then just use the `ServerHelper.sh` script inside the game's folder to start your server.

## Hosting more than one server in the same host

If you want a fancier setup to do something like tinkering and restarting a second server while people play at your main one, you will need the following scripts:

### start.sh
```sh
$unturned_dir = ~/unturned

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`dirname $0`/Unturned_Headless_Data/Plugins/x86_64/
cp -f $unturned_dir/linux64/steamclient.so $unturned_dir/Unturned_Headless_Data/Plugins/x86_64/steamclient.so

# ~/steamcmd/steamcmd.sh +login anonymous +force_install_dir $unturned_dir +app_update 1110390 validate +exit
mkdir -p $unturned_dir/linux64
yes | cp -rf ~/steamcmd/linux64/steamclient.so $unturned_dir
yes | cp -rf ~/steamcmd/linux64/steamclient.so $unturned_dir/linux64/

# Terminal mode compatible with -logfile 2>&1 IO.
export TERM=xterm

# Run the server binary.
# -batchmode and -nographics are Unity player arguments.
# -logfile 2>&1 can be used to pipe IO to/from the terminal.
# "$@" appends any command-line arguments passed to this script.
./Unturned_Headless.x86_64 -batchmode -nographics -ThreadedConsole "$@"
```

### update.sh
```sh
md5sum ~/steamcmd/linux32/steamclient.so
md5sum ~/steamcmd/linux64/steamclient.so

mkdir -p ~/steamcmd/
cd ~/steamcmd/
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
chmod +x steamcmd.sh
./steamcmd.sh +quit

# Fix libraries
sudo rm -fv /lib/steamclient.so
sudo rm -fv /lib64/steamclient.so
sudo ln -s ~/steamcmd/linux32/steamclient.so /lib/steamclient.so
sudo ln -s ~/steamcmd/linux64/steamclient.so /lib64/steamclient.so

md5sum ~/steamcmd/linux32/steamclient.so
md5sum ~/steamcmd/linux64/steamclient.so
```

These are based on the scripts shared in [this commentary](https://github.com/SmartlyDressedGames/Unturned-3.x-Community/issues/1622#issuecomment-640060882).

# Server Configuration

## Workshop Mods

Adding mods is as simple as editing `WorkshopDownloaderConfig.json` and adding the mods' ids (you can copy them from the URL) and pasting them inside the `File_IDs` array.

```json 
{
  "File_IDs": [],
  "Ignore_Children_File_IDs": [],
  "Query_Cache_Max_Age_Seconds": 600,
  "Max_Query_Retries": 2,
  "Use_Cached_Downloads": true,
  "Should_Monitor_Updates": true,
  "Shutdown_Update_Detected_Timer": 600,
  "Shutdown_Update_Detected_Message": "Workshop file update detected, shutdown in: {0}"
}
```

## Rocket

Rocket gives you a really nice framework to setup command permissions, server configurations and others. In order to add it to your game, you should move the Rocket assets into the `Modules` folder in your game root directory.

## Rocket Plugins
In order to add Rocket plugins to your server, you need to simply download the DLLs from the internet or compile them yourself using Visual Studio. Usually you'll be able to find the DLLs if you dig a bit deeper (checking repository issues, other branches) and then you just need to move these to the `Rocket/Plugins` folder inside your server directory.

# Backups

I wanted to have my server saved in an interval of X minutes in a cron, so I can
have different versions of it saved as the time goes.

## Local backups
This version saves the zipped files to a folder called `Backups` inside the
server folder.


```py 
import zipfile
import sys
import datetime
import calendar
import logging
import os

TO_SAVE = [
    "Rocket",
    "Bundles",
    "Level",
    "Maps",
    "Server",
    "Players",
    "Unturned_Headless_Data",
    "Config.json",
    "WorkshopDownloadConfig.json",
]
SERVER_FOLDER_PATH = sys.argv[1]
BACKUP_FOLDER_PATH = f"{SERVER_FOLDER_PATH}/Backups"

if not os.path.exists(BACKUP_FOLDER_PATH):
    logging.info(f"directory {BACKUP_FOLDER_PATH} does not exist: creating it now")
    os.makedirs(BACKUP_FOLDER_PATH)

try:
    date = datetime.datetime.utcnow()
    utc_time = calendar.timegm(date.utctimetuple())

    with zipfile.ZipFile(f"{BACKUP_FOLDER_PATH}/{utc_time}.zip", 'w') as zip_file:
        for file_name in TO_SAVE:
            path = f"{SERVER_FOLDER_PATH}/{file_name}"

            if os.path.exists(path):
                if os.path.isdir(path):
                    for root, dirs, files in os.walk(path):
                        for file in files:
                            zip_file.write(os.path.join(root, file))
                else:
                    zip_file.write(path)
            else:
                logging.error(f"file or directory {file_name} does not exist in {SERVER_FOLDER_PATH}")

except Exception as e:
    logging.error(f"Could not backup the server folder: {e}")
    raise e
```

## Azure Blob Storage backups
I've also made a version of it that uploads the content to an Azure Blob
Storage: 

```py
import zipfile
import sys
import datetime
import calendar
import logging
import os
import io

from azure.storage.blob import BlobClient, ContainerClient

def send_to_blob_storage(connection_string, container, blob_name, data):
    container_client = ContainerClient.from_connection_string(conn_str=connection_string, container_name=container)

    if not container_client.exists():
        container_client.create_container()

    blob = BlobClient.from_connection_string(conn_str=connection_string, container_name=container, blob_name=blob_name)
    blob.upload_blob(data)

TO_SAVE = [
    "Rocket",
    "Bundles",
    "Level",
    "Maps",
    "Server",
    "Players",
    "Unturned_Headless_Data",
    "Config.json",
    "WorkshopDownloadConfig.json",
]

CONNECTION_STRING = os.environ["AZURE_BLOBSTORAGE_CONNECTION_STRING"]
CONTAINER = os.environ.get("AZURE_BLOBSTORAGE_CONTAINER") or "server-backups"
SERVER_FOLDER_PATH = sys.argv[1]
BACKUP_FOLDER_PATH = f"{SERVER_FOLDER_PATH}/Backups"
TEMP_FILE_PATH = "/tmp/server_backup"

if not os.path.exists(BACKUP_FOLDER_PATH):
    logging.info(f"directory {BACKUP_FOLDER_PATH} does not exist: creating it now")
    os.makedirs(BACKUP_FOLDER_PATH)

try:
    with zipfile.ZipFile(TEMP_FILE_PATH, "w") as zip_file:
        for file_name in TO_SAVE:
            path = f"{SERVER_FOLDER_PATH}/{file_name}"

            if os.path.exists(path):
                if os.path.isdir(path):
                    for root, dirs, files in os.walk(path):
                        for file in files:
                            zip_file.write(os.path.join(root, file))
                else:
                    zip_file.write(path)
            else:
                logging.error(f"file or directory {file_name} does not exist in {SERVER_FOLDER_PATH}")

    date = datetime.datetime.utcnow()
    utc_time = calendar.timegm(date.utctimetuple())

    with open(TEMP_FILE_PATH, "rb") as data:
        filename = f"{utc_time}.zip"
        send_to_blob_storage(CONNECTION_STRING, CONTAINER, filename, data)

    os.remove(TEMP_FILE_PATH)

    logging.info(f"Succesfully backed {SERVER_FOLDER_PATH} up!")
except Exception as e:
    logging.error(f"Could not back {SERVER_FOLDER_PATH} up: {e}")
    raise e
```
> Note: This assumes the environment variable `AZURE_BLOBSTORAGE_CONNECTION_STRING` is
> set.


# Ending
My first attempt of hosting a modded server last weekend ended up a failure. 
Someone got really mad playing and DDOSed the server. The box actually handled
the load fine, but for some ironical reason, the server itself got banned from
BattleEye. From this I could see that hosting a modded Unturned server could
attract some very annoying playerbase. Since I don't have and won't have any
DDOS protection in this virtual machine, the approach I'm using now is to host a
full vanilla server and hopefully attract a "chadder" playerbase, and it's
working actually well until this moment. 

I hope that you could learn some nice
tricks about hosting an Unturned server and may get attempted to host one too.
