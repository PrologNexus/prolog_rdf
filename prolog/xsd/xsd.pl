:- module(
  xsd,
  [
    xsd_lexical_value/3,  % +D, ?Lex, ?Value
    xsd_numeric_type/1,   % ?D
    xsd_strict_subtype/2, % ?Sub, ?Super
    xsd_subtype/2         % ?Sub, ?Super
  ]
).

/** <module> XSD support

@author Wouter Beek
@compat XML Schema 1.1 Part 2: Datatypes
@version 2017-2018
*/

:- use_module(library(aggregate)).
:- use_module(library(arithmetic)).
:- use_module(library(dif)).
:- use_module(library(error)).
:- use_module(library(semweb/rdf11), []).
:- use_module(library(sgml)).
:- use_module(library(xsdp_types)).

:- use_module(library(dcg)).
:- use_module(library(list_ext)).
:- use_module(library(uri_ext)).

:- arithmetic_function(xsd_div/2).
:- arithmetic_function(xsd_mod/2).

:- discontiguous
    xsd_lexical_to_value/3,
    xsd_value_to_lexical/3.

:- op(400, yfx, xsd_div).
:- op(400, yfx, xsd_mod).

% xsd_div(+M, +N, -Z) is det.
%
% If `M` and `N` are numbers, then `M div N` is the greatest integer
% less than or equal to `M / N`.

xsd_div(X, Y, Z):-
  Z is floor(X rdiv Y).

%! xsd_mod(+M, +N, -X) is det.
%
% If `M` and `N` are numbers, then `M mod N` is `m-n * (m div n)`.

xsd_mod(X, Y, Z):-
  Z is X - Y * (X xsd_div Y).

:- rdf_meta
   dt_to_xsd_date_time(+, r, -),
   xsd_date_time_to_dt(+, r, -),
   xsd_lexical_to_value(r, +, -),
   xsd_lexical_to_value_error(r, +),
   xsd_lexical_value(r, ?, ?),
   xsd_numeric_type(r),
   xsd_strict_subtype(r, r),
   xsd_subtype(r, r),
   xsd_value_to_lexical(r, +, -),
   xsd_value_to_lexical_error(r, +).





%! dt_to_xsd_date_time(+Dt:dt, +D:iri, -DateTime:compound) is det.

dt_to_xsd_date_time(dt(Y,Mo,D,_,_,_,_), xsd:date, date(Y,Mo,D)) :- !.
dt_to_xsd_date_time(dt(Y,Mo,D,H,Mi,S,_), xsd:dateTime, date_time(Y,Mo,D,H,Mi,S)) :- !.
dt_to_xsd_date_time(dt(_,_,D,_,_,_,_), xsd:gDay, D) :- !.
dt_to_xsd_date_time(dt(_,Mo,_,_,_,_,_), xsd:gMonth, Mo) :- !.
dt_to_xsd_date_time(dt(_,Mo,D,_,_,_,_), xsd:gMonthDay, month_day(Mo,D)) :- !.
dt_to_xsd_date_time(dt(Y,_,_,_,_,_,_), xsd:gYear, Y) :- !.
dt_to_xsd_date_time(dt(Y,Mo,_,_,_,_,_), xsd:gYearMonth, year_month(Y,Mo)) :- !.
dt_to_xsd_date_time(dt(_,_,_,H,Mi,S,_), xsd:time, time(H,Mi,S)).



%! xsd_date_time_to_dt(+DateTime:compound, +D:iri, -DT:compound) is det.

