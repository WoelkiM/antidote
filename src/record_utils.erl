%% -------------------------------------------------------------------
%%
%% Copyright (c) 2014 SyncFree Consortium.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%%%-------------------------------------------------------------------
%%% @author pedrolopes
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(record_utils).
-include("querying.hrl").

%% API
-export([record_data/2,
         record_data/3,
         get_column/2,
         lookup_value/2,
         delete_record/2]).

record_data(Keys, TxId) when is_list(Keys) ->
    case querying_utils:read_keys(value, Keys, TxId) of
        [[]] -> [];
        ObjValues -> ObjValues
    end;
record_data(Key, TxId) ->
    record_data([Key], TxId).

record_data(PKeys, TableName, TxId) when is_list(PKeys) ->
    PKeyAtoms = lists:map(fun(PKey) -> querying_utils:to_atom(PKey) end, PKeys),
    ObjKeys = querying_utils:build_keys(PKeyAtoms, ?TABLE_DT, TableName),
    case querying_utils:read_keys(value, ObjKeys, TxId) of
        [[]] -> [];
        ObjValues -> ObjValues
    end;
record_data(PKey, TableName, TxId) ->
    record_data([PKey], TableName, TxId).

get_column(_ColumnName, []) -> undefined;
get_column({ColumnName, CRDT}, Record) ->
    case proplists:lookup({ColumnName, CRDT}, Record) of
        none -> undefined;
        Entry -> Entry
    end;
get_column(ColumnName, Record) ->
    querying_utils:first_occurrence(
        fun(?ATTRIBUTE(Column, _Type, _Value)) ->
            Column == ColumnName
        end, Record).

lookup_value(_ColumnName, []) -> [];
lookup_value({ColumnName, CRDT}, Record) ->
    proplists:get_value({ColumnName, CRDT}, Record);
lookup_value(ColumnName, Record) ->
    case get_column(ColumnName, Record) of
        ?ATTRIBUTE(_Column, _Type, Value) -> Value;
        undefined -> undefined
    end.

delete_record(ObjKey, TxId) ->
    %lager:info("Deleting record with key ~p", [ObjKey]),
    StateKey = {?STATE_COL, ?STATE_COL_DT},
    StateOp = crdt_utils:to_insert_op(?CRDT_VARCHAR, 'd'),
    MapOp = {StateKey, StateOp},
    Update = querying_utils:create_crdt_update(ObjKey, update, MapOp),
    ok = querying_utils:write_keys(Update, TxId),
    false.