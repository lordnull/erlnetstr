%% @doc Library for encoding and decoding netstring streams.
-module(netstring).

-export([encode/1, encode/2, decode/1, decode/2]).

-ifdef(TEST).
-compile(export_all).
-endif.

-record(continuation, {
	radix = 10 :: pos_integer(),
	length = []:: [pos_integer()] | pos_integer(),
	bin_so_far = <<>> :: binary()
}).

-type(netstring() :: binary()).

%% @doc Encode a single binary, or a list of binaries with the default 
%% radix of 10.
-spec(encode/1 :: (BinOrBins :: binary() | [binary()]) -> netstring()).
encode(Binary) when is_binary(Binary) ->
	encode([Binary]);

encode(Bins) ->
	encode(Bins, 10).

%% @doc Encode a single binary, or a list of binaries, with the given
%% radix.
-spec(encode/2 :: (BinOrBins :: binary() | [binary()], Radix :: pos_integer()) -> netstring()).
encode(Binary, Radix) when is_binary(Binary) ->
	encode([Binary], Radix);

encode(Binary, Radix) when is_binary(Binary) ->
	encode([Binary], Radix);
encode(Binaries, Radix) ->
	encode(Binaries, Radix, []).

encode([], _Radix, Acc) ->
	Out = lists:reverse(Acc),
	list_to_binary(Out);

encode([Bin | Tail], Radix, Acc) ->
	Length = size(Bin),
	NetLength = integer_to_list(Length, Radix),
	LengthBin = list_to_binary(NetLength),
	NewBin = <<LengthBin/binary, $:, Bin/binary, $,>>,
	NewAcc = [NewBin | Acc],
	encode(Tail, Radix, NewAcc).

%% @doc Decode a binary as a netstring with a radix of 10.  For future
%% decoding, `decode/2' should be used.
-spec(decode/1 :: (Binary :: binary()) -> {[binary()], #continuation{}}).
decode(Binary) ->
	decode(Binary, 10).

%% @doc Decode a binary as a netstring with a radix given; or the given
%% continuation.  Each successive call to `decode/2' should use the 
%% `#continuation{}' from the previous call to `decode/2'.
-spec(decode/2 :: (Binary :: binary(),
	RadixOrCont :: pos_integer() | #continuation{}) ->
		{[binary()], #continuation{}}).
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