% xsd:date
xsd_date_time_to_dt(date(Y,Mo,D), xsd:date, dt(Y,Mo,D,_,_,_,0)).
% xsd:dateTime
xsd_date_time_to_dt(date_time(Y,Mo,D,H,Mi,S), xsd:dateTime, dt(Y,Mo,D,H,Mi,S,0)).
xsd_date_time_to_dt(date_time(Y,Mo,D,H,Mi,S,TZ), xsd:dateTime, dt(Y,Mo,D,H,Mi,S,TZ)).
% xsd:gDay
xsd_date_time_to_dt(D, xsd:gDay, dt(_,_,D,_,_,_,0)).
% xsd:gMonth
xsd_date_time_to_dt(Mo, xsd:gMonth, dt(_,Mo,_,_,_,_,0)).
% xsd:gMonthDay
xsd_date_time_to_dt(month_day(Mo,D), xsd:gMonthDay, dt(_,Mo,D,_,_,_,0)).
% xsd:gYear
xsd_date_time_to_dt(Y, xsd:gYear, dt(Y,_,_,_,_,_,0)).
% xsd:gYearMonth
xsd_date_time_to_dt(year_month(Y,Mo), xsd:gYearMonth, dt(Y,Mo,_,_,_,_,0)).
% xsd:time
xsd_date_time_to_dt(time(H,Mi,S), xsd:time, dt(_,_,_,H,Mi,S,0)).



%! xsd_lexical_value(+D:atom, +Lex:atom, -Value:term) is semidet.
%! xsd_lexical_value(+D:atom, -Lex:atom, +Value:term) is semidet.
%
% @error syntax_error(+Literal:compound)
% @error type_error(+D:atom,+Value:term)

xsd_lexical_value(D, Lex, Value) :-
  ground(Lex), !,
  xsd_lexical_to_value(D, Lex, Value0),
  Value = Value0.
xsd_lexical_value(D, Lex, Value) :-
  ground(Value), !,
  xsd_value_to_lexical(D, Value, Lex0),
  Lex = Lex0.
xsd_lexical_value(_, Lex, Value) :-
  instantiation_error(args([Lex,Value])).

% xsd:anyURI
xsd_lexical_to_value(xsd:anyURI, Lex, Value) :- !,
  (   is_iri(Lex)
  ->  Value = Lex
  ;   xsd_lexical_to_value_error(xsd:anyURI, Lex)
  ).
xsd_value_to_lexical(xsd:anyURI, Value, Lex) :- !,
  (   is_iri(Value)
  ->  Lex = Value
  ;   xsd_value_to_lexical_error(xsd:anyURI, Value)
  ).

% xsd:boolean
xsd_lexical_to_value(xsd:boolean, Lex, Value) :- !,
  (   xsd_lexical_to_value_boolean(Lex, Value)
  ->  true
  ;   xsd_lexical_to_value_error(xsd:boolean, Lex)
  ).

xsd_lexical_to_value_boolean('0', false).
xsd_lexical_to_value_boolean(false, false).
xsd_lexical_to_value_boolean('1', true).
xsd_lexical_to_value_boolean(true, true).

xsd_value_to_lexical(xsd:boolean, Value, Lex) :- !,
  (   xsd_value_to_lexical_boolean(Value, Lex)
  ->  true
  ;   xsd_value_to_lexical_error(xsd:boolean, Value)
  ).

xsd_value_to_lexical_boolean(false, false).
xsd_value_to_lexical_boolean(true, true).

% xsd:decimal
xsd_lexical_to_value(xsd:decimal, Lex, Value) :- !,
  (   atom_phrase(decimalLexicalMap(Value), Lex)
  ->  true
  ;   xsd_lexical_to_value_error(xsd:decimal, Lex)
  ).
xsd_value_to_lexical(xsd:decimal, Value, Lex) :- !,
  (   atom_phrase(decimalCanonicalMap(Value), Lex)
  ->  true
  ;   xsd_value_to_lexical_error(xsd:decimal, Value)
  ).

% xsd:byte
% xsd:decimal
% xsd:double
% xsd;float
% xsd:int
% xsd:integer
% xsd:long
% xsd:negativeInteger
% xsd:nonNegativeInteger
% xsd:nonPositiveInteger
% xsd:positiveInteger
% xsd:short
% xsd:unsignedByte
% xsd:unsignedInt
% xsd:unsignedLong
% xsd:unsignedShort
xsd_lexical_to_value(D, Lex, Value) :-
  rdf11:xsd_numerical(D, Domain, Type), !,
  (   (   Type == double
      ->  catch(xsd_number_string(Value, Lex), _, fail)
      ;   Type == integer
      ->  catch(xsd_number_string(Value, Lex), _, fail),
          rdf11:check_integer_domain(Domain, D, Value)
      )
  ->  true
  ;   xsd_lexical_to_value_error(D, Lex)
  ).
