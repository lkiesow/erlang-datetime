%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                                                                            %
%%% Copyright (c) 2012, Lars Kiesow.                                           %
%%% All rights reserved.                                                       %
%%% http://www.larskiesow.de                                                   %
%%%                                                                            %
%%% Redistribution and use in source and binary forms, with or without         %
%%% modification, are permitted provided that the following conditions         %
%%% are met:                                                                   %
%%%                                                                            %
%%% 1. Redistributions of source code must retain the above copyright          %
%%%    notice, this list of conditions and the following disclaimer.           %
%%%                                                                            %
%%% 2. Redistributions in binary form must reproduce the above copyright       %
%%%    notice, this list of conditions and the following disclaimer in the     %
%%%    documentation and/or other materials provided with the distribution.    %
%%%                                                                            %
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"%
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE  %
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE %
%%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE   %
%%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR        %
%%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF       %
%%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS   %
%%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN    %
%%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)    %
%%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE %
%%% POSSIBILITY OF SUCH DAMAGE.                                                %
%%%                                                                            %
%%% The views and conclusions contained in the software and documentation are  %
%%% those of the authors and should not be interpreted as representing         %
%%% official policies, either expressed or implied, of the whole project.      %
%%%                                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                                                                            %
%%% This module provides simple import and export functions for datetime       %
%%% strings specified by RFC822, RFC2822 and the RSS specification to erlang   %
%%% datetime tuples as returned for example by erlang:universaltime() or       %
%%% erlang:localtime().                                                        %
%%%                                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-module(datetime).
-author('lkiesow@uos.de').
-export([ datetime_encode/3, datetime_encode/2, datetime_encode/1,
		datetime_encode/0, datetime_decode/1, datetime_decode/2 ]).

%% Takes a numerical representation of a month and returns its representation
%% as a list of three characters.
%%
%% X should be an integer with 0 <= X <= 12.
month_name( X ) when is_integer(X) ->
	case X of
		1 -> 'Jan';
		2 -> 'Feb';
		3 -> 'Mar';
		4 -> 'Apr';
		5 -> 'May';
		6 -> 'Jun';
		7 -> 'Jul';
		8 -> 'Aug';
		9 -> 'Sep';
		10 -> 'Oct';
		11 -> 'Nov';
		12 -> 'Dec'
	end.


%% Takes a three character representation of a month and returns its numerical
%% representation.
%%
%% X should be a list of three charaters or a binary which will be
%% automatically converted to a list.
month_by_name( X ) when is_binary(X) ->
	month_by_name( binary_to_list(X) );

month_by_name( X ) ->
	case X of
		"Jan" -> 1;
		"Feb" -> 2;
		"Mar" -> 3;
		"Apr" -> 4;
		"May" -> 5;
		"Jun" -> 6;
		"Jul" -> 7;
		"Aug" -> 8;
		"Sep" -> 9;
		"Oct" -> 10;
		"Nov" -> 11;
		"Dec" -> 12
	end.


%% Returns a three character representation of the weekday implied by the date
%% specification.
get_day_name( Date ) ->
	case calendar:day_of_the_week(Date) of
		1 -> 'Mon';
		2 -> 'Tue';
		3 -> 'Wed';
		4 -> 'Thu';
		5 -> 'Fri';
		6 -> 'Sat';
		7 -> 'Sun'
	end.


%% Takes a timezone string as specified in RFC822 and returns the time
%% difference to UTC. The value returned is { HourOffset, MinuteOffset }. All
%% timezones specified in REC822 are supported. Some common timezones however
%% are not allowed according to the RFC.
timezone_offset( TZ ) when is_binary(TZ) ->
	timezone_offset( binary_to_list(TZ) );

timezone_offset( [TZ] ) ->
	{ if
		TZ >= $A, TZ =< $I -> 64-TZ;
		TZ >= $K, TZ =< $M -> 65-TZ;
		TZ >= $N, TZ =< $Y -> TZ-$M;
		TZ == $Z              -> 0
	end, 0 };

timezone_offset( [Sgn,H1,H2,M1,M2] ) ->
	{ list_to_integer([Sgn,H1,H2]),
		list_to_integer([Sgn,M1,M2]) };

timezone_offset( TZ ) ->
	{ case TZ of
		"UT"  -> 0;
		"GMT" -> 0;
		"EST" -> -5;
		"EDT" -> -4;
		"CST" -> -6;
		"CDT" -> -5;
		"MST" -> -7;
		"MDT" -> -6;
		"PST" -> -8;
		"PDT" -> -7
	end, 0 }.


%% According to the RFC822 a year is only represented by its two last digits.
%% This function provides some methods for expanding those short year
%% representations to a full year. You can choose between the following
%% expansion rules:
%%  smart             If the two digit year is less or equal of the two last
%%                    digits of the current year, assume that the date is from
%%                    the current century. Otherwise assume that the date is
%%                    from last century.
%%                    Example (Current year is 2012):
%%                      12  will become  2012
%%                      34  will become  1934
%%                      05  will become  2005
%%  current_century   It is assumed that all dates are from this century.
%%  no_alternation    No alternation is done. Thus two digit years stay as they
%%                    are.
%%  DIGIT             DIGIT may be any integer. Using this method you can
%%                    specify a concrete century. This number is basically
%%                    added to the two digit year. Thus 34 with DIGIT = 1800
%%                    will become 1834.
expand_year( Year, _ ) when Year >= 100; Year < 0 ->
	Year;

expand_year( Year, smart ) ->
	{{CurrentYear,_,_},_} = erlang:universaltime(),
	if
		Year =< CurrentYear rem 100 -> Year + CurrentYear div 100 * 100;
		true                        -> Year + CurrentYear div 100 * 100 - 100
	end;

