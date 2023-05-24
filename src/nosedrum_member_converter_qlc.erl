-module(nosedrum_member_converter_qlc).
-export([find_by/4, find_by/5]).

-include_lib("stdlib/include/qlc.hrl").

% Optimized channel cache QLC queries.

find_by(RequestedGuildId, Name, MemberCache, UserCache) ->
    qlc:q([Member || {{GuildId, MemberId}, Member} <- MemberCache:query_handle(),
                     GuildId =:= RequestedGuildId,
                     {UserId, User} <- UserCache:query_handle(),
                     MemberId =:= UserId,
                     map_get(username, User) =:= Name]).

find_by(RequestedGuildId, Name, Discriminator, MemberCache, UserCache) ->
    qlc:q([Member || {{GuildId, MemberId}, Member} <- MemberCache:query_handle(),
                     GuildId =:= RequestedGuildId,
                     {UserId, User} <- UserCache:query_handle(),
                     MemberId =:= UserId,
                     map_get(username, User)  =:= Name,
                     map_get(discriminator, User) =:= Discriminator]).
