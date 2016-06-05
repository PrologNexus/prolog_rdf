:- module(
  geold,
  [
    geold_array2wkt/0,
    geold_flatten_geometry/0,
    geold_flatten_geometry/1, % ?G
    geold_print_feature/1,    % ?Feature
    geold_rm_feature_collections/0,
    geold_tuple/2,  % +Source, -Tuple
    geold_tuple/4,  % +Source, +ExtraContext, +ExtraData, -Tuple
    geold_tuples/2, % +Source, -Tuples
    geold_tuples/4  % +Source, +ExtraContext, +ExtraData, -Tuples
  ]
).

/** <module> GeoJSON-LD

http://www.opengis.net/ont/geosparql#asWKT
"POINT(-84.22924230000001 39.596629500000006)"

@author Wouter Beek
@version 2016/05-2016/06
*/

:- use_module(library(aggregate)).
:- use_module(library(cli/rc)).
:- use_module(library(dcg/dcg_ext)).
:- use_module(library(dict_ext)).
:- use_module(library(geo/wkt)).
:- use_module(library(json_ext)).
:- use_module(library(jsonld/jsonld_array)).
:- use_module(library(jsonld/jsonld_read)).
:- use_module(library(print_ext)).
:- use_module(library(rdf/rdf_ext)).
:- use_module(library(rdf/rdf_term)).
:- use_module(library(rdf/rdf_update)).
:- use_module(library(rdfs/rdfs_ext)).
:- use_module(library(semweb/rdf11)).

:- rdf_register_prefix(geold, 'http://geojsonld.com/vocab#').
:- rdf_register_prefix(tcco, 'http://triply.cc/ontology/').
:- rdf_register_prefix(wkt, 'http://geojsonld.com/wkt#').

:- rdf_meta
   geold_geometry_class(r),
   geold_geometry_class(r, ?),
   geold_print_feature(r).

:- dynamic
    gis:resource_shape_hook/3.

:- multifile
    gis:resource_shape_hook/3.

gis:resource_shape_hook(Res, Shape, G) :-
  rdf_has(Res, geold:geometry, Lex^^D, _, G),
  rdf_global_id(wkt:Name, D),
  string_phrase(wkt(Name, Array), Lex),
  array2shape(Array, Name, Shape).


%polygon([[[point([[5.472025742797797,51.35046476465081,5.472040381482079,51.350393787984586],[5.472096228698165,51.350398304507394,5.472081590099213,51.3504692811806],[5.472025742797797,51.35046476465081]],[[5.472031650727821,51.35046147945612,5.472075136148579,51.35046455782218],[5.472087654571696,51.35040358714889,5.472044585269217,51.35040039163047],[5.472031650727821,51.35046147945612]])]]])
%polygon([[point(52.1335811883338,4.24342337208216),point(52.1240808418951,4.23342263416468),point(52.1827499743908,3.87006309399112),point(52.0599123264119,3.27368644149239),point(52.076579608387,3.2736864626958),point(52.1994172644824,3.87006311490954),point(52.1335811883338,4.24342337208216)]])

array2shape(L1, linestring, linestring(L2)) :- !,
  maplist(point0, L1, L2).
array2shape([L1], multipolygon, polygon([L2])) :- !,
  maplist(point0, L1, L2).
array2shape([X,Y], point, point(X,Y)) :- !.
array2shape([X,Y,Z], point, point(X,Y,Z)) :- !.
array2shape([X,Y,Z,M], point, point(X,Y,Z,M)) :- !.
array2shape([L1], polygon, polygon([L2])) :- !,
  maplist(point0, L1, L2).


point0([X,Y], point(X,Y)).



%! geold_array2wkt is nondet.
%
% Transforms JSON-LD arrays (see module [[jsonld_array]]) into
% Well-Known Text literals (see module [[wkt]]).

geold_array2wkt :-
  geold_array2wkt(_{count:0}).


geold_array2wkt(State) :-
  geold_geometry_class(C, Name),
  rdfs_instance(I, C),
  rdf_has(I, geold:coordinates, Lex1^^tcco:array),
  string_phrase(array(Array), Lex1),
  string_phrase(wkt(Name, Array), Lex2),
  rdf_global_id(wkt:Name, D),
  rdf_change(I, geold:coordinates, Lex1^^tcco:array, object(Lex2^^D)),
  dict_inc(count, State),
  fail.
