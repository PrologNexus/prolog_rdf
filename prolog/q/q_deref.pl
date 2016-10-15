:- module(
  q_deref,
  [
    q_cache_iri/2,        % +M, +Iri
    q_cache_iris/1,       % +M
    q_cached_iri/1,       % ?Iri
    q_cached_iri_graph/2, % ?Iri, ?G
    q_deref/2,            % +Iri, -Tuple
    q_deref_triple/2      % +Iri, -Triple
  ]
).

/** <module> Quine: IRI dereferencing & caching

@author Wouter Beek
@version 2016/10
*/

:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(debug_ext)).
:- use_module(library(http/http_ext)).
:- use_module(library(iri/iri_ext)).
:- use_module(library(lists)).
:- use_module(library(option)).
:- use_module(library(pool)).
:- use_module(library(q/q_print)).
:- use_module(library(q/q_term)).
:- use_module(library(rdf/rdf__io)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(yall)).

:- rdf_meta
   q_cache_iri(+, r),
   q_cached_iri(r),
   q_cached_iri_graph(r, r),
   q_deref(r, -),
   q_deref_triple(r, -).





%! q_cache_iri(+M, +Iri) is det.

q_cache_iri(M, Iri) :-
  q_cached_iri_graph(Iri, G),
  forall(
    q_deref_triple(Iri, Triple),
    qb(M, Triple, G)
  ).



%! q_cache_iris(+M) is det.
%! q_cache_iris(+M, +Opts) is det.
%
% The following options are supported:
%
%   * excluded_authorities(+list(atom))
%
%     Default is [].
%
%   * number_of_workers(+nonneg)
%
%     Default is 1.
%
%   * Other options are passed to add_worker/3.

q_cache_iris(M) :-
  q_cache_iris(M, []).


q_cache_iris(M, Opts1) :-
  Pool = qc,
  forall(
    distinct(Iri, q_external_iri(M, Iri)),
    add_resource(Pool, Iri)
  ),
  select_option(number_of_workers(N), Opts1, Opts2, 1),
  forall(
    between(1, N, _),
    add_worker(Pool, q_cache_iris_worker(M, Opts2), Opts2)
  ).

q_cache_iris_worker(M, Opts, Iri, NewIris) :-
  (   q_is_external_iri(M, Iri)
  ->  if_debug(rdf(deref), print_pool(qc)),
      aggregate_all(
        set(NewIri),
        (
          q_deref_triple(Iri, Triple),
          qb(M, Triple, G),
          q_triple_iri(Triple, NewIri)
        ),
        NewIris
      )
  ;   Iris = [],
      debug(rdf(deref), "Skipping non-IRI or internal IRI: ~w", [S])
  ).



%! q_cached_iri(+Iri) is semidet.
%! q_cached_iri(-Iri) is nondet.
%
% Enumerates IRIs whose dereference has been cached.

q_cached_iri(Iri) :-
  var(Iri), !,
  q_graph(G),
  q_cached_iri_graph(Iri, G).
q_cached_iri(Iri) :-
  q_cahced_iri_graph(Iri, G),
  q_graph(G).



%! q_cached_iri_graph(+Iri, +G) is semidet.
%! q_cached_iri_graph(+Iri, -G) is det.
%! q_cached_iri_graph(-Iri, +G) is det.

q_cached_iri_graph(Iri, G) :-
  var(Iri), !,
  q_iri_alias_local(G, gc, Enc),
  base64url(Iri, Enc).
q_cached_iri_graph(Iri, G) :-
  base64url(Iri, Enc),
  q_iri_alias_local(G, qc, Enc).



%! q_deref(+Iri, -Tuple) is nondet.

q_deref(Iri, Tuple) :-
  call_or_exception(rdf_load_quads(Iri, Tuples)),
  member(Tuple, Tuples).



%! q_deref_triple(+Iri, -Triple) is nondet.
%
% @see Like q_deref/2, but always returns a triple.

q_deref_triple(Iri, Triple) :-
  q_deref(Iri, Tuple),
  q_tuple_triple(Tuple, Triple).
