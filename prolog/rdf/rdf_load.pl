:- module(
  rdf_load,
  [
    rdf_load_file/1, % +Spec
    rdf_load_file/2, % +Spec
                     % +Options:list(compound)
    rdf_load_triple/2 % +Spec
                      % :Goal_2
  ]
).

/** <module> RDF load

Support for loading RDF data.

@author Wouter Beek
@tbd Make rdf_load_triple/2 simply return triples non-deterministically.
@version 2015/08
*/

:- use_module(library(option)).
:- use_module(library(lists)).
:- use_module(library(rdf)).
:- use_module(library(rdf/rdf_stream)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/rdf_ntriples)).
:- use_module(library(semweb/turtle)).
:- use_module(library(uuid_ext)).

:- meta_predicate(rdf_load_triple(+,2)).





%! rdf_load_file(+Spec) is det.

rdf_load_file(Spec):-
  rdf_load_file(Spec, []).

%! rdf_load_file(+Spec, +Options:list(compound)) is det.
% Options are passed to rdf_load/2.

rdf_load_file(Spec, Opts0):-
  % Set the graph name.
  option(graph(G), Opts0, _VAR),
  (   var(G),
      atom(Spec)
  ->  G = Spec
  ;   true
  ),
  merge_options([graph(G)], Opts0, Opts),
  rdf_stream_read(Spec, rdf_load_file0(Opts), Opts).

rdf_load_file0(Opts0, BaseIri, Format, Read):-
  merge_options([base_iri(BaseIri),format(Format)], Opts0, Opts),
  rdf_load(Read, Opts).



%! rdf_load_triple(+Spec, :Goal_2) is nondet.

rdf_load_triple(Spec, Goal_2):-
  rdf_stream_read(Spec, rdf_load_triple0(Goal_2), []).

%! rdf_load_triple0(:Goal_2, +BaseIri:atom, +Format:atom, +Read:stream) is det.

rdf_load_triple0(Goal_2, BaseIri, Format, Read):-
  memberchk(Format, [nquads,ntriples]), !,
  rdf_process_ntriples(Read, Goal_2, [base_uri(BaseIri)]).
rdf_load_triple0(Goal_2, BaseIri, Format, Read):-
  memberchk(Format, [trig,turtle]), !,
  uuid_no_hyphen(Prefix0),
  atomic_list_concat(['__',Prefix0,':'], Prefix),
  rdf_process_turtle(Read, Goal_2, [anon_prefix(Prefix),base_uri(BaseIri)]).
rdf_load_triple0(Goal_2, BaseIri, xml, Read):- !,
  process_rdf(Read, Goal_2, [base_uri(BaseIri)]).
rdf_load_triple0(_, _, Format, _):-
  format(user_error, 'Unrecognized RDF serialization format: ~a~n', [Format]).
