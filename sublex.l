%{
var
  tempstr: ansistring;
%}
CR \015
LF \012
SP \040
TB \011
SQ \'
DQ \"
BLANK ({SP}|{TB})
CH2 [0-9A-Z_a-z]
CH [!#$0-9A-Z_`a-z~]
WORD {CH}+
ON ({BLANK}+(O|o)(N|n){BLANK}+{WORD}{BLANK}+{WORD})?

%s NORMAL
%s SQUOTE
%s DQUOTE
%s COMMENT
%%

<NORMAL>\/\*  start(COMMENT,yyvars);
<NORMAL>{SQ}  start(SQUOTE, yyvars);
<NORMAL>{DQ}  start(DQUOTE, yyvars);
<COMMENT>\*\/ start(NORMAL, yyvars);
<SQUOTE>{SQ}  start(NORMAL, yyvars);
<DQUOTE>{DQ}  start(NORMAL, yyvars);

<NORMAL>{WORD}{BLANK}*"("
                  begin
                    tempstr:=trim(yyvars.yytext);
                    setlength(tempstr,length(tempstr)-1);
                    tempstr:=trim(tempstr);
                    addlib(tempstr,ll);
                  end;
<NORMAL>(C|c)(A|a)(L|l){2}{ON}{BLANK}+{WORD} 
                  begin
                    tempstr:=trim(yyvars.yytext);
                    tempstr:=trim(rightstr(tempstr,length(tempstr)-lastposc(' ',tempstr)));
                    tempstr:=trim(tempstr);
                    addlib(tempstr,ll);
                  end;
<NORMAL>(S|s)(I|i)(G|g)(N|n)(A|a)(L|l){ON}{BLANK}+{WORD} 
                  begin
                    tempstr:=trim(yyvars.yytext);
                    tempstr:=trim(rightstr(tempstr,length(tempstr)-6));
                    tempstr:=trim(tempstr);
                    addlib(tempstr,ll);
                  end;
<NORMAL>^{BLANK}*{WORD}{BLANK}*: 
                  begin
                    tempstr:=trim(yyvars.yytext);
                    setlength(tempstr,length(tempstr)-1);
                    tempstr:=trim(tempstr);
                    ll.d[addlib(tempstr,ll)]:=true;
                  end;

{CR}{LF}          |
{CR}              |
{LF}              
                  begin
                    //writeln('EOLN');
                    inc(yyvars.yylineno);
                    yyvars.yycolno:=0;
                  end;

. ;//write(yyvars.yytext);

%%
