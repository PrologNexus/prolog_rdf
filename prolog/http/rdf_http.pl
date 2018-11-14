:- encoding(utf8).
:- module(
  rdf_http,
  [
    rdf_http_query/2 % +Parameters, -Query
  ]
).

/** <module> HTTP support for RDF

@author Wouter Beek
@version 2018
*/

:- use_module(library(error)).

:- use_module(library(semweb/rdf_term)).

:- multifile
    http:convert_parameter/3,
    http:error_status_message_hook/3.

http:convert_parameter(rdf_term, Atom, G) :-
  rdf_atom_term(Atom, G).

http:error_status_message_hook(rdf(cannot_parse(rdf_term,Atom)), 400, Msg) :-
  format(
    string(Msg),
    "😿 Your request is incorrect!  You have specified the value ‘~a’, but this cannot be parsed as an RDF term.",
    [Atom]
  ).





%! rdf_http_query(+Parameters:list(compound), -Query:list(compound)) is det.

% skip non-ground terms
rdf_http_query([NonGround|T1], T2) :-
  \+ ground(NonGround), !,
  rdf_http_query(T1, T2).
% graph
rdf_http_query([g(G)|T1], T2) :-
  rdf_default_graph(G), !,
  rdf_http_query(T1, T2).
rdf_http_query([g(G)|T1], [g(Atom)|T2]) :- !,
  rdf_atom_term(Atom, G),
  rdf_http_query(T1, T2).
% object
rdf_http_query([o(O)|T1], [o(Atom)|T2]) :- !,
  rdf_atom_term(Atom, O),
  rdf_http_query(T1, T2).
% predicate
rdf_http_query([p(P)|T1], [p(Atom)|T2]) :- !,
  rdf_atom_term(Atom, P),
  rdf_http_query(T1, T2).
% subject
rdf_http_query([s(S)|T1], [s(Atom)|T2]) :- !,
  rdf_atom_term(Atom, S),
  rdf_http_query(T1, T2).
% term
rdf_http_query([term(Term)|T1], [term(Atom)|T2]) :- !,
  rdf_atom_term(Atom, Term),
  rdf_http_query(T1, T2).
% done!
rdf_http_query([], []).
