%% The MIT License (MIT)
%% Copyright (c) 2011 Micah Warren
%% 
%% Permission is hereby granted, free of charge, to any person obtaining a 
%% copy of this software and associated documentation files (the 
%% "Software"), to deal in the Software without restriction, including 
%% without limitation the rights to use, copy, modify, merge, publish, 
%% distribute, sublicense, and/or sell copies of the Software, and to 
%% permit persons to whom the Software is furnished to do so, subject to 
%% the following conditions:
%% 
%% The above copyright notice and this permission notice shall be included 
%% in all copies or substantial portions of the Software.
%% 
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
%% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
%% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
%% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
%% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
%% TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
%% SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

%% @doc Library for encoding and decoding netstring streams.
-module(netstring).

-export([encode/1, encode/2, decode/1, decode/2]).

-record(continuation, {
	radix = 10 :: pos_integer(),
	length = []:: [pos_integer()] | pos_integer(),
	bin_so_far = <<>> :: binary()
}).

-type netstring() :: iolist().

%% @doc Encode a single iolist into an iolist netstring with the default radix
%% of 10.
-spec encode( Iolist :: iolist() ) -> netstring().
encode(Iolist) ->
	encode(Iolist, 10).

%% @doc Encode a single iolist with the given radix.
-spec encode(Iolist :: iolist(), Radix :: pos_integer()) -> netstring().
encode(Iolist, Radix) ->
	Length = iolist_size(Iolist),
	NetLength = integer_to_binary(Length, Radix),
	[NetLength, $:, Iolist, $,].

%% @doc Decode a binary as a netstring with a radix of 10.  For future
%% decoding, `decode/2' should be used, passing in the second element of the
%% return value.
-spec decode(Binary :: binary()) -> {[binary()], #continuation{}}.
decode(Binary) ->
	decode(Binary, 10).

%% @doc Decode a binary as a netstring with a radix given; or the given
%% continuation.  Each successive call to `decode/2' should use the 
%% `#continuation{}' from the previous call to `decode/2'.
-spec decode(Binary :: binary(), RadixOrCont :: pos_integer() | #continuation{}) -> {[binary()], #continuation{}}.
decode(Binary, Radix) when is_integer(Radix) ->
	Cont = #continuation{radix = Radix},
	decode(Binary, Cont);

decode(Binary, Cont) when is_record(Cont, continuation) ->
	decode(Binary, Cont, []).

decode(<<>>, Cont, Acc) ->
	OutAcc = lists:reverse(Acc),
	{OutAcc, Cont};

decode(Binary, #continuation{length = Len} = Cont, Acc) when is_integer(Len) ->
	#continuation{radix = Rad, bin_so_far = BinSoFar} = Cont,
	FullBin = <<BinSoFar/binary, Binary/binary>>,
	case FullBin of
		<<NewBin:Len/binary, $,, Rest/binary>> ->
			NewCont = #continuation{radix = Rad},
			NewAcc = [NewBin | Acc],
			decode(Rest, NewCont, NewAcc);
		_ ->
			OutAcc = lists:reverse(Acc),
			OutCont = #continuation{radix = Rad, bin_so_far = FullBin, length = Len},
			{OutAcc, OutCont}
	end;

decode(<<$:, Binary/binary>>, Cont, Acc) ->
	#continuation{length = RawLen, radix = Radix, bin_so_far = OldBin} = Cont,
	Len = list_to_integer(lists:reverse(RawLen), Radix),
	NewCont = #continuation{radix = Radix, length = Len, bin_so_far = OldBin},
	decode(Binary, NewCont, Acc);

decode(<<X/integer, Binary/binary>>, Cont, Acc) ->
	#continuation{length = Len1} = Cont,
	Len2 = [X | Len1],
	Cont1 = Cont#continuation{length = Len2},
	decode(Binary, Cont1, Acc).
