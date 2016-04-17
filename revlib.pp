unit revlib;

interface

uses sysutils, math, crt;

type
  charset = set of char;

// ansistring functions \\
function countchar(s: ansistring; c: char): longint;
function posc(c:char; s:ansistring; start:longint): longint;
function posc(c:char; s:ansistring): longint;
function reverse(s:ansistring): ansistring;
function lastposc(c:char; s:ansistring): longint;
function lastposc(c:char; s:ansistring; start:longint): longint;
function stripansi(s: ansistring): ansistring;
function stripchar(s: ansistring; c: char): ansistring;
function stripset(s: ansistring; l: charset): ansistring;
function strppos(s2, s1: ansistring): longint;
function substr(s: ansistring; i, l: longint): ansistring;
function translate(s, tfr, tto: ansistring): ansistring;
function wordcount(s: ansistring; d: char): longint;
function wordget(s: ansistring; num: longint; d: char): ansistring;
function wordloc(s: ansistring; start, num: longint; d: char): longint;
function center(s: ansistring; w: longint; c: char): ansistring;

// ini file management \\
function inisection(line,section: ansistring): boolean;
function inikey(line,key:ansistring): boolean;
function inivalue(line:ansistring): ansistring;
function iniwrite(fname,section,key,value:ansistring): boolean;
function iniread(fname,section,key:ansistring; var value:ansistring): boolean;

// misc functions \\
function spinner(count, width: word): word;
function paramcheck(p: ansistring): longint;
function charmenu(prompt, menu: ansistring): char;
function validfolder(path: ansistring): boolean;

implementation

// tested legacy
function center(s: ansistring; w: longint; c: char): ansistring;
var
  pad1, pad2: longint;
begin
  pad2:=w-length(s);
  pad1:=pad2 div 2;
  pad2:=pad1 + (pad2 mod 2);
  if length(s)>w then center:=leftstr(s,w)
  else center:=stringofchar(c,pad1)+s+stringofchar(c,pad2);
end;

function substr(s: ansistring; i, l: longint): ansistring;
begin
  substr:=leftstr(rightstr(s,length(s)-i),l);
end;

// tested legacy
function spinner(count, width: word): word;
var
  x, y: byte;
  ch: char;
begin
  ch:=' ';
  if count=0 then ch:='-';
  if count=width then ch:='\';
  if count=width*2 then ch:='|';
  if count=width*3 then ch:='/';
  if count>=width*4 then
  begin
    ch:='-';
    count:=0;
  end;
  if not(ch=' ') then
  begin
    x:=wherex;
    y:=wherey;
    write(ch);
    gotoxy(x,y);
  end;
  spinner:=count+1;
end;

// needs to be tested
function strppos(s2, s1: ansistring): longint;
var
  p: pchar;
begin
  p:=strpos(pchar(s1), pchar(s2));
  if p=nil then strppos:=0
           else strppos:=length(s1)-length(pchar(p));
end;

// tested 21 aug 2002
function posc(c:char; s:ansistring; start: longint): longint;
var
  p : pchar;
  len : longint;
begin
  if start=0 then start:=1;
  len:=max(length(s)-start+1,0);
  p:=strscan(pchar(rightstr(s,len)),c);
  if p=nil then posc:=0
  else posc:=length(s)-strlen(p)+1;
end;

// tested 21 aug 2002
function posc(c:char; s:ansistring): longint;
begin
  posc:=posc(c,s,1);
end;

// tested 21 aug 2002
function reverse(s:ansistring): ansistring;
var
  i: longint;
  r: ansistring;
begin
  for i:=length(s) downto 1 do
  begin
    r:=r+s[i];
  end;
  reverse:=r;
end;

// needs to be tested
function lastposc(c:char; s:ansistring; start: longint): longint;
var
  p : pchar;
  len : longint;
begin
  if start=0 then start:=1;
  len:=max(length(s)-start+1,0);
  p:=strrscan(pchar(rightstr(s,len)),c);
  if p=nil then lastposc:=0
  else lastposc:=length(s)-strlen(p)+1;