xsd_value_to_lexical(D, Value, Lex) :-
  rdf11:xsd_numerical(D, Domain, Type), !,
  (   rdf11:in_number(Type, Domain, D, Value, Lex)
  ->  true
  ;   xsd_value_to_lexical_error(D, Value)
  ).

% xsd:string
xsd_lexical_to_value(xsd:string, Lex, Value) :- !,
  (   atom_string(Lex, Value)
  ->  true
  ;   xsd_lexical_to_value_error(xsd:string, Lex)
  ).
xsd_value_to_lexical(xsd:string, Value, Lex) :- !,
  (   atom_string(Lex, Value)
  ->  true
  ;   xsd_value_to_lexical_error(xsd:string, Value)
  ).

% xsd:date
% xsd:dateTime
% xsd:gDay
% xsd:gMonth
% xsd:gMonthDay
% xsd:gYear
% xsd:gYearMonth
% xsd:time
xsd_lexical_to_value(D, Lex, Value) :- !,
  rdf11:xsd_date_time_type(D), !,
  (   catch(xsd_time_string(Value0, D, Lex), _, fail),
      xsd_date_time_to_dt(Value0, D, Value)
  ->  true
  ;   xsd_lexical_to_value_error(D, Lex)
  ).
xsd_value_to_lexical(D, Value, Lex) :- !,
  rdf11:xsd_date_time_type(D), !,
  (   dt_to_xsd_date_time(Value, D, Value0),
      catch(xsd_time_string(Value0, D, Str), _, true),
      atom_string(Lex, Str)
  ->  true
  ;   xsd_value_to_lexical_error(D, Value)
  ).

% error
xsd_lexical_to_value_error(D, Lex) :-
  syntax_error(literal(type(D,Lex))).
xsd_value_to_lexical_error(D, Value) :-
  type_error(D, Value).



%! xsd_numeric_type(+D:iri) is semidet.
%! xsd_numeric_type(-D:iri) is multi.

xsd_numeric_type(xsd:byte).
xsd_numeric_type(xsd:double).
xsd_numeric_type(xsd:decimal).
xsd_numeric_type(xsd:float).
xsd_numeric_type(xsd:int).
xsd_numeric_type(xsd:integer).
xsd_numeric_type(xsd:long).
xsd_numeric_type(xsd:negativeInteger).
xsd_numeric_type(xsd:nonNegativeInteger).
xsd_numeric_type(xsd:nonPositiveInteger).
xsd_numeric_type(xsd:positiveInteger).
xsd_numeric_type(xsd:short).
xsd_numeric_type(xsd:unsignedByte).
xsd_numeric_type(xsd:unsignedInt).
xsd_numeric_type(xsd:unsignedLong).
xsd_numeric_type(xsd:unsignedShort).



%! xsd_strict_subtype(?Sub:atom, ?Super:atom) is nondet.

xsd_strict_subtype(X, Y) :-
  dif(X, Y),
  xsd_subtype(X, Y).



%! xsd_subtype(?Sub:atom, ?Super:atom) is nondet.

xsd_subtype(SubGlobal, SuperGlobal) :-
  xsd_global_local_(SubGlobal, SubLocal),
  xsd_global_local_(SuperGlobal, SuperLocal),
  xsdp_subtype_of(SubLocal, SuperLocal),
  xsd_global_local_(SubGlobal, SubLocal),
  xsd_global_local_(SuperGlobal, SuperLocal).

xsd_global_local_(Global, Local) :-
  var(Global),
  var(Local), !.
xsd_global_local_(Global, Local) :-
  rdf_prefix_id(xsd:Local, Global).





% Auxiliary Functions for Operating on Numeral Fragments %

%! digitValue(-Integer:between(0,9))// is det.
% Maps each digit to its numerical value.
%
% # Arguments
%
% @arg Integer A nonnegative integer less than ten.
%
% # Algorithm
%
% Return
%
%   - `0` when `d = '0'`
%
%   - `1` when `d = '1'`
%
%   - `2` when `d = '2'`
%
%   - etc.

digitValue(N) -->
  digit_weight(N).