geold_array2wkt(State) :-
  ansi_format(user_output, [fg(yellow)], "~D arrays to WKT.~n", [State.count]).



%! geold_context(-Context) is det.
%
% The default GeoJSON-LD context.

geold_context(_{
  coordinates: _{'@id': 'geold:coordinates', '@type': '@array'},
  crs: 'geold:crs',
  geo : 'http://www.opengis.net/ont/geosparql#',
  geold: 'http://geojsonld.com/vocab#',
  geometry: 'geold:geometry',
  'GeometryCollection': 'geold:GeometryCollection',
  'Feature': 'geold:Feature',
  'FeatureCollection': 'geold:FeatureCollection',
  features: 'geold:features',
  'LineString': 'geold:LineString',
  'MultiLineString': 'geold:MultiLineString',
  'MultiPoint': 'geold:MultiPoint',
  'MultiPolygon': 'geold:MultiPolygon',
  'Point': 'geold:Point',
  'Polygon': 'geold:Polygon',
  properties: 'geold:properties',
  type: '@type',
  '@vocab': 'http://example.org/'
}).



%! geold_flatten_geometry is det.

geold_flatten_geometry :-
  geold_flatten_geometry(_).


geold_flatten_geometry(G) :-
  geold_flatten_geometry0(_{count:0}, G).


geold_flatten_geometry0(State, G) :-
  rdf(S, geold:geometry, B, G),
  rdf(B, geold:coordinates, Lit, G),
  rdf_assert(S, geold:geometry, Lit, G),
  rdf_retractall(S, geold:geometry, B, G),
  rdf_retractall(B, geold:coordinates, Lit, G),
  rdf_retractall(B, rdf:type, _, G),
  dict_inc(count, State),
  fail.
geold_flatten_geometry0(State, _) :-
  rdf_update:rdf_msg(State.count, "flattened").



%! geold_geometry_class(?C) is semidet.
%! geold_geometry_class(?C, ?Name) is semidet.

geold_geometry_class(C) :-
  geold_geometry_class(C, _).


geold_geometry_class(geold:'MultiPolygon', multipolygon).
geold_geometry_class(geold:'Point', point).
geold_geometry_class(geold:'Polygon', polygon).



%! geold_print_feature(?Feature) is nondet.

geold_print_feature(I) :-
  rdfs_instance(I, geold:'Feature'),
  rc_cbd(I).



%! geold_tuple(+Source, -Tuple) is det.
%! geold_tuple(+Source, +ExtraContext, +ExtraData, -Tuple) is det.

geold_tuple(Source, Tuple) :-
  geold_tuple(Source, _{}, _{}, Tuple).


geold_tuple(Source, ExtraContext, ExtraData, Tuple) :-
  geold_prepare(Source, ExtraContext, Context, ExtraData, Data),
  jsonld_tuple_with_context(Context, Data, Tuple).



%! geold_tuples(+Source, -Tuples) is det.
%! geold_tuples(+Source, +ExtraContext, +ExtraData, -Tuples) is det.

geold_tuples(Source, Tuples) :-
  geold_tuples(Source, _{}, Tuples).


geold_tuples(Source, ExtraContext, ExtraData, Tuples) :-
  geold_prepare(Source, ExtraContext, Context, ExtraData, Data),
  aggregate_all(
    set(Tuple),
    jsonld_tuple_with_context(Context, Data, Tuple),
    Tuples
  ).



%! geold_rm_feature_collections is det.
%
% Remove all GeoJSON FeatureCollections, since these are mere
% artifacts.

geold_rm_feature_collections :-
  rdf_rm_col(geold:features),
  rdf_rm(_, rdf:type, geold:'FeatureCollection').





% HELPERS %

%! geold_prepare(+Source, +ExtraContext, -Context, +ExtraData, -Data) is det.

geold_prepare(Source, ExtraContext, Context, ExtraData, Data) :-
  geold_prepare_context(ExtraContext, Context),
  geold_prepare_data(Source, ExtraData, Data).



%! geold_prepare_context(+ExtraContext, -Context) is det.

geold_prepare_context(ExtraContext, Context) :-
  geold_context(Context0),
  Context = Context0.put(ExtraContext).



%! geold_prepare_data(+Source, +ExtraData, -Data) is det.

geold_prepare_data(Source, ExtraData, Data) :-
  json_read_any(Source, Data0),
  Data = Data0.put(ExtraData).
