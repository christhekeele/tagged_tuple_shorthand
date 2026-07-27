@:foo = {:foo, 1}
@"bar" = {"bar", 2}

{foo, bar} == {1, 2}

var = {@"foo", @:bar}
var == {{"foo", foo}, {:bar, bar}}