%! digitSequenceValue(+Digits:list(between(0,9)), -Integer:nonneg) is det.
%
% Maps a sequence of digits to the position-weighted sum of the terms
% numerical values.
%
% # Arguments
%
% @arg Digits A finite sequence of literals, each term matching
%      digit//1.
%
% @arg Integer A nonnegative integer.
%
% # Algorithm
%
% Return the sum of `digitValue(S_i) × 10^{length(S)-i}`, where `i`
% runs over the domain of `S`.

digitSequenceValue(Ds, N) :-
  length(Ds, Len),
  aggregate(
    sum(D * 10 ^ (Len - I)),
    nth1(I, Ds, D),
    N
  ).



%! fractionDigitSequenceValue(+Digits:list(between(0,9)),
%!                            -Fraction:rational) is det.
%
% Maps a sequence of digits to the position-weighted sum of the terms
% numerical values, weighted appropriately for fractional digits.
%
% # Arguments
%
% @arg Digits A finite sequence of literals, each term matching digit.
%
% @arg Integer A nonnegative integer.
%
% # Algorithm
%
% Return the sum of `digitValue(S_i) * 10^{-i}`, where `i` runs over
% the domain of `S`.

fractionDigitSequenceValue(Ds, F):-
  aggregate(
    % @bug The brackets are needed in the exponent.
    sum(rdiv(D,10^I)),
    nth1(I, Ds, D),
    F
  ).



%! fractionFragValue(-Fraction:rational)// is det.
%
% Maps a fracFrag//1 to the appropriate fractional decimal number.
%
% # Arguments
%
% @arg Fraction A nonnegative decimal number.
%
% # Algorithm
%
% The parsed string is necessarily the left-to-right concatenation of
% a finite sequence `S` of literals, each term matching digit//1.
%
% Return fractionDigitSequenceValue(S).

fractionFragValue(Frac) -->
  'digit_weight*'(Ds), !,
  {fractionDigitSequenceValue(Ds, Frac)}.




% Generic Numeral-to-Number Lexical Mappings %

%! unsignedNoDecimalMap(-Integer:nonneg)// is det.
%
% The parser for unsignedNoDecimalPtNumeral//1
%
% Maps an unsignedNoDecimalPtNumeral//1 to its numerical value.
%
% # Arguments
%
% @arg Integer A nonnegative integer.
%
% # Algorithm
%
% `N` is the left-to-right concatenation of a finite sequence `S` of
% literals, each term matching digit//1.
%
% Return `digitSequenceValue(S)`.

unsignedNoDecimalMap(N) -->
  'digit_weight*'(Ds), !,
  {digitSequenceValue(Ds, N)}.



%! noDecimalMap(-Integer:integer)// .
%
% Maps an noDecimalPtNumeral//1 to its numerical value.
%
% Arguments
%
% @arg Integer An integer.
%
% # Algorithm
%
% `N` necessarily consists of an optional sign (`'+'` or `'-'`) and then
% a literal `U` that matches unsignedNoDecimalPtNumeral//1.
%
% Return:
%   - `-1 × unsignedNoDecimalMap(U)`, when `'-'` is present
%   - `unsignedNoDecimalMap(U)`, otherwise.

noDecimalMap(N) -->
  ("-" -> {Sg = -1} ; "+" -> {Sg = 1} ; {Sg = 1}),
  unsignedNoDecimalMap(N0),
  {N is copysign(N0, Sg)}.



%! unsignedDecimalPtMap(-Decimal:rational)// is det.
%
% Maps an unsignedDecimalPtNumeral//1 to its numerical value.
%
% # Arguments
%
% @arg Decimal A nonnegative decimal number.
%
% # Algorithm
%
% `D` necessarily consists of an optional literal `N` matching:
%
%   - unsignedNoDecimalPtNumeral//1
%
%   - a decimal point
%
%   - an optional literal `F` matching fracFrag//1.
%
% Return:
%
%   - `unsignedNoDecimalMap(N)`, when `F` is not present.
%
%   - `fractionFragValue(F)`, when `N` is not present.
%
%   - `unsignedNoDecimalMap(N) + fractionFragValue(F)`, otherwise.

