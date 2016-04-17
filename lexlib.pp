{$I-}
unit lexlib;

{ Standard Lex library unit for TP Lex Version 3.0. 2-11-91 AG  }
{  modified by ron wilson for use in revproxy                   }

interface

{ Variables:

  The variable yytext contains the current match, yyleng its length.
  The variable yyline contains the current input line, and yylineno and
  yycolno denote the current input position (line, column). These values
  are often used in giving error diagnostics (however, they will only be
  meaningful if there is no rescanning across line ends).

  - yystext: contains the initial contents of the yytext variable; this
    will be the empty string, unless yymore is called which sets yystext
    to the current yytext
  - yysstate: start state of lexical analyzer (set to 0 during
    initialization, and modified in calls to the start routine)
  - yylstate: line state information (1 if at beginning of line, 0
    otherwise)
  - yystack: stack containing matched rules; yymatches contains the number of
    matches
  - yypos: for each rule the last marked position (yymark); zeroed when rule
    has already been considered
  - yysleng: copy of the original yyleng used to restore state information
    when reject is used 
}

const
  lf = #10;  { newline character  }
  cr = #13;
  max_chars = 2048;
  max_matches = 1024;
  max_rules   = 256;

type
  tyyvars = record

    yyline            : string;      { current input line                      }
    yylineno, yycolno : integer;     { current input position                  }
    yytext            : string;      { matched text (should be considered r/o) }

