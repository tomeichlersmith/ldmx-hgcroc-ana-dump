#import "@local/umn-theme:0.0.0": *
#import "@preview/codly:1.3.0": *

#show: codly-init

#show strong: it => text(weight: "bold", fill: umn-sunny, it)

#show: umn-theme.with(
  config-info(
    title: [`pflib` Design and `pftool` Commands],
    subtitle: [and selected C++ concepts],
    author: [Tom Eichlersmith],
    date: datetime.today(),
    institution: [he/him/his \ University of Minnesota],
    logo: ldmx-logo()
  )
)

#title-slide()

= General Goals

== General Goals

=== Goals of `pflib`
1. Share interaction/testing/tuning code across test stands
  - *Collaborate* on difficult and complicated problems
  - *Avoid Duplication* so we can make quick progress and build off each other
2. Prepare codebase for use in final detector (_Personally_, I'm not sure how this will look)

#tblock(title: [GitHub Issues])[
  *Our main form of collaboration.*
  No correctness/formality requirements. Just post information there! Make new issues for different projects!
  Comment on other issues!
]

=== Goals of this Presentation
1. Gives reasoning for my design choices
2. Explain some advanced C++ techniques that are in use
3. Provide examples of how (I imagine) `pftool` commands can be written

= Design

*Flexibility* and *Avoid Duplication*

= Advanced C++

Inheritance, ABCs, Lambda Functions, and Capturing

== Inheritance and ABCs
#slide(composer: (1fr,1fr))[
  #set text(size: 0.8em)
  ```cpp
  class A {
   public:
    virtual ~A() = default;
    virtual void hello() {
      std::cout << "hello from A!\n";
    }
  };
  
  class B : public A {
  };
  
  class C : public A {
    virtual void hello() override {
      std::cout << "hello from C!\n";
    }
  };
  ```
][
  === Vocabulary
  - `B` and `C` are *derived* classes of `A`
  - `A` is the *base* class of `B` and `C`

  ```cpp
  B b; C c;
  // prints "hello from A!"
  b.hello();
  // prints "hello from C!"
  c.hello();
  A &a_ref_to_b{b}, &a_ref_to_c{c};
  // prints "hello from A!"
  a_ref_to_b.hello();
  // prints "hello from C!"
  a_ref_to_c.hello();
  ```
]

== Abstract Base Class
#slide[
  One (or more) of the base class functions are not defined.

  #set text(size: 0.8em)
  ```cpp
  class ABC {
   public:
    virtual ~ABC() = default;
    virtual void needs_to_be_defined() = 0;
  };

  class Concrete : public ABC {
   public:
    virtual void
    needs_to_be_defined() override {
      std::cout << "hooray!\n";
    }
  };
  ```
][
  - `ABC::needs_to_be_defined` is a *pure virtual* function
  - *Concrete* classes are ones that have no pure virtual functions
  - Only concrete classses can be constructed
  - Can still use references to abstract base classes

  === Why?
  Basically _require_ derived classes to make a specific implementation
  while allowing other users of the ABC to have the same interface.
]

== Lambda Functions
*Lambda* (or *Free* or *Anonymous*) Functions allow us to
define a function "in place".
```cpp
auto f = [](int a, int b) -> int {
  return a+b;
};
int x = f(1, 2); // x = 3
```
If you see `std::function` floating around, that is asking for a Lambda.
```cpp
std::function<Ret(Arg1, Arg2, ...)>
// should be given
[](Arg1 a1, Arg2 a2, ...) -> Ret {
  // todo
};
```

== Capturing
The square brackets `[]` starting the Lambda defines what is *captured*.
(what can be used within the Lambda when it is called).

#tblock(title: [This is a whole thing])[
  For our purposes we want to "capture by reference" (using `&`),
  and use the capture default (only `&`) allowing the compiler
  to figure out what should be captured for us.
]

#grid(
  columns: (3fr,2fr),
  column-gutter: 0.5em,
  ```cpp
  int a = 1;
  auto f = [&](int b) -> int {
    return a+b;
  };
  int x = f(2); // x=3
  a=2;
  int y = f(2); // y=4
  ```,
  [
    - I haven't followed these rules perfectly in `pflib` up until this point (sorry!)
    - *Very Complicated* so only useful when maximum flexibility is required
      (see writing out data later)
  ]
)

= `pftool` Commands

== Setup a New `pftool` Command
#slide[
#set text(size: 0.8em)
```cpp
// in some file built into pftool (probably app/tool/tasks.cxx)
/**
 * NAME.MY_COMMAND
 *
 * longer explanation of what my command does in this special doxygen syntax so it
 * ends up in the online documentation
 */
static void my_command(Target* tgt) {
  // todo
}
// usually at bottom of file
namespace {
auto menu_ = pftool::menu("NAME", "one line description")
    ->line("MY_COMMAND", "short description of my command", my_command)
;
}
```
]

== Outline of New Command
#slide[
```cpp
static void my_command(Target* tgt) {
  // prompt user for arguments using pftool::readline_

  // pre-run setup like apply test parameters with roc.testParameters(),
  // defining a writer, and calling tgt->setup_run

  // do run(s) of data collection

  // post-run cleanup
}
```
You can also use doxygen style comments (`/** ... */` or `///`) in the function
body and those notes will be included in the online documentation.
]

== Test HGCROC Parameters
- The `ROC::TestParameters` class applies a set of parameters to the chip and then *unsets them when it is destroyed*
- i.e. the `ROC::TestParameters` object must be *in scope* with the `tgt->daq_run` you wish for them to be applied to
  (do folks know what I mean by in scope?)
#grid(
  columns: (1fr, 1fr),
  gutter: 0.5em,
  [
    Build up with test parameter builder.
    - The `ROC::TestParameters` is not created until `apply`
    ```cpp
    auto test_param_handle =
      roc.testParameters()
      .add("PAGE", "PARAM1", 42)
      // .. more .add( )s
      .apply();
    ```
  ],
  [
    Apply already created `std::map`
    - Helpful if parameter map is used for something else
    ```cpp
    auto test_param_handle =
      ROC::TestParameters(
        roc,
        parameters_to_apply
      );
    ```
  ]
)

== Defining a Writer