unsignedDecimalPtMap(N) -->
  unsignedNoDecimalMap(I), !,
  ".",
  (fractionFragValue(F) -> {N is I + F} ; {N is I}).
unsignedDecimalPtMap(N) -->
  ".",
  fractionFragValue(N).



%! decimalPtMap(-Decimal:rational)// is det.
%
% Maps a decimalPtNumeral//1 to its numerical value.
%
% # Arguments
%
% @arg Decimal A decimal number.
%
% # Algorithm
%
% `N` necessarily consists of an optional sign (`'+'` or `'-'`) and
% then an instance `U` of unsignedDecimalPtNumeral//1.
%
% Return:
%
%   - `-unsignedDecimalPtMap(U)`, when `'-'` is present
%
%   - `unsignedDecimalPtMap(U)`, otherwise

decimalPtMap(N) -->
  ("-" -> {Sg = -1} ; "+" -> {Sg = 1} ; {Sg = 1}),
  unsignedDecimalPtMap(N0),
  {N is copysign(N0, Sg)}.



%! scientificMap(-Decimal:rational)// is det.
%
% Maps a scientificNotationNumeral//1 to its numerical value.
%
% # Arguments
%
% @arg Decimal A decimal number.
%
% # Algorithm
%
% `N` necessarily consists of an instance `C` of:
%
%   - either noDecimalPtNumeral//1 or decimalPtNumeral//1,
%
%   - either an `'e'` or an `'E'`, and then
%
%   - an instance `E` of noDecimalPtNumeral//1.
%
% Return:
%
%   - `decimalPtMap(C) × 10 ^ unsignedDecimalPtMap(E)`, when a `'.'`
%     is present in `N`, and
%
%   - `noDecimalMap(C) × 10 ^ unsignedDecimalPtMap(E)`, otherwise.

scientificMap(N) -->
  (decimalPtMap(C) -> "" ; noDecimalMap(C)),
  ("e" -> "" ; "E"),
  noDecimalMap(E),
  {N is C * 10 ^ E}.





% GRAMMAR %

% Auxiliary Functions for Producing Numeral Fragments %

/*
%! digit(+Integer:between(0,9))// is det.
%
% Maps each integer between 0 and 9 to the corresponding digit.
%
% In the XSD 1.1 specification this mapping is named `digit`, thus
% conflicting with the name of the grammar rule to which it is
% related.
%
% # Arguments
%
% @arg Integer Between 0 and 9 inclusive.
%
% # Algorithm:
%
% Return:
%
%   - `'0'`, when  `i = 0`
%
%   - `'1'`, when  `i = 1`
%
%   - `'2'`, when  `i = 2`
%
%   - etc.

digit(N) -->
  decimal_digit(N).
*/



%! digitRemainderSeq(+I:nonneg, -Sequence:list(nonneg)) is det.
%
% Maps each nonnegative integer to a sequence of integers used by
% digitSeq/2 to ultimately create an unsignedNoDecimalPtNumeral//1.
%
% # Arguments
%
% @arg I   A nonnegative integer.
%
% @arg Seq A infinite sequence of nonnegative integers
%
% # Algorithm
%
% Return that sequence s for which
%
%   - `s_0 = i` and
%
%   - `s_{j+1} = s_j div 10`
%
% According to this algorithm, Sequence ends in an inifinite number of
% zeros.  This is no problem in Prolog:
%
% ```prolog
% ?- digitRemainderSeq(123, Seq), append([X,Y,Z,A,B,C,D,E,F|_], _, Seq).
% Seq = [123, 12, 1, 0, 0, 0, 0, 0, 0|...],
% X = 123,
% Y = 12,
% Z = 1,
% A = B, B = C, C = D, D = E, E = F, F = 0,
% freeze(_G29912399, xsd_numer_aux: (_G29912399=[0|_G29912477], inflist(0, _G29912477))) .
% ```

digitRemainderSeq(0, L):- !,
  inflist(0, L).
digitRemainderSeq(I1, [I1|T]):-
  I2 is I1 xsd_div 10,
  digitRemainderSeq(I2, T).



