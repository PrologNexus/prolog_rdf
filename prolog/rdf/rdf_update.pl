:- module(
  rdf_update,
  [
    rdf_canonize_graph/1, % +Graph:atom
    rdf_canonize_triple/5, % +Subject:or([bnode,iri])
                           % +Predicate:iri
                           % +Datatype:iri
                           % +LexicalForm:atom
                           % +Graph:atom
    rdf_cp/5, % +FromGraph:atom
              % ?Subject:or([bnode,iri])
              % ?Predicate:iri
              % ?Object:rdf_term
              % +ToGraph:atom
    rdf_increment/5, % +Subject:or([bnode,iri])
                     % +Predicate:iri
                     % -Old:integer
                     % +Graph:atom
                     % -New:integer
    rdf_mv/5 % +FromGraph:atom
             % ?Subject:or([bnode,iri])
             % ?Predicate:iri
             % ?Object:rdf_term
             % +ToGraph:atom
  ]
).

/** <module> RDF update

Higher-level update operations performed on RDF data.

@author Wouter Beek
@version 2015/07-2015/08
*/

:- use_module(library(deb_ext)).
:- use_module(library(rdf/rdf_build)).
:- use_module(library(rdf/rdf_datatype)).
:- use_module(library(rdf/rdf_print)).
:- use_module(library(rdf/rdf_read)).
:- use_module(library(xsd/xsd)).

:- rdf_meta(rdf_canonize_triple(r,r,r,+,+)).
:- rdf_meta(rdf_cp(+,r,r,o,+)).
:- rdf_meta(rdf_increment(r,r,-,+,-)).
:- rdf_meta(rdf_mv(+,r,r,o,+)).





%! rdf_canonize_graph(+Graph:atom) is det.
% Make sure all typed literals in the graph with the given name
% have a lexical form that is a canonical lexical form for its datatype.
%
% This check every RDF triple in the given graph
% that contains a typed literal.

rdf_canonize_graph(G):-
  forall(
    rdf2(S, P, literal(type(D,Lex)), G),
    rdf_canonize_triple(S, P, D, Lex, G)
  ).



%! rdf_canonize_triple(
%!   ?Subject:or([bnode,iri]),
%!   ?Predicate:iri,
%!   ?Datatype:iri,
%!   ?LexicalForm:atom,
%!   ?Graph:atom
%! ) is det.
% Updates a triple whose object term is an RDF literal
% so as to ensure that the same value is denote,
% but by the canonical lexical form for that value.

rdf_canonize_triple(S, P, D, Lex, G):-
  xsd_datatype(D),
  forall(
    rdf(S, P, literal(type(D,Lex)), G),
    (
      rdf_lexical_canonical_map(D, Lex, CLex),

      % Only changes need to be written.
      Lex \== CLex,

      % Perform the update.
      rdf_transaction((
        rdf_retractall2(S, P, literal(type(D,Lex)), G),
        rdf_assert2(S, P, literal(type(D,CLex)), G)
      ))
    )
  ).



%! rdf_cp(
%!   +FromGraph:atom,
%!   ?Subject:or([bnode,iri]),
%!   ?Predicate:iri,
%!   ?Object:rdf_term,
%!   +ToGraph:atom
%! ) is det.
% Copies triples between graphs.
%
% @tbd Perform blank node renaming.

rdf_cp(FromG, S, P, O, ToG):-
  rdf_transaction(rdf_cp0(copied, FromG, S, P, O, ToG)).

rdf_cp0(Action, FromG, S, P, O, ToG):-
  forall(rdf2(S, P, O, FromG), (
    rdf_assert2(S, P, O, ToG),
    if_debug(rdf(update), (
      with_output_to(atom(T), rdf_print_triple(S, P, O)),
      debug(rdf(update), '[~a] ~a   -----~a----->   ~a~n', [Action,FromG,T,ToG])
    ))
  )).



%! rdf_increment(
%!   +Subject:or([bnode,iri]),
%!   +Predicate:iri,
%!   -Old:integer,
%!   +Graph:atom,
%!   -New:integer
%! ) is det.

rdf_increment(S, P, Old, G, New):-
  rdf_transaction((
    rdf_literal(S, P, D, Old, G),

    % Any integer datatype can be incremented.
    once(rdf_subtype_of(D, xsd:integer)),
    rdf_retractall_literal(S, P, D, Old, G),
    succ(Old, New),

    % Make sure the new value belongs to the datatype's value space.
    rdf_canonical_map(D, New, _),
    rdf_assert_literal(D, P, D, New, G)
  )).



%! rdf_mv(
%!   +FromGraph:atom,
%!   ?Subject:or([bnode,iri]),
%!   ?Predicate:iri,
%!   ?Object:rdf_term,
%!   +ToGraph:atom
%! ) is det.
% Move triples between graphs.

rdf_mv(FromG, S, P, O, ToG):-
  rdf_transaction((
    rdf_cp0(moved, FromG, S, P, O, ToG),
    rdf_retractall2(S, P, O, FromG)
  )).
