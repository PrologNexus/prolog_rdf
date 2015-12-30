:- module(
  rdf_print,
  [
    rdf_print_deref/1, % +Subject
    rdf_print_deref/2, % +Subject:iri
                       % +Options:list(compound)
    rdf_print_describe/1, % +Subject
    rdf_print_describe/2, % +Subject, +Options
    rdf_print_describe/3, % +Subject:rdf_term
                          % ?Graph:rdf_graph
                          % +Options:list(compound)
    rdf_print_graph/1, % ?Graph
    rdf_print_graph/2, % ?Graph:rdf_graph
                       % +Options:list(compound)
    rdf_print_graphs/0,
    rdf_print_graphs/1 % +Options:list(compound)
  ]
).
:- reexport(library(rdf/rdf_print_stmt)).
:- reexport(library(rdf/rdf_print_term)).

/** <module> RDF print

Printing of RDF statements to a text-based output stream.

@author Wouter Beek
@version 2015/07-2015/09, 2015/12
*/

:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(dcg/dcg_phrase)).
:- use_module(library(dcg/dcg_table)).
:- use_module(library(error)).
:- use_module(library(lists)).
:- use_module(library(pair_ext)).
:- use_module(library(rdf/rdf_deref)).
:- use_module(library(rdf/rdf_graph)).
:- use_module(library(rdf/rdf_stats)).

:- set_prolog_flag(toplevel_print_anon, false).

:- rdf_meta(rdf_print_deref(r)).
:- rdf_meta(rdf_print_deref(r,+)).
:- rdf_meta(rdf_print_describe(o)).
:- rdf_meta(rdf_print_describe(o,+)).
:- rdf_meta(rdf_print_describe(o,r,+)).
:- rdf_meta(rdf_print_graph(r)).
:- rdf_meta(rdf_print_graph(r,+)).

:- predicate_options(rdf_print_deref/2, 2, [
     pass_to(rdf_print_triple/5, 5)
   ]).
:- predicate_options(rdf_print_describe/2, 2, [
     pass_to(rdf_print_describe/3, 3)
   ]).
:- predicate_options(rdf_print_describe/3, 3, [
     pass_to(rdf_print_statement/5, 5)
   ]).
:- predicate_options(rdf_print_graph/2, 2, [
     pass_to(rdf_print_quadruple/5, 5),
     pass_to(rdf_print_triple/5, 5)
   ]).
:- predicate_options(rdf_print_graphs/1, 1, [
     pass_to(dcg_table//2, 2)
   ]).





%! rdf_print_deref(+Subject:iri) is det.
% Wrapper around rdf_print_deref/2 with default options.

rdf_print_deref(S):-
  rdf_print_deref(S, []).


%! rdf_print_deref(+Subject:iri, +Options:list(compound)) is det.

rdf_print_deref(S, Opts):-
  forall(rdf_deref(S, P, O), rdf_print_triple(S, P, O, _, Opts)).



%! rdf_print_describe(+Subject:rdf_term) is det.
% Wrapper around rdf_print_describe/2 with default options.

rdf_print_describe(S):-
  rdf_print_describe(S, none, []).


%! rdf_print_describe(+Subject:rdf_term, +Options:list(compound)) is det.
% Wrapper around rdf_print_describe/3 with uninstantiated graph.

rdf_print_describe(S, Opts):-
  rdf_print_describe(S, none, Opts).


%! rdf_print_describe(
%!   +Subject:rdf_term,
%!   ?Graph:rdf_graph,
%!   +Options:list(compound)
%! ) is det.
% The following options are supported:
%   * abbr_iri(+boolean)
%   * abbr_list(+boolean)
%   * ellip_lit(+or([nonneg,oneof([inf])]))
%   * id_closure(+boolean)
%   * indent(+nonneg)
%   * label_iri(+boolean)
%   * language_priority_list(+list(atom))
%   * symbol_iri(+boolean)

rdf_print_describe(S, G, Opts):-
  (   G == none
  ->  forall(rdf_print_triple(S, _, _, _, Opts), true)
  ;   var(G)
  ->  % No graph is given: display quadruples.
      forall(rdf_print_quadruple(S, _, _, G, Opts), true)
  ;   % A graph is given: display triples.
      forall(rdf_print_triple(S, _, _, G, Opts), true)
  ).



%! rdf_print_graph(?Graph:rdf_graph) is det.

rdf_print_graph(G):-
  rdf_print_graph(G, []).


%! rdf_print_graph(?Graph:rdf_graph, +Options:list(compound)) is det.
% The following options are supported:
%   * abbr_iri(+boolean)
%   * abbr_list(+boolean)
%   * ellip_lit(+or([nonneg,oneof([inf])]))
%   * id_closure(+boolean)
%   * indent(+nonneg)
%   * label_iri(+boolean)
%   * language_priority_list(+list(atom))
%   * symbol_iri(+boolean)
%
% @throws existence_error

rdf_print_graph(G, Opts):-
  (   var(G)
  ->  rdf_print_quadruple(_, _, _, _, Opts),
      fail
  ;   rdf_is_graph(G)
  ->  rdf_print_triple(_, _, _, G, Opts),
      fail
  ;   existence_error(rdf_graph, G)
  ).
rdf_print_graph(_, _).



%! rdf_print_graphs is det.
% Wrapper around rdf_print_graphs/1 with default options.

rdf_print_graphs:-
  rdf_print_graphs([maximum_number_of_rows(50)]).


%! rdf_print_graphs(+Options:list(compound)) is det.
% Options are passed to dcg_table//2.

rdf_print_graphs(Opts):-
  aggregate_all(set(N-G), rdf_number_of_triples(G, N), Pairs1),
  reverse(Pairs1, Pairs2),
  maplist(inverse_pair, Pairs2, Pairs3),
  maplist(pair_list, Pairs3, DataRows),
  dcg_with_output_to(
    user_output,
    dcg_table([head(['Graph','Number of statements'])|DataRows], Opts)
  ).