%! digitSeq(+I:nonneg, -Seq:list(nonneg)) is det.
%
% Maps each nonnegative integer to a sequence of integers used by
% unsignedNoDecimalPtCanonicalMap//1 to create an
% unsignedNoDecimalPtNumeral//1.
%
% # Arguments
%
% @arg I        A nonnegative integer.
%
% @arg Sequence A sequence of integers where each term is between 0
%               and 9 inclusive.
%
% # Algorithm:
%
% Return that sequence `s` for which `s_j = digitRemainderSeq(i)_j mod
% 10`.

digitSeq(0, L):- !,
  inflist(0, L).
digitSeq(I1, [I|T]):-
  I is I1 xsd_mod 10,
  I2 is I1 xsd_div 10,
  digitSeq(I2, T).



%! lastSignificantDigit(+Sequence:list(nonneg), -Last:nonneg) is det.
%
% Maps a sequence of nonnegative integers to the index of the last
% non-zero term (when reading from left to right).
%
% This is zero iff the sequence consists of only zeros.  This is a
% non-zero, count-by-1 index into Seq otherwise.
%
% # Arguments
%
% @arg Sequence Aa sequence of nonnegative integers.
%
% @arg Index A nonnegative integer.
%
% # Algorithm
%
% For a sequence of nonnegative integers `s`, return the smallest
% nonnegative integer `j` such that `s(i)_{j+1} = 0`.

lastSignificantDigit(Seq, J):-
  nth0(J, Seq, N),
  N =:= 0, !.



%! 'FractionDigitRemainderSeq'(
%!   +Fraction:rational,
%!   -Sequence:list(compound)
%! ) is det.
%
% Maps each nonnegative decimal number less than 1 to a sequence of
% decimal numbers used by fractionDigitSeq/2 to ultimately create an
% unsignedNoDecimalPtNumeral//1.
%
% # Arguments:
%
% @arg Fraction A nonnegative rational number smaller than 1.
%
% @arg Sequence A sequence of nonnegative rational numbers.
%
% # Algorithm
%
% Return that sequence `s` for which
%
%   - `s_0 = f - 10`
%
%   - `s_{j+1} = (s_j mod 1) - 10`

'FractionDigitRemainderSeq'(0, L):- !,
  inflist(0, L).
'FractionDigitRemainderSeq'(F1, [F0|T]):-
  F0 is F1 * 10,
  F2 is F0 xsd_mod 1,
  'FractionDigitRemainderSeq'(F2, T).



%! fractionDigitSeq(+Fraction:rational, -Sequence:list(between(0,9))) is det.
%
% Maps each nonnegative decimal number less than 1 to a sequence of
% integers used by fractionDigitsCanonicalFragmentMap//1 to ultimately
% create an unsignedNoDecimalPtNumeral//1.
%
% # Arguments
%
% @arg Fraction A nonnegative rational number smaller than 1.
%
% @arg Sequence A sequence of integers where each term is between 0
%               and 9 inclusive.
%
% # Algorithm
%
% For a given fraction `f`, return that sequence `s` for which `s_j =
% FractionDigitRemainderSeq(f)_j div 1`.

fractionDigitSeq(0, L):- !,
  inflist(0, L).
fractionDigitSeq(F1, [F0|T]):-
  F_ is F1 * 10,
  F0 is F_ xsd_div 1,
  F2 is F_ xsd_mod 1,
  fractionDigitSeq(F2, T).



%! fractionDigitsCanonicalFragmentMap(+Fraction:rational)// is det.
%
% Maps each nonnegative decimal number less than 1 to a literal used
% by unsignedDecimalPtCanonicalMap//1 to create an
% unsignedDecimalPtNumeral//1.
%
% # Arguments
%
% @arg Fraction A nonnegative rational number smaller than 1.
%
% # Algorithm
%
% For a given fraction `f`, return:
%
%   - `digit(fractionDigitSeq(f)_0)` &
%
%   - ... &
%
%   - `digit(fractionDigitSeq(f)_{lastSignificantDigit(FractionDigitRemainderSeq(f))})`

fractionDigitsCanonicalFragmentMap(Frac) -->
  {
    fractionDigitSeq(Frac, Seq),
    'FractionDigitRemainderSeq'(Frac, RemSeq),
    lastSignificantDigit(RemSeq, Last),
    length(Ds, Last),
    prefix(Ds, Seq)
  },
  'digit_weight*'(Ds), !.





