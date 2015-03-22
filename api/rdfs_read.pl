:- module(
  rdfs_read,
  [
    rdfs_label/4, % ??Subject:or([bnode,iri])
                  % ?Value
                  % ?LangTagPreference:list(list(atom))
                  % ?Graph:atom
    rdfs_label_value/2, % ?Subject:or([bnode,iri])
                        % ?Label:atom
    rdfs_label_value/3, % ?Subject:or([bnode,iri])
                        % ?Label:atom
                        % ?LangTagPreference:list(list(atom))
    rdfs_label_value/4 % ?Subject:or([bnode,iri])
                       % ?Label:atom
                       % ?LangTagPreference:list(list(atom))
                       % ?Graph:atom
  ]
).

/** <module> RDFS Read API

@author Wouter Beek
@version 2014/11-2015/03
*/

:- use_module(library(lists), except([delete/3,subset/2])).
:- use_module(library(semweb/rdf_db), except([rdf_node/1])).

:- use_module(plRdf(api/rdf_read)).
:- use_module(plRdf(term/rdf_term)).

:- rdf_meta(rdfs_label(r,?,?,?)).
:- rdf_meta(rdfs_label_value(r,?)).
:- rdf_meta(rdfs_label_value(r,?,?)).
:- rdf_meta(rdfs_label_value(r,?,?,?)).





%! rdfs_label(
%!   ?Subject:or([bnode,iri]),
%!   ?Value,
%!   ?LangTagPreference:list(list(atom)),
%!   ?Graph:atom
%! ) is nondet.
% Reads RDFS labels attributed to resources.

rdfs_label(S, Value, LangPrefs, Graph):-
  rdf_plain_literal(S, rdfs:label, Value, LangPrefs, Graph).



%! rdfs_label_value(?Subject:or([bnode,iri]), ?Label:atom) is nondet.

rdfs_label_value(S, Label):-
  rdfs_label_value(S, Label, _, _).

%! rdfs_label_value(
%!   ?Subject:or([bnode,iri]),
%!   ?Label:atom,
%!   ?LangTagPreference:list(list(atom))
%! ) is nondet.

rdfs_label_value(S, Label, LangPrefs):-
  rdfs_label_value(S, Label, LangPrefs, _).

%! rdfs_label_value(
%!   ?Subject:or([bnode,iri]),
%!   ?Label:atom,
%!   ?LangTagPreference:list(list(atom)),
%!   ?Graph:atom
%! ) is nondet.
% Since RDFS labels can be of type `rdf:langTag` or `xsd:string`,
% the `Value` returned by rdfs_label/4 can be either an atom or a pair.
%
% This predicate normalizes argument Label.
% It is either the full `Value` (if `xsd:string`)
% or the second argument of the pair (if `rdf:langTag`).

rdfs_label_value(S, Label, LangPrefs, Graph):-
  rdfs_label(S, Value, LangPrefs, Graph),
  (   Value = Label-_
  ->  true
  ;   Label = Value
  ).
