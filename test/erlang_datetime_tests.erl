%%% @doc
%%% 
%%% @end
%%% Created :  9 Mar 2014 by Nathaniel Waisbrot <nathaniel@waisbrot.net>
-module(erlang_datetime_tests).
-author('nathaniel@waisbrot.net').

-include_lib("eunit/include/eunit.hrl").

rfc822_decode_test() ->
    [
     ?assertEqual({{2014,3,9},{1,11,0}}, datetime:datetime_decode("Sun, 9 Mar 14 01:11 GMT"))
    ,?assertEqual({{2014,3,10},{21,0,0}}, datetime:datetime_decode("10 Mar 14 21:00 GMT"))
    ,?assertEqual({{2011,1,1},{5,43,21}}, datetime:datetime_decode("1 Jan 11 05:43:21 GMT"))
    ,?assertEqual({{2011,1,1},{9,43,21}}, datetime:datetime_decode("1 Jan 11 05:43:21 EDT"))
    ].

rfc822_encode_test() ->
    [
     ?assertEqual("Mon, 28 Feb 00 10:29:00 +0000", datetime:datetime_encode({{2000,2,28},{10,29,0}}, "GMT", rfc822))
    ,?assertEqual("Mon, 28 Feb 00 05:29:00 +0000", datetime:datetime_encode({{2000,2,28},{10,29,0}}, "EST", rfc822))
    ].

rfc2822_decode_test() ->
    [
     ?assertEqual({{2014,3,8},{1,11,0}}, datetime:datetime_decode("Sat, 8 Mar 2014 01:11 GMT"))
    ,?assertEqual({{2014,3,10},{21,0,0}}, datetime:datetime_decode("10 Mar 2014 21:00 GMT"))
    ,?assertEqual({{2011,1,1},{5,43,21}}, datetime:datetime_decode("1 Jan 2011 05:43:21 GMT"))
    ,?assertEqual({{2011,1,1},{9,43,21}}, datetime:datetime_decode("1 Jan 2011 05:43:21 EDT"))
    ].

rfc2822_encode_test() ->
    [
     ?assertEqual("Mon, 28 Feb 2000 10:29:00 +0000", datetime:datetime_encode({{2000,2,28},{10,29,0}}, "GMT", rfc2822))
    ,?assertEqual("Mon, 28 Feb 2000 05:29:00 +0000", datetime:datetime_encode({{2000,2,28},{10,29,0}}, "EST", rfc2822))
    ].