% Generic Number to Numeral Canonical Mappings %

%! unsignedNoDecimalPtCanonicalMap(+Integer:nonneg)// is det.
%
% Maps a nonnegative integer to a unsignedNoDecimalPtNumeral//1,
% its canonical representation.
%
% # Arguments
%
% @arg Integer A nonnegative integer.
%
% # Algorithm
%
% Given an integer `i`, return:
%   - `digit(digitSeq(i)_{lastSignificantDigit(digitRemainderSeq(i))})`
%   - & ... &
%   - `digit(digitSeq(i)_0)`
%
% Note that the concatenation is in reverse order.

unsignedNoDecimalPtCanonicalMap(N) -->
  {
    digitRemainderSeq(N, RemainderSeq),
    lastSignificantDigit(RemainderSeq, Last),
    digitSeq(N, Seq),
    % Count-by-1.
    length(Ds0, Last),
    prefix(Ds0, Seq),
    reverse(Ds0, Ds)
  },
  ({Ds == []} -> "0" ; 'digit_weight+'(Ds), !).



%! noDecimalPtCanonicalMap(+Integer:integer)// is det.
%
% Maps an integer to a noDecimalPtNumeral//1, its canonical
% representation.
%
% # Arguments
%
% @arg Integer An integer.
%
% # Algorithm
%
% For a given integer `i`, return:
%
%   - `'-'` & `unsignedNoDecimalPtCanonicalMap(-i)`, when `i` is
%     negative
%
%   - `unsignedNoDecimalPtCanonicalMap(i)`, otherwise.

noDecimalPtCanonicalMap(N) -->
  {N < 0}, !,
  "-",
  {N0 is abs(N)},
  unsignedNoDecimalPtCanonicalMap(N0).
noDecimalPtCanonicalMap(N) -->
  unsignedNoDecimalPtCanonicalMap(N).



%! unsignedDecimalPtCanonicalMap(+Decimal:rational)// is det.
%
% Maps a nonnegative decimal number to a unsignedDecimalPtNumeral//1,
% its canonical representation.
%
% # Arguments
%
% @arg Decimal A nonnegative decimal number.
%
% # Algorithm
%
% Return:
%
%   - `unsignedNoDecimalPtCanonicalMap(n div 1)` &
%
%   - `'.'` &
%
%   - `fractionDigitsCanonicalFragmentMap(n mod 1)`

unsignedDecimalPtCanonicalMap(N) -->
  {N1 is N xsd_div 1},
  unsignedNoDecimalPtCanonicalMap(N1),
  ".",
  {N2 is N xsd_mod 1},
  ({N2 =:= 0} -> "" ; fractionDigitsCanonicalFragmentMap(N2)).



%! decimalPtCanonicalMap(+Decimal:rational)// is det.
%
% Maps a decimal number to a decimalPtNumeral//1, its canonical
% representation.
%
% # Arguments
%
% @arg Decimal A decimal number.
%
% # Algorithm
%
% Return:
%
%   - `'-' & unsignedDecimalPtCanonicalMap(-i)`, when `i` is negative
%
%   - `unsignedDecimalPtCanonicalMap(i)`, otherwise

decimalPtCanonicalMap(N) -->
  {N < 0}, !,
  "-",
  {N0 is abs(N)},
  unsignedDecimalPtCanonicalMap(N0).
decimalPtCanonicalMap(N) -->
  unsignedDecimalPtCanonicalMap(N).



%! unsignedScientificCanonicalMap(+Decimal:rational)// is det.
%
% Maps a nonnegative decimal number to a
% unsignedScientificNotationNumeral//1, its canonical representation.
%
% # Arguments
%
% @arg Decimal A nonnegative decimal number.
%
% # Algorithm
%
% Return
%
%   - `unsignedDecimalPtCanonicalMap(n / 10^{log(n) div 1})` &
%
%   - `'E'` &
%
%   - `noDecimalPtCanonicalMap(log(n) div 1)`

