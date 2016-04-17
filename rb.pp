program rb;

uses revlib, lexlib, dos, sysutils;

const
  VERSION : string = '1.3a';
  VDATE : string = 'October 2003';
  MAXLIBS = 999;
  LOG = FALSE;

type
  tliblist = record
    l: array[1..MAXLIBS] of ansistring;
    d: array[1..MAXLIBS] of boolean;
    c: word;
  end;
  
procedure stop_error(msg: ansistring; code: word);
begin
  writeln(msg);
  halt(code);
end;

function addlib(l: ansistring; var ll: tliblist): word;
var
  i: word;
  f: boolean;
begin
  f:=false;
  for i:=1 to ll.c do
  begin
    if ll.l[i]=l then 
    begin
      f:=true;
      addlib:=i;
      break;
    end;
  end;
  if not f then 
  begin
    if ll.c<MAXLIBS then
    begin
      inc(ll.c);
      ll.l[ll.c]:=l;
      addlib:=ll.c;
    end
    else stop_error('error:  exceeded max libraries.',4);
  end;
end;

{$include sublex.pp}

function buildscript(sname, libpath, author, logname: ansistring): boolean;
var
  fhandle, thandle, lhandle, loghandle: text;
  line, fname, tname, bname: ansistring;
  action, curlib, i: word;
  lflag, lhdr, done: boolean;
  buildnum, bpos: longint;
  yyvars: tyyvars;
  ll: tliblist;
begin
  fname:=sname;
  tname:=fname+'.$$$';
  bname:=extractfilename(fname);
  if LOG then 
  begin
   if fileexists(logname) then
   begin
    assign(loghandle,logname);
    append(loghandle);
   end
   else
   begin
    assign(loghandle,logname);
    rewrite(loghandle);
   end;
  end;

  if fileexists(tname) then deletefile(tname);
  if fileexists(fname) then
  begin
    assign(thandle,tname);
    rewrite(thandle);

    { init liblist }
    ll.c:=0;
    for i:=1 to MAXLIBS do
      ll.d[i]:=false;
    ll.c:=0;

    { init yyvars }
    yyvars.yyiter:=0;
    yyvars.yysstate:=NORMAL;
    yyvars.yylstate:=0;
    
    { loop variables }
    curlib:=0;
    lflag:=false;
    lhdr:=false;
    done:=false;

    while not done do
    begin
      if curlib=0 then write('reading.')
      else begin
             write('.');
             if not lhdr then writeln(thandle,'/*** ',center(upcase(author)+'''S TW LIBRARY FOR ZOC/REXX',70,' ')+' ***/');
             writeln(thandle);
             lhdr:=true;
             lflag:=true;
           end;
      assign(fhandle,fname);
      reset(fhandle);

      while not(eof(fhandle)) do
      begin
        readln(fhandle,line);
        action:=0;
        if (action=0) and (leftstr(line,7)='/* REXX') and not(lflag) then action:=1;
        if (action=0) and (leftstr(line,5)='/*** ')   and not(lflag) then action:=2;
        if (action=0) and (leftstr(line,4)='/** ')    and     lflag  then action:=3;
        if (action=0) and (leftstr(line,3)='/*-')                    then action:=4;
        if (action=0) and (leftstr(line,1)='#')                      then
        begin
         action:=4;
         i:=lastposc('#',line,2);
// writeln(thandle,'/*'+inttostr(i)+' '+bname+' '+trim(substr(line,1,i-2))+' '+line+'*/');
         if (i>1) and (bname=trim(substr(line,1,i-2))) then
         begin
          line:=rightstr(line,length(line)-i);
          action:=5;
         end;
        end;
        if (action=0)                                                then action:=5;
        case action of
          0: ;
          1: begin
               bpos:=strppos('(build',line)+7;
               if bpos=7 then buildnum:=0
               else buildnum:=strtoint(substr(line,bpos,posc(')',line,bpos)-bpos-1))+1;
               line:='/* REXX '+bname+' by '+author+' (build '+inttostr(buildnum)+')';
               line:=line+stringofchar(' ',78-length(line))+'*/';
               writeln(thandle,line);
               line:='built by rev-builder version '+VERSION+' on '+formatdatetime('dd mmm yyyy "at" hh:nn:ss',now);
               line:='/*- '+center(line,72,' ')+' -*/';
               writeln(thandle,line);
               writeln(thandle,'/*- '+stringofchar('-',72)+' -*/');
               if fileexists(libpath+'license.txt') then
               begin
                 assign(lhandle,libpath+'license.txt');
                 reset(lhandle);
                 while not(eof(lhandle)) do
                 begin
                   readln(lhandle,line);
                   if length(line)>72 then line:=leftstr(trim(line),72);
                   writeln(thandle,'/*- ',line,stringofchar(' ',72-length(line)),' -*/');
                 end;
                 close(lhandle);
                 writeln(thandle,'/*- '+stringofchar('-',72)+' -*/');
               end;
               line:='*/ _g.!sname="'+bname+'" /*';
               line:='/*- '+center(line,72,'-')+' -*/';
               writeln(thandle,line);
               line:='*/ _g.!sbuild='+inttostr(buildnum)+'; _g.!sdate="'+formatdatetime('yyyy-mm-dd',now)+'" /*';
               line:='/*- '+center(line,72,'-')+' -*/';
               writeln(thandle,line);
               writeln(thandle,'/*- '+stringofchar('-',72)+' -*/');
             end;
          2: lflag:=true;
          3: writeln(thandle,trimright(line));
          4: ;
          5: begin
               if curlib>0 then writeln(thandle,trimright('    '+line))
                           else writeln(thandle,trimright(line));
               yyvars.buf:=line+char(13);
               yyvars.buflen:=length(line)+1;
               yyvars.bufptr:=1;
               if yysublex(yyvars,ll)=0 then ;
             end;
          otherwise ;
        end;
        if action=2 then break;
      end;
      close(fhandle);
      repeat
        inc(curlib);
        if curlib>ll.c then done:=true
        else fname:=libpath+ll.l[curlib]+'.zrl';
        if LOG and not(done) then writeln(loghandle,ll.l[curlib]);
      until (not(ll.d[curlib]) and fileexists(fname)) or done;
    end;

    close(thandle);
    if LOG then
    begin
     if fileexists(tname) then deletefile(tname);
    end
    else
    begin
     if fileexists(sname) then deletefile(sname);
     renamefile(tname,sname);
    end;
    buildscript:=true;
  end
  else buildscript:=false;
  if LOG then close(loghandle);
end;

var
  sname, libpath, author: ansistring;
begin

  writeln('REV-BUILDER version ',VERSION,' [',VDATE,'], Copyright (c) 2002 Ron Wilson');

  if paramcount<2 then stop_error('usage:  rb scriptname libpath [author]',1);
  sname:=paramstr(1);
  libpath:=paramstr(2);
  if paramcount=3 then author:=translate(paramstr(3),'_',' ')
  else author:='(unknown author)';

  if not validfolder(libpath) then libpath:=libpath+'\';
  if not validfolder(libpath) then stop_error('error:  invalid library path',2);
  if not buildscript(sname,libpath,author,libpath+'_revbuilder_log.txt') then stop_error('error:  build failed',3);
end.