{:foo, foo} = {:foo, 1}
{"bar", bar} = {"bar", 2}

{foo, bar} == {1, 2}

var = {{"foo", foo}, {:bar, bar}}
var == {{"foo", foo}, {:bar, bar}}
