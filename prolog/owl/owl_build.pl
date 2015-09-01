:- module(
  owl_build,
  [
    owl_assert_class/5, % +Class:iri
                        % ?ParentClass:iri
                        % ?Label:or([atom,pair(atom)])
                        % ?Comment:or([atom,pair(atom)])
                        % ?Graph:atom
    owl_assert_data_property/2, % +Property:iri
                                % ?Graph:atom
    owl_assert_data_property/8, % +Property:iri
                                % ?ParentProperty:iri
                                % ?Label:or([atom,pair(atom)])
                                % ?Comment:or([atom,pair(atom)])
                                % ?Domain:or([bnode,iri])
                                % ?Range:or([bnode,iri])
                                % ?Graph:atom
                                % +Options:list(compound)
    owl_assert_functional_property/2, % +Property:iri
                                      % ?Graph:atom
    owl_assert_object_property/2, % +Property:iri
                                  % ?Graph:atom
    owl_assert_ontology/2, % +Ontology:or([bnode,iri])
                           % ?Graph:atom
    owl_assert_object_property/8, % +Property:iri
                                  % ?ParentProperty:iri
                                  % ?Label:or([atom,pair(atom)])
                                  % ?Comment:or([atom,pair(atom)])
                                  % ?Domain:or([bnode,iri])
                                  % ?Range:or([bnode,iri])
                                  % ?Graph:atom
                                  % +Options:list(compound)
    owl_assert_value_restriction/4 % +Property:or([bnode,iri])
                                   % +Value:or([bnode,iri])
                                   % ?Graph:atom
                                   % -Restriction:bnode
  ]
).

/** <module> OWL build

Predicates for asserting common OWL structures.

@author Wouter Beek
@version 2015/08-2015/09
*/

:- use_module(library(option)).
:- use_module(library(rdfs/rdfs_build)).

:- predicate_options(owl_assert_data_property/8, 8, [
     pass_to(owl_assert_property/8, 8)
   ]).
:- predicate_options(owl_assert_object_property/8, 8, [
     pass_to(owl_assert_property/8, 8)
   ]).
:- predicate_options(owl_assert_property/8, 8, [
     functional(+boolean)
   ]).

:- rdf_meta(owl_assert_class(r,r,?,?,?)).
:- rdf_meta(owl_assert_data_property(r,?)).
:- rdf_meta(owl_assert_data_property(r,r,+,+,r,r,?,+)).
:- rdf_meta(owl_assert_functional_property(r,?)).
:- rdf_meta(owl_assert_object_property(r,?)).
:- rdf_meta(owl_assert_object_property(r,r,+,+,r,r,?,+)).
:- rdf_meta(owl_assert_ontology(r,?)).
:- rdf_meta(owl_assert_value_restriction(r,r,?,-)).





%! owl_assert_class(
%!   +Class:iri,
%!   ?Parent:iri,
%!   ?Label:or([atom,pair(atom)]),
%!   ?Comment:or([atom,pair(atom)]),
%!   ?Graph:atom
%! ) is det.

owl_assert_class(C, Parent, Lbl, Comm, G):-
  rdf_assert_instance(C, owl:'Class', G),
  rdfs_build:assert_class(C, Parent, Lbl, Comm, G).



%! owl_assert_data_property(+Property:iri, ?Graph:atom) is det.

owl_assert_data_property(I, G):-
  rdf_assert_instance(I, owl:'DataProperty', G).

%! owl_assert_data_property(
%!   +Property:iri,
%!   ?ParentProperty:iri,
%!   ?Label:or([atom,pair(atom)]),
%!   ?Comment:or([atom,pair(atom)]),
%!   ?Domain:or([bnode,iri]),
%!   ?Range:or([bnode,iri]),
%!   ?Graph:atom,
%!   +Options:list(compound)
%! ) is det.
% The following options are supported:
%   * functional(+boolean)

owl_assert_data_property(P, Parent, Lbl, Comm, D, R, G, Opts):-
  owl_assert_data_property(P, G),
  owl_assert_property(P, Parent, Lbl, Comm, D, R, G, Opts).



%! owl_assert_functional_property(+Property:iri, ?Graph:atom) is det.

owl_assert_functional_property(I, G):-
  rdf_assert_instance(I, owl:'FunctionalProperty', G).



%! owl_assert_object_property(+Property:iri, ?Graph:atom) is det.

owl_assert_object_property(I, G):-
  rdf_assert_instance(I, owl:'ObjectProperty', G).

%! owl_assert_object_property(
%!   +Property:iri,
%!   ?ParentProperty:iri,
%!   ?Label:or([atom,pair(atom)]),
%!   ?Comment:or([atom,pair(atom)]),
%!   ?Domain:or([bnode,iri]),
%!   ?Range:or([bnode,iri]),
%!   ?Graph:atom,
%!   +Options:list(compound)
%! ) is det.
% The following options are supported:
%   * functional(+boolean)

owl_assert_object_property(P, Parent, Lbl, Comm, D, R, G, Opts):-
  owl_assert_object_property(P, G),
  owl_assert_property(P, Parent, Lbl, Comm, D, R, G, Opts).



%! owl_assert_ontology(+Ontology:or([bnode,iri]), ?Graph:atom) is det.

owl_assert_ontology(I, G):-
  rdf_assert_instance(I, owl:'Ontology', G).



%! owl_assert_value_restriction(
%!   +Property:iri,
%!   +Value:or([bnode,iri]),
%!   ?Graph:atom,
%!   -Restriction:bnode
%! ) is det.

owl_assert_value_restriction(P, V, G, R):-
  rdf_bnode(R),
  rdf_assert_instance(R, owl:'Restriction', G),
  rdf_assert2(R, owl:onProperty, P, G),
  rdf_assert2(R, owl:hasValue, V, G).





% HELPERS %

%! owl_assert_property(
%!   +Property:iri,
%!   ?ParentProperty:iri,
%!   ?Label:or([atom,pair(atom)]),
%!   ?Comment:or([atom,pair(atom)]),
%!   ?Domain:or([bnode,iri]),
%!   ?Range:or([bnode,iri]),
%!   ?Graph:atom,
%!   +Options:list(compound)
%! ) is det.

owl_assert_property(P, Parent, Lbl, Comm, D, R, G, Opts):-
  (   option(functional(true), Opts)
  ->  owl_assert_functional_property(P, G)
  ;   true
  ),
  (var(Parent) -> true ; rdfs_assert_subproperty(P, Parent, G)),
  (var(Lbl) -> true ; rdfs_assert_label(P, Lbl, G)),
  (var(Comm) -> true ; rdfs_assert_comment(P, Comm, G)),
  (var(D) -> true ; rdfs_assert_domain(P, D, G)),
  (var(R) -> true ; rdfs_assert_range(P, R, G)),
  rdfs_assert_isDefinedBy(P, G).
