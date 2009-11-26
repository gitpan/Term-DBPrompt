use Test::More tests => 27;
BEGIN { use_ok('Term::DBPrompt') };

set_command qw(help exit i init input list);

set_opt({ quiet => 1, file => \'
abc;
def; ghi;
help qslkdj fff;
help
  tttt
     uuuu;
i eruy;
in eruy;
ini eruy;




e;
ex;
exi;
exit;
h;
list a b c d;
list a b # c d;
list a "b # c" d;
list a b ";" c d;
exit; list; i; inp; ini;
'});

init_pipe;

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Empty', o='1', c='1', cmd='', p=('')}, 'Test line 001');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Not', o='1', c='1', cmd='abc', p=('')}, 'Test line 002');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Not', o='1', c='0', cmd='def', p=('')}, 'Test line 003');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Not', o='0', c='1', cmd='ghi', p=('')}, 'Test line 004');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='help', p=('qslkdj', 'fff')}, 'Test line 005');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='help', p=('tttt', 'uuuu')}, 'Test line 006');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='i', p=('eruy')}, 'Test line 007');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Dup', o='1', c='1', cmd='in', p=('init', 'input')}, 'Test line 008');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='init', p=('eruy')}, 'Test line 009');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Empty', o='1', c='1', cmd='', p=('')}, 'Test line 010');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Empty', o='1', c='1', cmd='', p=('')}, 'Test line 011');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Empty', o='1', c='1', cmd='', p=('')}, 'Test line 012');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Empty', o='1', c='1', cmd='', p=('')}, 'Test line 013');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='exit', p=('')}, 'Test line 014');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='exit', p=('')}, 'Test line 015');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='exit', p=('')}, 'Test line 016');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='exit', p=('')}, 'Test line 017');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='help', p=('')}, 'Test line 018');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='list', p=('a', 'b', 'c', 'd')}, 'Test line 019');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='list', p=('a', 'b', 'list', 'a', 'b # c', 'd')}, 'Test line 020');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='1', cmd='list', p=('a', 'b', ';', 'c', 'd')}, 'Test line 021');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='1', c='0', cmd='exit', p=('')}, 'Test line 022');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='0', c='0', cmd='list', p=('')}, 'Test line 023');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='0', c='0', cmd='i', p=('')}, 'Test line 024');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='0', c='0', cmd='input', p=('')}, 'Test line 025');
}

{
    my ($rc, $open, $close, $cmd, @params) = get_cmd_line;
    local $" = "', '";
    $result = "rc='$rc', o='$open', c='$close', cmd='$cmd', p=('@params')";
    is($result, q{rc='Found', o='0', c='1', cmd='init', p=('')}, 'Test line 026');
}
