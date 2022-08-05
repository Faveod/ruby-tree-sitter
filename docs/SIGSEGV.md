> One finds oneself debugging one’s knowledge of the programming language
> instead of debugging the application itself.
<div style="text-align: right">— The Zig Language Docs</div>

# Hello, `SEGFAULT`!

Normally, one should not get a `SIGSEGV`, the glorious `SEGFAULT` signal, if
they're working locally with `tree-sitter` objects.

What do I mean by that?

The canonical example we're giving in the docs and the `examples` directory
looks roughly like this:

```ruby
require 'tree_sitter'

src = "console.log('hello, world!);"

parser = TreeSitter::Parser.new
language = TreeSitter.load('javascript',
                           'path/to/libtree-sitter-javascript.{dylib, so}')
parser.language = language

tree = parser.parse_string(nil, src)
root = tree.root_node
# …
```

As long as `tree` is outlives `root` (or any node you extract from your parse),
you should be safe.  For instance, you can have `parser`, `language`, and `tree`
as class members of a visitor, and then define your visiting methods in the same
class to traverse the whole tree.

If `node` outlives `tree`, then you're setting a trap for yourself, and you're
asking for `SEGFAULT` trouble, because internally, a `TSNode` struct contains a
`TSTree` pointer, and invoking functions on the `node` will most likely involve
the `TSTree` pointer. When `ruby`'s `GC` decides to collect `tree`, it will call
its finalizer, which in turn calls the `C` function `ts_tree_delete`; from now
on, any pointer referring to `tree` is a loaded weapon.

But sometimes you're not in control of the lifecycle of these objects, and this
is why this doc exists.

PS: Other objects that will have their `ts_*_delete` called on garbage
collection are `TreeCursor`, `Query`, and `QueryCursor`.

## The Setup

I encountered this bug in production. We had a visitor set up the way I explained
earlier, i.e.: we're sure that `tree` outlives `node`.

We added new features for this visitor, and their respective test-cases.  When we ran
the tests in isolation, we had some failures, which was somehow expected.

However, when we launched the whole test suite, we got a `SEGFAULT`. Cool! That means
we have some bugs in `ruby-tree-sitter` asking for some ass-whipping.

Dear reader, any lineraization of narrative below does not reflect reality.
Chaos, discord, and uncertainty better describe the campaign for finding the
source of this particular segmentation fault.

