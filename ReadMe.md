# Installing `apt-get` On A Phoenix Contact PLCnext Controller

[Phoenix Contact](https://www.phoenixcontact.com/), a German manufacturer for industrial appliances, offers a set of extremely versatile [PLCnext](https://www.phoenixcontact.com/en-pc/products/controller-axc-f-2152-2404267) SPS controllers that come with a Debian Linux OS pre-installed.

Out of the box, the Debian OS stored on these controllers is equipped with a minimum set of packages necessary to run and support the PLCnext [ARP](https://www.plcnext-runtime.com/ch03-00-plcnext-runtime.html) runtime in order to leave as much free memory as possible to your SPS programs.

If you plan to install additional packages to the PLCnext controller of your choice, you probably want to download these to the PLCnext device by using a package manager.

Currently, the package manager installed on a PLCnext controller is [`dpkg`](https://en.wikipedia.org/wiki/Dpkg), which is a low-level tool that's unable to resolve package dependencies by itself. This may cause some headache when you have a deep dependency tree to download for your favorite package to finally run.

So, `dpkg` may not be the first of your choices for downloading packages to your PLCnext controller. Fortunately, the higher-level [`apt`](https://en.wikipedia.org/wiki/APT_(software)) package manager has become a popular alternative tool to use. But the `apt` package manager is not included with a PLCnext device's Debian Linux distribution.

This repository now provides a `bash` script that's downloading and installing all the packages required to run `apt`. The script itself is using the `dpkg` package manager to download and install all the necessary packages (about 60 at this time).

Just run this repository's installation script on your PLCnext device, and `apt` will  get properly installed by the script.

## Prerequisites

The footprint of the `apt` package and all of its dependency packages is too large to fit the free space available on a PLCnext controller. So, you must have an [SD memory card](https://www.plcnext.help/te/WBM/Security_SD_Card_settings.htm) installed and configured on your PLCnext device for successful installation. 4 GB of free memory on the card should be sufficient for `apt` to be installed and configured.

Make sure your PLCnext controller has Internet access when running this script, as the packages will get downloaded from `debian.org` for installation.

## How To Install

1. This repository's `bash` script must run on your PLCnext controller with `root` privileges. Full administrative privileges are required when installing the `.deb` packages.

   To do so, enable the `root` user account to log-in to your PLCnext device; i.e., sign in as `admin` to your PLCnext device and set a password on the `root` user account:

   ```bash
   sudo passwd root
	 ```

1. Next, enable SSH access for the `root` user.

   To do so, still being logged-in as `admin` on your PLCnext controller, edit the `/etc/ssh/sshd_config` file:

   Uncomment the `PermitRootLogin yes` line in the file and save the file back again:

	 ```bash
   sed -i -E 's/^\s*#\s*PermitRootLogin/PermitRootLogin/' '/etc/ssh/sshd_config'
	 ```

   After saving the file, restart the SSH daemon for the changes to take effect:

   ```bash
   /etc/init.d/sshd restart
   ```

1. Log in to your PLCnext controller using `root` credentials and perform the next steps as `root` user.

1. Copy this repository's `apt-installer.sh` and `packages.txt` files to your PLCnext device into a folder you feel appropriate, e.g. `/opt/aptget/`.

1. In your PLCnext controller, run `apt-installer.sh` using the `bash` shell:

   ```bash
	 bash ./apt-installer.sh
	 ```

	 *Above path assumes you changed your current working directory to the folder containing the installation script.*

The installation script will then install `apt` to your PLCnext device.

## Behind The Scenes

This repository and the `apt-installer.sh` script was created based on the [`pxcbe/apt-installer`](https://github.com/pxcbe/apt-installer) repository found on GitHub.

Unfortunately, today some of the packages listed in that other repository are not available anymore. So, I was left to find and download the currently available necessary packages manually.

Doing so, I took the chance not only to update the package list but also to improve the installation script design and make it more robust.

### Improvements are:

- All listed packages get fully downloaded in step #&#8203;1, before any installation takes place.

  This ensures that, if anything goes wrong while downloading, nothing will be changed on the PLCnext device. No need to unwind from an instable state or to reset the device.

- The list of packages to download is now outsourced to a separate file. So, when new package releases get published, the list of packages can easily be updated in the package list file without touching the installation script's source code.

- Optionally, a different package list file may be used for installation by providing the corresponding file path as command line argument to the script:

  ```bash
	bash ./apt-installer.sh /path/to/my-packages.txt
	```

  *The default location of the packages list file is `"./packages.txt"`, relative to the installation script file.*

- The script outputs helpful log and error messages.

- After successful installation, clean-up is done by deleting the temporary download directory containing the `.deb` packages that have been downloaded by the installation script.

  *NB: Download directory location is `"./download/"`, relative to the installation script file.*


## The Package List File Format

The package list file is a tab-delimited value file, with individual entries separated by new-line.

The first element in each line is the absolute path to the package file to download. The second element is the package file name.

Entries in the list may be disabled by preceding either path or file name with a hash character (`#`).

Empty lines in the file are ignored.