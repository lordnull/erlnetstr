-module(netstring_tests).
-include_lib("eunit/include/eunit.hrl").

encode_test_() -> [
	?_assertEqual([<<"5">>, $:, <<"hello">>, $,],
		netstring:encode(<<"hello">>)),

	?_assertEqual([<<"11">>, $:, [<<"hello ">>, $w , "orld"], $,],
		netstring:encode([<<"hello ">>, $w, "orld"])),

	?_assertEqual([<<"B">>, $:, <<"hello world">>, $,],
		netstring:encode(<<"hello world">>, 16)),

	?_assertEqual([<<"C">>, $:, [<<"hello world">>, <<$!>>], $, ],
		netstring:encode([<<"hello world">>, <<$!>>], 16))
].

decode_test_() -> [
	?_assertMatch({[<<"hello">>], _},
		netstring:decode(<<"5:hello,">>)),

	?_assertMatch({[<<"hello">>, <<"world">>], _},
		netstring:decode(<<"5:hello,5:world,">>)),

	?_assertMatch({[<<"hello world">>], _},
		netstring:decode(<<"B:hello world,">>, 16)),

	?_assertMatch({[<<"hello world">>, <<$!>>], _},
		netstring:decode(<<"B:hello world,1:!,">>, 16)),

	?_assertMatch({[<<"hello world!">>, <<"yum">>], _},
		netstring:decode(<<"12:hello world!,3:yum,">>))
].
