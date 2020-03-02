# main.sh

Generic bash library functions (management of messages, traps, arrays, hashes, strings, etc.)

## Constants

### Terminal color codes
* **Color_Off**: Disable color
* **Black,Red,Green,Yellow,Blue,Purple,Cyan,Orange**: Regular Colors
* **BBlack,BRed,BGreen,BYellow,BBlue,BPurple,BCyan,BWhite**: Bold Colors
* **UBlack,URed,UGreen,UYellow,UBlue,UPurple,UCyan,UWhite**: Underlined Colors
* **On_Black,On_Red,On_Green,On_Yellow,On_Blue,On_Purple,On_Cyan,On_White**: Background Colors
* **IBlack,IRed,IGreen,IYellow,IBlue,IPurple,ICyan,IWhite**: High Intensty Colors
* **BIBlack,BIRed,BIGreen,BIYellow,BIBlue,BIPurple,BICyan,BIWhite**: Bold High Intensty Colors
* **On_IBlack,On_IRed,On_IGreen,On_IYellow,On_IBlue,On_IPurple,On_ICyan,On_IWhite**: High Intensty Background Colors


## Global Variables

### Flags
* **\_MAIN__FLAGS\[SOURCED\]** (Bool): Is current file sourced?
* **\_MAIN__FLAGS\[CHROOTED\]** (Bool): Is current process chrooted? This flag is set after with the call to function main.is-chroot?()
### Others
* **\_MAIN__RAW_SCRIPTNAME** (string): Calling script path, raw and not normalized: as seen by the shell through BASH_SOURCE variable
* **\_MAIN__SCRIPTPATH** (string): Calling script path after any possible link resolution
* **\_MAIN__SCRIPTNAME** (string): Calling script real name (after any possible link resolution)
* **\_MAIN__SCRIPTDIR** (string): Absolute path where reside the calling script, after any possible link resolution


## Functions
* [main_set-script-path-info()](#main_set-script-path-info)
* [get_ext_color()](#get_ext_color)


### main_set-script-path-info()

Set the 

#### Aliases

* **main.set-script-path-info**

#### Exit codes

* **0**: Script is chroot'ed
* **1**: Script is not chroot'ed

#### Example

```bash
main.is-chroot?
```

### get_ext_color()

Get extended terminal color codes

#### Arguments

* **$1** (number): Foreground color
* **$2** (number): Background color

#### Example

```bash
get_ext_color 208
  => \e[38;5;208m
```

#### Exit codes

* n.a.

#### Output on stdout

* Color code.