unsignedScientificCanonicalMap(N) -->
  {(  N =:= 0
  ->  N1 = 0
  ;   N1 is rationalize(N / 10 ^ (log10(N) xsd_div 1))
  )},
  unsignedDecimalPtCanonicalMap(N1),
  "E",
  {(N =:= 0 -> N2 = 0 ; N2 is rationalize(log10(N) xsd_div 1))},
  noDecimalPtCanonicalMap(N2).



%! scientificCanonicalMap(+Decimal:rational)// is det.
%
% Maps a decimal number to a scientificNotationNumeral//1, its
% canonical representation.
%
% # Arguments
%
% @arg Decimal A decimal number.
%
% # Algorithm
%
% Return:
%
%   - `'-'` & `unsignedScientificCanonicalMap(-n)`, when `n` is
%     negative
%
%   - `unsignedScientificCanonicalMap(i)`, otherwise
%
% @tbd `i` should be `n`.

scientificCanonicalMap(N) -->
  {N < 0}, !,
  "-",
  {N0 is abs(N)},
  unsignedScientificCanonicalMap(N0).
scientificCanonicalMap(N) -->
  unsignedScientificCanonicalMap(N).





% Lexical Mapping for Non-numerical Special Values Used With %
% Numerical Datatypes                                        %

%! specialRepValue(-SpecialValue:atom)// is det.
%
% Maps the lexical representations of special values used with some
% numerical datatypes to those special values.
%
% # Arguments
%
% @arg SpecialValue One of `positiveInfinity`, `negativeInfinity`,
%                   or `notANumber`.
%
% # Algorithm
%
% Return:
%
%   - `positiveInfinity`, when `S` is `'INF'` or `'+INF'`
%
%   - `negativeInfinity`, when `S` is `'-INF'`
%
%   - `notANumber`, when `S` is `'NaN'`

specialRepValue(positiveInfinity) --> "INF",  !.
specialRepValue(positiveInfinity) --> "+INF", !.
specialRepValue(negativeInfinity) --> "-INF", !.
specialRepValue(notANumber) --> "NaN".





% Canonical Mapping for Non-numerical Special Values Used with %
% Numerical Datatypes                                          %

%! specialRepCanonicalMap(+SpecialValue:atom)// is det.
%
% Maps the special values used with some numerical datatypes to their
% canonical representations.
%
% # Arguments
%
% @arg SpecialValue One of `positiveInfinity`, `negativeInfinity`,
%                   and `notANumber`.
%
% # Algorithm
%
% Return:
%
%   - `'INF'`, when `c` is `positiveInfinity`
%
%   - `'-INF'`, when `c` is `negativeInfinity`
%
%   - `'NaN'`, when `c` is `notANumber`

specialRepCanonicalMap(positiveInfinity) --> !, "INF".
specialRepCanonicalMap(negativeInfinity) --> !, "-INF".
specialRepCanonicalMap(notANumber) --> "NaN".



% Lexical Mapping %

%! decimalLexicalMap(-Decimal:rational)// is det.
%
% Maps a decimalLexicalRep//1 onto a decimal value.
%
% # Arguments
%
% @arg Decimal A decimal value.
%
% # Algorithm
%
% Let `d` be a decimal value.
%
% Set `d` to:
%
%   - `noDecimalMap(LEX)`, when `LEX` is an instance of
%     noDecimalPtNumeral//1
%
%   - `decimalPtMap(LEX)`, when `LEX` is an instance of
%     decimalPtNumeral//1 Return `d`.

decimalLexicalMap(N) -->
  decimalPtMap(N), !.
decimalLexicalMap(N) -->
  noDecimalMap(N).





% Canonical Mapping %

%! decimalCanonicalMap(+Decimal:rational)// is det.
%
% Maps a Decimal to its canonical representation, a
% decimalLexicalRep//1.
%
% # Arguments
%
% @arg Decimal A decimal value.
%
% # Algorithm
%
% If `d` is an integer, then return `noDecimalPtCanonicalMap(d)`.
% Otherwise, return `decimalPtCanonicalMap(d)`.

decimalCanonicalMap(N) -->
  {integer(N)}, !,
  noDecimalPtCanonicalMap(N).
decimalCanonicalMap(N) -->
  decimalPtCanonicalMap(N).
