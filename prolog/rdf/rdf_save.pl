:- module(
  rdf_save,
  [
    rdf_save_file/1,     % ?Sink
    rdf_save_file/2,     % ?Sink,          +Opts
    rdf_call_to_graph/2, % +Sink, :Goal_1
    rdf_call_to_graph/3  % +Sink, :Goal_1, +Opts
  ]
).

/** <module> Save RDF data

@author Wouter Beek
@version 2015/08, 2015/10-2016/02, 2016/04
*/

:- use_module(library(debug)).
:- use_module(library(gen/gen_ntuples)).
:- use_module(library(iostream)).
:- use_module(library(option)).
:- use_module(library(os/file_ext)).
:- use_module(library(os/open_any2)).
:- use_module(library(rdf/rdf_file)). % Type definition.
:- use_module(library(rdf/rdf_graph)).
:- use_module(library(rdf/rdf_stream)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(semweb/rdf_db), [rdf_save/2 as rdf_save_xmlrdf]).
:- use_module(library(semweb/rdf_turtle_write)).
:- use_module(library(uri)).
:- use_module(library(yall)).

:- meta_predicate
    rdf_call_to_graph(+, 1),
    rdf_call_to_graph(+, 1, +),
    rdf_call_to_graph0(+, 1, +).

:- rdf_meta
   rdf_save_file(+, t).





%! rdf_save_file(+Sink) is det.
%! rdf_save_file(+Sink, +Opts) is det.
% The following options are supported:
%   * rdf_format(+rdf_format)
%   * graph(+iri)

rdf_save_file(Sink) :-
  rdf_save_file(Sink, []).


% The file name can be derived from the graph.
rdf_save_file(Sink, Opts) :-
  var(Sink),
  option(graph(G0), Opts),
  rdf_graph_property(G0, source(File0)), !,
  uri_file_name(File0, File),
  rdf_save_file(File, Opts).
% A new file name is created based on graph and serialization format.
rdf_save_file(Sink, Opts) :-
  var(Sink), !,
  option(graph(Base), Opts, out),
  % In case a serialization format is specified,
  % we use the appropriate file extension.
  (   option(rdf_format(Format), Opts)
  ->  rdf_file_extension(Ext, Format),
      file_name_extension(Base, Ext, Local)
  ;   Local = Base
  ),
  absolute_file_name(Local, File, [access(write)]),
  rdf_save_file(File, Opts).
% We do not need to save the graph if:
%   1. the contents of the graph did not change, and
%   2. the serialization format of the graph did not change, and
%   3. the output file is the same.
rdf_save_file(File, Opts) :-
  is_absolute_file_name(File),
  option(graph(G), Opts),
  
  % The graph was not modified after the last save operation.
  rdf_graph_property(G, modified(false)),
  
  % The given file is the source of the given graph.
  rdf_graph_property(G, source(File0)),
  uri_file_name(File0, File),
  
  % The file was not modified after the graph was loaded.
  rdf_graph_property(G, source_last_modified(LMod)),
  exists_file(File),
  time_file(File, LMod), !,
  debug(rdf(save), "No need to save graph ~w; no updates.", [G]).
rdf_save_file(Sink, Opts) :-
  % Determine the RDF output format:
  %   1. By option.
  %   2. By file name extension.
  %   3. Default to `nquads'.
  (   option(rdf_format(Format), Opts)
  ->  true
  ;   is_absolute_file_name(Sink),
      file_name_extension(_, Ext, Sink),
      rdf_file_extension(Ext, Format)
  ->  true
  ;   Format = nquads
  ),

  % Make sure the directory exists.
  (is_absolute_file_name(Sink) -> create_file_directory(Sink) ; true),
  
  call_to_stream(Sink, [Out,_,_]>>rdf_save_file(Out, Format, Opts), Opts).

% N-Quads or N-Triples
rdf_save_file(Out, Format, Opts) :-
  memberchk(Format, [nquads,ntriples]), !,
  option(graph(G), Opts, _NO_GRAPH),
  with_output_to(Out, gen_ntuples(_, _, _, G)).
% TriG
rdf_save_file(Out, trig, Opts) :- !,
  rdf_save_trig(Out, Opts).
% Turtle
rdf_save_file(Out, turtle, Opts0) :- !,
  merge_options(
    [
      a(true),
      align_prefixes(true),
      comment(true),
      group(true),
      indent(4),
      only_known_prefixes(true),
      subject_white_lines(1),
      tab_distance(0),
      user_prefixes(true)
    ],
    Opts0,
    Opts
  ),
  rdf_save_turtle(Out, Opts).
% XML/RDF
rdf_save_file(Out, xml, Opts) :-
  rdf_save_xmlrdf(Out, Opts).



%! rdf_call_to_graph(+Sink, :Goal_1) is det.
%! rdf_call_to_graph(+Sink, :Goal_1, +Opts) is det.
% Writes results of Goal_1 asserted in its additional Graph argument
% to Sink.
%
% The following options are supported:
%   * compress(+oneof([deflate,gzip,none]))
%     Whether, and if so which, compression is used.
%     By default no compression is used.
%   * rdf_format(+rdf_format)
%     The output format that is used for writing.
%     Default is `simpleQuads`.

rdf_call_to_graph(Sink, Goal_1) :-
  rdf_call_to_graph(Sink, Goal_1, []).


rdf_call_to_graph(Sink, Goal_1, Opts) :-
  call_to_stream(
    Sink,
    [Out,_,_]>>rdf_call_to_graph0(Out, Goal_1, Opts),
    Opts
  ).


rdf_call_to_graph0(Out, Goal_1, Opts1) :-
  setup_call_cleanup(
    rdf_tmp_graph(G),
    (
      call(Goal_1, G),
      merge_options([graph(G)], Opts1, Opts2),
      rdf_save_file(stream(Out), Opts2)
    ),
    rdf_unload_graph(G)
  ).