But I digress. Our test suite is set up to run a huge battery of test in
parallel using
[minitest_parallel-fork](https://github.com/jeremyevans/minitest-parallel_fork).
Since we were sure that the bug came up when running the whole test suite only,
I had to see if anything changes if I set up the suite to run serially. And lo
and behold, the bug didn't creep up across numerous serial runs.

## The chase begins 

After some amusing investigation, it turned out that the first issue we were having
came from `tree-sitter` itself.

When we visit the `end` node, and ask it for `child_count`, `tree-sitter` will
happily tell us it has a positive children count. In fact,
`end.child_count == root.child_count`, and when you try to access
`end.child(i)`, for all `0 <= i < root.child_count`.

So I opened an [issue on
`tree-sitter`](https://github.com/tree-sitter/tree-sitter/issues/1832) to
get a confirmation that this is indeed a bug in the generated parsers, and
meanwhile we fixed the issue in `ruby-tree-sitter`.

Excellent! Issue fixed, `tree_sitter`'s `ref` in `Gemfile` updated, hit `bundle update`,
then ran the test suite again: `SEGFAULT` in the same test.

And this time the crash report looked like this:

```
-- Control frame information -----------------------------------------------
c:0012 p:---- s:0060 e:000059 CFUNC  :inspect
c:0011 p:---- s:0057 e:000056 CFUNC  :inspect
c:0010 p:---- s:0054 e:000053 CFUNC  :_dump
c:0009 p:---- s:0051 e:000050 CFUNC  :dump
c:0008 p:0064 s:0046 e:000044 BLOCK  /Users/firas/projects/faveod/langeod/.gems/ruby/3.1.0/gems/minitest-parallel_fork-1.3.0/lib/minitest/parallel_fork.rb:64 [FINISH]
c:0007 p:---- s:0040 e:000039 CFUNC  :fork
c:0006 p:0040 s:0036 e:000035 BLOCK  /Users/firas/projects/faveod/langeod/.gems/ruby/3.1.0/gems/minitest-parallel_fork-1.3.0/lib/minitest/parallel_fork.rb:47 [FINISH]
c:0005 p:---- s:0030 e:000029 CFUNC  :times
c:0004 p:0064 s:0026 e:000025 METHOD /Users/firas/projects/faveod/langeod/.gems/ruby/3.1.0/gems/minitest-parallel_fork-1.3.0/lib/minitest/parallel_fork.rb:44
c:0003 p:0175 s:0016 e:000015 METHOD /Users/firas/projects/faveod/langeod/.gems/ruby/3.1.0/gems/minitest-5.16.2/lib/minitest.rb:159
c:0002 p:0497 s:0009 E:001ab8 EVAL   bin/langeod.rb:1800 [FINISH]
c:0001 p:0000 s:0003 E:001a20 (none) [FINISH]
```

No indicator whatsoever that it's coming from the bindings. Maybe those
`inspect` `C` functions come from the bindings, but I couldn't be sure for
reasonable reasons: my `macOS` refused to generate the crash reports it was
generating earlier, and I couldn't lay my hands on a proper core dump.

## More than meets the eye

So I embarked on roughly two very, very long days investigating the source of
the issue.

First, I tried to hook up `gdb` to the ruby process launching the test suite.
You can read about how you can do it in
[Development.md](Development.md#debugging). That was a fail because
`minitest_parallel-fork` was forking groups of test in their own processes, and
I couldn't make `gdb` hook up to the forks.

I tried to do some `ASAN` and `UBSAN` just to make sure that we're not leaking
somthing. Also, no success. Couldn't see anything wrong.

So it came down to narrowing down the test file to the single test that produced
the segfault. It turned out to be a problem in our visit where we were doing a
variation of this:

```ruby
def get_node
  # …
  [node1, node2]
end

def visit_x
  # …
  n = get_node().type
end
```

Obviously, an `Array` doesn't have a `type` method, so we should just get an
exception. The test suite should report the exception and we should move on with
out lives. Why would it segfault? It can't be a `ruby` bug on such a trivial
case! It was doing it when running this test in isolation *and* when we run
the whole test-suite serially!

But then, upon reading `minites_parallel-fork`'s code, and quite some time
reflecting on the generated error report, and what could possibly cause such an
issue, I remembered that `ruby` may defer evaluation of some expressions until
they're needed.

And what does `ruby` do when you have an exception? It calls `inspect` on the
expression.

So could it be that it is actually generating an exception string, which calls
`Array::inspect`, and in turn call its elements' `inspect` methods, i.e.
`TreeSitter::Node::inspect`, but defering its evaluation until needed?

I know that `Node::inspect` calls `tree-sitter`'s `ts_node_string` to print a
`sexp` representation of the node and its descendants.

So the only reasonable explanation is that when `inspect` is invoked, the
underlying `TSTree` pointer used to print the `sexp`, by visiting the node's
descendants, is invalid ⇒ 💥.

Could it be that the visitor and its member `parser`, `tree`, etc. were `GC`ed
already when the time came to output the exception message?

Of course the answer is yes. I don't do click-baits …

## Reproducing the Bug

First, we will simulate a failing test case:

```ruby
class Test
  def run
    parser = TreeSitter::Parser.new
    language = TreeSitter.lang('javascript')

    src = "console.log('hello, world!');"

    parser.language = language

    tree = parser.parse_string(nil, src)
    root = tree.root_node
    [root].type
  end
end
```

Notice that we're calling `[root].type` instead of `root.type`, which should
generate the exception we're looking for.

Then, we're going to need to simulate what's happening in `minitest_parallel-fork`,
which is basically forking a process, running the test, and sending the results back
to the parent process via `Marshall::dump`.

Take a look at the [crash report](#the-chase-begins): the call stack has
`inspect` sitting on top of `dump`.

```ruby
class Minitest
  attr_accessor :result

  def run
    read, write = IO.pipe

    pid = Process.fork do
      data = 'intialized'
      begin
        read.close
        data = Test.new.run
      rescue StandardError => e
        data = e
      ensure
        GC.start(full_mark: true, immediate_sweep: true)
        write.write(Marshal.dump(data))
      end
    end

    write.close
    res = read.read
    Process.wait(pid)
    @result = Marshal.load(res)
  end
end
```

Finally, all that remains is running the test:

```ruby
t = Minitest.new
t.run

puts t.result
```

The full details are in [examples/05-segfault](../examples/05-segfault.rb).

What happens when you run `bundle exec ruby examples/05-segfault.rb`? Of course
it `segfault`s.

If you remove the forced `GC.start()` then you're most likely never going to see
the error in your runs. It's put here to simulate our case where we have a great amount
of objects created and recycled in the test-suite.

And I know that you're tempted to point out that `tree` is not a class member,
so of course it will be collected. Well, try it for yourself. Add those sweet `@`
wherever you like in `Test`. It will not change a thing, because the `Test` object
itself will be collected when we hit `ensure`.

The only true fix for this is to retain `Test.new` in a `Minitest` member.

## Conclusion

So who's fault its this, and who has to fix this behavior?

Is it `Minitest`'s fault for discarding all my objects? Should I make an extension
called `minitest-hoarder` just to fix my issue?

Is it `minitest_parallel-fork`'s fault? Should the maintainers fix the way they
handle forks and error messages?

Is it matz's fault for making `ruby`? 

Are we all guilty for chosing `ruby`? Or any garbage-collected language for that
matter?

Alas, the blame game is nice, but unproductive. I could cache the results of
`inspect` in a `ruby` string upon `Node` creation. Possible, doable, and works.
It means I (the library consumer) would need to consume far more memory than we
should, and it's all redundant information.