end;

// needs to be tested
function lastposc(c:char; s:ansistring): longint;
begin
  lastposc:=lastposc(c,s,1);
end;

// tested legacy
function validfolder(path:ansistring): boolean;
const
  name: string='tmp.$$$';
var
  f: text;
  fname: ansistring;
begin
 fname:=path+name;
 {$i-}
 assign(f, fname);
 rewrite(f);
 {$i+}
 case ioresult of
   0: begin
        write(f,'this file can be deleted.');
        close(f);
        deletefile(fname);
        validfolder:=(extractfilename(fname)=name);
      end;
   otherwise validfolder:=false;
 end;
end;

// tested legacy
function paramcheck(p : ansistring) : longint;
var j, k1, k2, k3, l: longint;
begin
  if posc('/',p)=0 then paramcheck:=0
  else
  begin
    k1:=posc('+',p);
    k2:=posc('-',p);
    k3:=posc(':',p);
    if min(min(k1,k2),k3)=0 then
    begin
      j:=max(max(k1,k2),k3);
      l:=length(p);
      if (j<2) then
      begin
        if (l>1) then paramcheck:=l+1
        else paramcheck:=0;
      end
      else
      begin
        if l>1 then paramcheck:=j
        else paramcheck:=0;
      end;
    end
    else paramcheck:=min(min(k1,k2),k3);
  end;
end;

// tested legacy
function wordloc(s: ansistring; start, num: longint; d: char): longint;
var
  w, l: longint;
  db: boolean;
begin
  l:=length(s);
  if (s='') or (num<1) or (start>l) then
  begin
    wordloc:=0;
    exit;
  end;
  db:=true;
  w:=0;
  start:=pred(start);
  while (w<num) and (start<l) do
  begin
    start:=succ(start);
    if db and not(s[start]=d) then
    begin
      w:=succ(w);
      db:=false;
    end
    else
      if not(db) and (s[start]=d) then db:=true;
  end;
  if w=num then wordloc:=start
  else wordloc:=0;
end;

// tested legacy
function wordcount(s: ansistring; d: char): longint;
var
  w, i: longint;
  db: boolean;
begin
  if s='' then
  begin
    wordcount:=0;
    exit;
  end;
  db:=true;
  w:=0;
  For  i:=1 to length(s) do
  begin
    if db and not(s[i]=d) then
    begin
      w:=succ(w);
      db:=false;
    end
    else
      if not(db) and (s[i]=d) then db:=true;
  end;
  wordcount:=w;
end;

// tested legacy
function wordget(s: ansistring; num: longint; d: char): ansistring;
var start, finish : longint;
begin
  if s='' then
  begin
    wordget:='';
    exit;
  end;
  start:=wordloc(s,1,num,d);
  if start=0 then
  begin
    wordget:='';
    exit;
  end
  else finish:=wordloc(s,start,2,d);
  if finish=0 then finish:=succ(length(s));
  repeat
    finish:=pred(finish);
  until s[finish]<>d;
  wordget:=copy(s,start,succ(finish-start));
end;

// tested legacy
function inisection(line,section:ansistring): boolean;
begin
  if line='['+section+']' then inisection:=true
  else inisection:=false;
end;

// tested legacy
function inikey(line,key:ansistring): boolean;
begin
  if wordcount(line,'=')=2 then
    if wordget(line,1,'=')=key then inikey:=true
    else inikey:=false
  else inikey:=false;
end;

// tested legacy
function inivalue(line:ansistring): ansistring;
begin
  inivalue:=wordget(line,2,'=');
end;

// tested legacy
function iniwrite(fname,section,key,value:ansistring): boolean;
var
  fhandle, tmphandle: text;
  tmpname, line: ansistring;
  insection, written: boolean;
