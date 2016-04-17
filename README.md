# rev-builder

welcome to rev-builder, the reverend's premier rexx script building utility.

USAGE:  RB scriptname libraryfolder authorname

the rev-builder will search the libraryfolder for all subroutines used in the script and if found, include them in the script - it also searches each library file for more subroutines to include.  if licence.txt is found in the libraryfolder, then a license will be included in the script.  a script can be re-built any number of times and it will always only include the the subroutines needed by your script.  underscores in the authorname will be converted to spaces.  if you have spaces in your scriptname or library folder, enclose the parameter in quotes like this:  `RB "my script.zrx" "my library\" my\_name`

there are a few format requirements:

1. a script should begin with `/* REXX */` in order to get full header information.
2. all libraries should have the .zrl extension.
3. double and triple star comments are special comments used by the rev-builder.  do not use `/**` and `/***` style comments in your script, except as illustrated below.
4. the first line of each library should begin with a double-star comment (`/** `).
5. do not edit a script below the triple-star comment. when re-building a script (building a script that has already been built before), everything below the `/***` comment will be thrown away and replaced by the most recent library routines.  make sure you fix bugs in your libraries instead of fixing them below the `/***` comment.
6. star-dash comments (`/*- `) will always be removed from a script and its libraries by the rev-builder.

## EXAMPLE

`RB _example.zrx .\_library the_reverend`

in this example, the \_example.zrx script will be built using the subroutine
libraries found in the library\ folder.  notice how the original script has a
star-dash comment, but the built version does not.  also, the original script
only calls one subroutine, \_ansi, but the built version contains \_dwords and
\_dword, which are used by the \_ansi library.

### BEFORE

```
/* REXX */

/*- star-dash comment -*/

line="hello there"

call zocwrite _ansi("bt;frd")
call zocwriteln line

exit
```

### AFTER

```
/* REXX _example.zrx by the reverend (build 0)                                */
/*-       built by rev-builder version 1.0 on 13 May 2002 at 10:59:31        -*/
/*- ------------------------------------------------------------------------ -*/
/*-                       Copyright (C) 2001 Ron Wilson                      -*/
/*-                                                                          -*/
/*- This script is free, and can be modified for your personal use, but you  -*/
/*- cannot copy or distribute this script or any derivative work based upon  -*/
/*- this script without the express permission of the author. Your use of    -*/
/*- this script is governed by the terms of the REV-LICENSE.                 -*/
/*-                                                                          -*/
/*- This program is provided to you WITHOUT ANY WARRANTY, even the implied   -*/
/*- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the -*/
/*- REV-LICENSE for more details.                                            -*/
/*-                                                                          -*/
/*-                A copy of the REV-LICENSE is available at:                -*/
/*-            http://thereverend.coastgames.com/rev-license.html            -*/
/*- ------------------------------------------------------------------------ -*/

line="hello there"

call zocwrite _ansi("bt;frd")
call zocwriteln line

exit

/***                 THE REVEREND'S TW LIBRARY FOR ZOC/REXX                 ***/

/** _ansi v.3 **/
 _ansi: procedure expose (globals)
  rslt="0"
  do i=1 to _dwords(arg(1),";")
   w=_dword(arg(1),i,";")
   select
    when w="dl"  then rslt=rslt||";"||0  /* dull               */
    when w="bt"  then rslt=rslt||";"||1  /* bright             */
    when w="ul"  then rslt=rslt||";"||4  /* underlined         */
    when w="blk" then rslt=rslt||";"||5  /* blinking           */
    when w="fbk" then rslt=rslt||";"||30 /* black foreground   */
    when w="frd" then rslt=rslt||";"||31 /* red foreground     */
    when w="fgr" then rslt=rslt||";"||32 /* green foreground   */
    when w="fye" then rslt=rslt||";"||33 /* yellow foreground  */
    when w="fbl" then rslt=rslt||";"||34 /* blue foreground    */
    when w="fmg" then rslt=rslt||";"||35 /* magenta foreground */
    when w="fcy" then rslt=rslt||";"||36 /* cyan foreground    */
    when w="fwh" then rslt=rslt||";"||37 /* white foreground   */
    when w="bbk" then rslt=rslt||";"||40 /* black background   */
    when w="brd" then rslt=rslt||";"||41 /* red background     */
    when w="bgr" then rslt=rslt||";"||42 /* green background   */
    when w="bye" then rslt=rslt||";"||43 /* yellow background  */
    when w="bbl" then rslt=rslt||";"||44 /* blue background    */
    when w="bmg" then rslt=rslt||";"||45 /* magenta background */
    when w="bcy" then rslt=rslt||";"||46 /* cyan background    */
    when w="bwh" then rslt=rslt||";"||47 /* white background   */
    otherwise nop
   end /* select */
  end /* do */
  rslt="^[["||rslt||"m"
 return rslt

/** _dwords v.2 **/
 _dwords: procedure expose (globals)
  rslt=words(translate(arg(1),arg(2)||" "," "||arg(2)))
 return rslt

/** _dword v.2 **/
 _dword: procedure expose (globals)
  rslt=translate(word(translate(arg(1),arg(3)||" "," "||arg(3)),arg(2))," "||arg(3),arg(3)||" ")
 return rslt
```