{ internal data structures }
    yystate    : integer;            { current state of lexical analyzer       }
    yyactchar  : char;               { current character                       }
    yylastchar : char;               { last matched character (#0 if none)     }
    yyrule     : integer;            { matched rule                            }
    yyreject   : boolean;            { current match rejected?                 }
    yydone     : boolean;            { yylex return value set?                 }
    yyretval   : integer;            { yylex return value                      }

{ input buffer }
    bufptr : integer;
    buflen : integer;
    buf    : array [1..max_chars] of char;

{ unget buffer }
    unbufptr : integer;
    unbuf    : array [1..max_chars] of char;

{ state information }
    yyiter             : cardinal;  { how many times yylex has been called     }
    yystext            : string;
    yysstate, yylstate : integer;
    yymatches          : integer;
    yystack            : array [1..max_matches] of integer;
    yypos              : array [1..max_rules] of integer;
    yysleng            : byte;
  end;

{ I/O routines: }

function get_char( var yyvars : tyyvars ) : char;
  { obtain one character from the input buffer (null character at end-of-file) }

procedure unget_char ( c : char; var yyvars: tyyvars );
  { return one character to the input buffer to be reread in subsequent calls to get_char }

{ Utility routines: }

procedure yymore( var yyvars : tyyvars );
  { append the next match to the current one }

procedure yyless ( n : integer; var yyvars : tyyvars );
  { truncate yytext to size n and return the remaining characters to the
    input stream }

procedure reject( var yyvars : tyyvars );
  { reject the current match and execute the next one }

  { reject does not actually cause the input to be rescanned; instead,
     internal state information is used to find the next match. Hence
     you should not try to modify the input stream or the yytext variable
     when rejecting a match. }

procedure return ( n : integer; var yyvars : tyyvars );
procedure returnc ( c : char; var yyvars : tyyvars );
  { sets the return value of yylex }

procedure start ( state : integer; var yyvars : tyyvars );
  { puts the lexical analyzer in the given start state; state=0 denotes
    the default start state, other values are user-defined }

procedure yynew( var yyvars : tyyvars );
  { starts next match; initializes state information of the lexical
     analyzer }

procedure yyscan( var yyvars : tyyvars );
  { gets next character from the input stream and updates yytext and
     yyactchar accordingly }

procedure yymark ( n : integer; var yyvars : tyyvars );
  { marks position for rule numner n }

procedure yymatch ( n : integer; var yyvars : tyyvars );
  { declares a match for rule number n }

function yyfind ( var n : integer; var yyvars : tyyvars ) : boolean;
  { finds the last match and the corresponding marked position and adjusts
    the matched string accordingly; returns:
    - true if a rule has been matched, false otherwise
    - n: the number of the matched rule }

function yydefault( var yyvars : tyyvars ) : boolean;
  { executes the default action (copy character); returns true unless
    at end-of-file }

procedure yyclear( var yyvars : tyyvars );
  { reinitializes state information after lexical analysis has been
     finished }

implementation

procedure fatal ( msg : string );
{ writes a fatal error message and halts program }
begin
  writeln('LexLib: ', msg);
  halt(1);
end;

{ I/O routines: }

function get_char( var yyvars : tyyvars ) : char;
begin
  if yyvars.unbufptr>0 then
  begin
    get_char:=yyvars.unbuf[yyvars.unbufptr];
    dec(yyvars.unbufptr);
    inc(yyvars.yycolno);
  end
  else if yyvars.bufptr<=yyvars.buflen then
       begin
         get_char := yyvars.buf[yyvars.bufptr];
         inc(yyvars.bufptr);
         inc(yyvars.yycolno);
       end
       else get_char := #0;
end;

procedure unget_char ( c : char; var yyvars : tyyvars );
begin
  if yyvars.unbufptr=max_chars then fatal('unget_char buffer overflow');
  inc(yyvars.unbufptr);
  dec(yyvars.yycolno);
  yyvars.unbuf[yyvars.unbufptr]:=c;
end;

{ Utilities: }

procedure yymore( var yyvars : tyyvars );
begin
  yyvars.yystext := yyvars.yytext;
end;

procedure yyless ( n : integer; var yyvars : tyyvars );
var i : integer;
begin
  for i := length(yyvars.yytext) downto n+1 do
    unget_char(yyvars.yytext[i],yyvars);
  setlength(yyvars.yytext, n);
end;

procedure reject( var yyvars : tyyvars );
var i : integer;
begin
  yyvars.yyreject := true;
  for i := length(yyvars.yytext)+1 to yyvars.yysleng do
    yyvars.yytext := yyvars.yytext+get_char(yyvars);
  dec(yyvars.yymatches);
end;

procedure return ( n : integer; var yyvars : tyyvars );
begin
  yyvars.yyretval := n;
  yyvars.yydone := true;
end;

procedure returnc ( c : char; var yyvars : tyyvars );
begin
  yyvars.yyretval := ord(c);
  yyvars.yydone := true;
end;

procedure start ( state : integer; var yyvars : tyyvars );
begin
  yyvars.yysstate := state;
end;

{ Internal routines: }

procedure yynew( var yyvars : tyyvars );
begin
  // need to evaluate this stuff here \\  
  if yyvars.yylastchar<>#0 then
    if (yyvars.yylastchar=lf) or (yyvars.yylastchar=cr) then yyvars.yylstate := 1
                                                         else yyvars.yylstate := 0;
// this line added 21 aug 2002 to fix uninitialized yylstate.
// this line removed same date when initializing yylstate in the main program also solved the problem.
//                           else yyvars.yylstate:=0;
  yyvars.yystate := yyvars.yysstate+yyvars.yylstate;
  yyvars.yytext  := yyvars.yystext;
  yyvars.yystext := '';
  yyvars.yymatches := 0;
  yyvars.yydone := false;
end;

procedure yyscan( var yyvars : tyyvars );
begin
  if length(yyvars.yytext)=255 then fatal('yytext overflow');
  yyvars.yyactchar := get_char(yyvars);
  setlength(yyvars.yytext,length(yyvars.yytext)+1);
  yyvars.yytext[length(yyvars.yytext)] := yyvars.yyactchar;
end;

procedure yymark ( n : integer; var yyvars : tyyvars );
begin
  if n>max_rules then fatal('too many rules');
  yyvars.yypos[n] := length(yyvars.yytext);
end;

procedure yymatch ( n : integer; var yyvars : tyyvars );
begin
  inc(yyvars.yymatches);
  if yyvars.yymatches>max_matches then fatal('match stack overflow');
  yyvars.yystack[yyvars.yymatches] := n;
end;

function yyfind ( var n : integer; var yyvars : tyyvars ) : boolean;
begin
  yyvars.yyreject := false;
  while (yyvars.yymatches>0) and (yyvars.yypos[yyvars.yystack[yyvars.yymatches]]=0) do
    dec(yyvars.yymatches);
  if yyvars.yymatches>0 then
  begin
    yyvars.yysleng := length(yyvars.yytext);
    n              := yyvars.yystack[yyvars.yymatches];
    yyless(yyvars.yypos[n],yyvars);
    yyvars.yypos[n] := 0;
    if length(yyvars.yytext)>0 then
      yyvars.yylastchar := yyvars.yytext[length(yyvars.yytext)]
    else
      yyvars.yylastchar := #0;
    yyfind := true;
  end
  else
  begin
    yyless(0,yyvars);
    yyvars.yylastchar := #0;
    yyfind := false;
  end
end;

function yydefault( var yyvars : tyyvars ) : boolean;
begin
  yyvars.yyreject := false;
  yyvars.yyactchar := get_char(yyvars);
  if yyvars.yyactchar<>#0 then yydefault := true
  else
  begin
    yyvars.yylstate := 1;
    yydefault := false;
  end;
  yyvars.yylastchar := yyvars.yyactchar;
end;

procedure yyclear( var yyvars : tyyvars );
begin
  yyvars.bufptr := 0;
  yyvars.unbufptr := 0;
  yyvars.yyiter := 0;
//  yyvars.yysstate := 0;
  yyvars.yylstate := 1;
  yyvars.yylastchar := #0;
  yyvars.yytext := '';
  yyvars.yystext := '';
end;

begin
end.