begin
  insection:=false;
  written:=false;
  tmpname:=fname+'.tmp';
  if fileexists(tmpname) then deletefile(tmpname);
  if fileexists(fname) then
  begin
    assign(tmphandle,tmpname);
    rewrite(tmphandle);
    assign(fhandle,fname);
    reset(fhandle);
    while not(eof(fhandle)) do
    begin
      readln(fhandle,line);
      line:=trim(line);
      if insection and (leftstr(line,1)='[') and (rightstr(line,1)=']') then insection:=false;
      if not(insection) then insection:=inisection(line,section);
      if not(insection) then writeln(tmphandle,line);
      if insection and not(inikey(line,key)) then writeln(tmphandle,line);
      if insection and not(written) then
      begin
        writeln(tmphandle,key,'=',value);
        written:=true;
      end;
    end;
    close(fhandle);
    if not(written) then
    begin
      writeln(tmphandle);
      writeln(tmphandle,'[',section,']');
      writeln(tmphandle,key,'=',value);
    end;
    close(tmphandle);
    if fileexists(fname) then deletefile(fname);
    renamefile(tmpname,fname);
    iniwrite:=true;
  end
  else iniwrite:=false;
end;

// tested legacy
function iniread(fname,section,key:ansistring; var value:ansistring): boolean;
var
  fhandle: text;
  line: ansistring;
  insection: boolean;
begin
  value:='';
  insection:=false;
  if fileexists(fname) and (value='') then
  begin
    assign(fhandle,fname);
    reset(fhandle);
    while not(eof(fhandle)) do
    begin
      readln(fhandle,line);
      line:=trim(line);
      if insection and (leftstr(line,1)='[') and (rightstr(line,1)=']') then insection:=false;
      if insection and inikey(line,key) then value:=inivalue(line);
      if not(insection) and inisection(line,section) then insection:=true;
    end;
    close(fhandle);
    if value='' then iniread:=false
    else iniread:=true;
  end
  else iniread:=false;
end;

// tested legacy
function charmenu(prompt,menu: ansistring): char;
var
  ch, high: char;
begin
  write(prompt);
  ch:=readkey;
  if ch=char(0) then high:=readkey;
  if ch=char(0) then write(' ',word(high));
  while (posc(ch,menu)=0) and not(ch=char(27)) do
  begin
    ch:=readkey;
    if ch=char(0) then high:=readkey;
    if ch=char(0) then write(' ',word(high));
  end;
  if ch=char(27) then ch:=char(0);
  writeln(ch);
  charmenu:=ch;
end;

// tested legacy
function stripansi(s: ansistring): ansistring;
var
  s2: ansistring;
  i: longint;
  ain: boolean;
begin
  ain:=false;
  for i:=1 to length(s) do
  begin
    if s[i]=#27 then ain:=true;
    if not(ain) then s2:=s2+s[i];
    if ain and not(s[i]=#27) and not(s[i] in ['[',';','1','2','3','4','5','6','7','8','9','0']) then ain:=false;
  end;
  stripansi:=s2;
end;

// tested legacy
function stripchar(s: ansistring; c: char): ansistring;
var
  s2: ansistring;
  i: longint;
begin
  for i:=1 to length(s) do
    if not(s[i]=c) then s2:=s2+s[i];
  stripchar:=s2;
end;

// tested legacy
function stripset(s: ansistring; l: charset): ansistring;
var
  s2: ansistring;
  i: longint;
begin
  for i:=1 to length(s) do
    if not(s[i] in l) then s2:=s2+s[i];
  stripset:=s2;
end;

// tested legacy
function translate(s, tfr, tto: ansistring): ansistring;
var
  s2: ansistring;
  i, j, k: longint;
  f: boolean;
begin
  k:=min(length(tfr),length(tto));
  for i:=1 to length(s) do
  begin
    f:=false;
    for j:=1 to k do
      if s[i]=tfr[j] then
      begin
        f:=true;
        break;
      end;
    if f then s2:=s2+tto[j]
    else s2:=s2+s[i];
  end;
  translate:=s2;
end;

// tested legacy
function countchar(s: ansistring; c: char): longint;
var
  i, count: longint;
begin
  count:=0;
  for i:=1 to length(s) do
    if s[i]=c then inc(count);
  countchar:=count;
end;

begin
end.