expand_year( Year, current_century ) ->
	{{CurrentYear,_,_},_} = erlang:universaltime(),
	Year + CurrentYear div 100 * 100;

expand_year( Year, no_alternation ) ->
	Year;

expand_year( Year, BaseYear ) ->
	Year + BaseYear.


%% Convert a erlang datetime struct to its string representation according to
%% either RFC822 or the RSS specification.
%%
%% datetime_encode( DateTime, TimeZone, SpecType )
%%                     |         |         +------- Defaults to 'rfc2822'
%%                     |         +------- Defaults to 'GMT'
%%                     +------- Defaults to erlang:universaltime()
%%
%% DateTime must be of the form {{Year,Month,Day},{Hour,Minute,Second}}. This
%%          form is returned for example by the erlang functions
%%          universaltime() or localtime().
%% TimeZone has to be a zone according to RFC822 or RFC2822. Additional time
%%          zones may be accepted in the future.
%% SpecType can be either 'rfc822', 'rfc2822' or 'rss'. Both specifications are
%%         basically the same except for the length of the year. RSS supports
%%         both, two and four digit years while rfc882 only accepts two digit
%%         year representation. rfc2822 basically equals the RSS
%%         specifications.
%%         Important: Some specifications of rfc2882 marked as obsolete and
%%         comments are not supported at the moment. At they will probably
%%         never be supported as they are basically never used in the real
%%         world.
datetime_encode({{Year,Mon,Day},{Hour,Min,Sec}}, 'GMT', rfc822) when is_float(Sec) ->
    datetime_encode({{Year, Mon, Day},{Hour, Min, round(Sec)}}, 'GMT', rfc822);

datetime_encode( {Date={Year,Mon,Day},{Hour,Min,Sec}}, 'GMT', rfc822 ) ->
	lists:flatten(io_lib:format( "~s, ~B ~s ~2..0B ~2..0B:~2..0B:~2..0B ~s", [
			get_day_name( Date ),
			Day, month_name(Mon), (Year rem 1000),
			Hour, Min, Sec, '+0000' ] ));

datetime_encode({{Year,Mon,Day},{Hour,Min,Sec}}, 'GMT', rss ) when is_float(Sec) ->
    datetime_encode({{Year, Mon, Day}, {Hour, Min, round(Sec)}}, 'GMT', rss);

datetime_encode( {Date={Year,Mon,Day},{Hour,Min,Sec}}, 'GMT', rss ) ->
	lists:flatten(io_lib:format( "~s, ~B ~s ~4..0B ~2..0B:~2..0B:~2..0B ~s", [
			get_day_name( Date ),
			Day, month_name(Mon), Year,
			Hour, Min, Sec, '+0000' ] ));

datetime_encode({{Year, Mon, Day}, {Hour, Min, Sec}}, 'GMT', rfc2822) when is_float(Sec) ->
    datetime_encode({{Year, Mon, Day}, {Hour, Min, round(Sec)}}, 'GMT', rfc2822);

datetime_encode( {Date={Year,Mon,Day},{Hour,Min,Sec}}, 'GMT', rfc2822 ) ->
	lists:flatten(io_lib:format( "~s, ~B ~s ~4..0B ~2..0B:~2..0B:~2..0B ~s", [
			get_day_name( Date ),
			Day, month_name(Mon), Year,
			Hour, Min, Sec, '+0000' ] ));

datetime_encode( DateTime, Zone, Type ) ->
	Secs  = calendar:datetime_to_gregorian_seconds( DateTime ),
	{H,M} = timezone_offset( Zone ),
	UTCDateTime = calendar:gregorian_seconds_to_datetime(Secs+(M*60)+(H*3600)),
	datetime_encode( UTCDateTime, 'GMT', Type ).


datetime_encode( DateTime, Type ) ->
	datetime_encode( DateTime, Type, rfc2822 ).


datetime_encode( {MegaSecs,Secs,MicroSecs} ) ->
	datetime_encode(
		calendar:now_to_datetime({MegaSecs,Secs,MicroSecs}),
		'GMT', rfc2822 );

datetime_encode( DateTime ) ->
	datetime_encode( DateTime, 'GMT', rfc2822 ).


datetime_encode() ->
	datetime_encode( erlang:universaltime(), 'GMT', rfc2822 ).


%% Converts a DateTime string according to rfc822 or RSS specifications into an
%% erlang datetime tupel. The first parameter is the datetime string, the
%% second specifies the handling of years represented as two digits as
%% described next to expand_year/2. The latter defaults to 'smart'.
datetime_decode( D, Y ) when is_binary(D) ->
	datetime_decode( binary_to_list(D), Y );

datetime_decode( DateTimeStr, YearHandling ) ->
	[StrDay,StrMon,StrYear,StrTime,Zone] =
		string:tokens( lists:last(string:tokens( DateTimeStr, ",")), " "),
	Year = expand_year(list_to_integer(StrYear), YearHandling ),
	Mon  = month_by_name(StrMon),
	Day  = list_to_integer(StrDay),
	[Hour,Min,Sec|_] = [list_to_integer(X) || X <- string:tokens(StrTime, ":")] ++ [0],
	DateTime = {{Year,Mon,Day},{Hour,Min,Sec}},
	Secs  = calendar:datetime_to_gregorian_seconds( DateTime ),
	{HOff,MOff} = timezone_offset( Zone ),
	UTCSecs = Secs+(-MOff*60)+(-HOff*3600),
	calendar:gregorian_seconds_to_datetime(UTCSecs).


datetime_decode( DateTimeStr ) ->
	datetime_decode( DateTimeStr, smart ).
