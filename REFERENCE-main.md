# main.sh

Generic bash library functions (management of messages, traps, arrays, hashes, strings, etc.)

## Constants

### Terminal color codes
* **Color_Off**: Disable color
* **Black,Red,Green,Yellow,Blue,Purple,Cyan,Orange**: Regular Colors
* **BBlack,BRed,BGreen,BYellow,BBlue,BPurple,BCyan,BWhite**: Bold Colors
* **UBlack,URed,UGreen,UYellow,UBlue,UPurple,UCyan,UWhite**: Underlined Colors
* **IBlack,IRed,IGreen,IYellow,IBlue,IPurple,ICyan,IWhite**: High Intensty Colors
* **BIBlack,BIRed,BIGreen,BIYellow,BIBlue,BIPurple,BICyan,BIWhite**: Bold High Intensty Colors
* **On_Black,On_Red,On_Green,On_Yellow,On_Blue,On_Purple,On_Cyan,On_White**: Background Colors
* **On_IBlack,On_IRed,On_IGreen,On_IYellow,On_IBlue,On_IPurple,On_ICyan,On_IWhite**: High Intensty Background Colors


## Functions
* [get_ext_color()](#get_ext_color)


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


