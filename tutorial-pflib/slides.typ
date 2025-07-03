#import "@local/umn-theme:0.0.0": *
#import "@preview/codly:1.3.0": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

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
#grid(
  columns: (1fr, 1fr),
  [
    - A lot of different ways to consume the data that is collected
    - Most/Many will start with `DecodeAndWriteToCSV`
    - Important to remember there are these other access points for
      - Caching data and only writing out summary statistics
      - Updating parameters instead of writing out data
      - Forwarding data along over the wire
  ],
  {
    set text(size: 0.8em)
    diagram(
      node-stroke: 1pt,
      node-corner-radius: 5pt,
      node(
        (0,0),
        [
          `DAQConsumer`
          #text(fill: umn-sunny)[ABC] \
          `void consume(/*data*/)`
        ]
      ),
      edge((0,0),(-0.5,1), "-|>"),
      node(
        (-0.5,1),
        [
          `WriteToBinaryFile` \
          #text(fill: umn-sunny)[Concrete]
        ]
      ),
      edge((0,0),(0.5,1), "-|>"),
      node(
        (0.5,1),
        [
          `DecodeAndWrite`
          #text(fill: umn-sunny)[ABC] \
          `void write_event(/*data*/)`
        ]
      ),
      edge("-|>"),
      node(
        (0.5,2),
        [
          `DecodeAndWriteToCSV`
          #text(fill: umn-sunny)[Concrete] \
          Use Lambdas to define what \
          and how to write rows
        ]
      )
    )
  }
)
#v(1fr)
#align(center)[Let's look at `DecodeAndWriteToCSV` in more detail.]

== DecodeAndWriteToCSV Outline
```cpp
pflib::DecodeAndWriteToCSV writer{
  fname, // file to write to
  [](std::ofstream& f) {
    // define how header should be written
    // called once
  },
  [](std::ofstream& f, const pflib::packing::SingleROCEventPacket& ep) {
    // define how rows should be written
    // called on every event collected during daq_run
  }
};
```
The `pflib::packing::SingleROCEventPacket` holds
*all* of the data from the chip. \
Decodes `DAQ_FORMAT_SIMPLEROC`, other formats not supported at this time

== Simple Example
Definition of `all_channels_to_csv`
```cpp
[](std::ofstream& f) {
  f << std::boolalpha;
  f << packing::SingleROCEventPacket::to_csv_header << '\n';
},
[](std::ofstream& f, const pflib::packing::SingleROCEventPacket& ep) {
  ep.to_csv(f);
}
```
- no capturing needed (so no `&` in `[]`)
- dumps all of the DAQ link data
- one row per channel per event

== Select ADC
```cpp
int param{0}; // somewhere above writer definition
// writer definition
[](std::ofstream& f) {
  f << 'param';
  for (int ch{0}; ch < 72; ch++) { f << ',' << ch; }
  f << '\n';
},
[&](std::ofstream& f, const pflib::packing::SingleROCEventPacket& ep) {
  f << param;
  for (int ch{0}; ch < 72; ch++) { f << ',' << ep.channel(ch).adc(); }
  f << '\n';
}
```
#align(center)[All channels in their own columns, only keep ADC data]

== Select Specific Channel
```cpp
int channel{0}; // somewhere above writer definition
// writer definition
[&](std::ofstream& f) {
  boost::json::object h;
  h["channel"] = channel;
  f << "# " << boost::json::serialize(h) << '\n';
  f << pflib::packing::Sample::to_csv_header << '\n';
},
[&](std::ofstream& f, const pflib::packing::SingleROCEventPacket& ep) {
  ep.channel(channel).to_csv(f);
  f << '\n';
}
```
#align(center)[Save all the data from a specific channel (ADC, TOT, ADCt-1, and flags)]

== Boost.JSON
The `boost::json` objects in the header functions are helpful for writing extra
data into the first line of the CSV.
- Command/configuration details
- Parameters that were applied during the whole run (would be constant for a whole column)
- Helpful for sharing run labels with downstream Python plotting scripts

= Python

== The Basics
#slide[
  ```python
  def f(x, y):
    """documentation string

    put it under the def or class
    so it is attached automatically
    the leading space is trimmed
    """
    return x+y
  ```
  *Docstrings* are the preferred documentation method
  in the Python ecosystem.

  Can still use `#` comments, but are not interpreted
  by Python.
][
  - A *module* is just a Python file that defines functions/classes
  - We can *import* modules to use the code in other modules or in our scripts

  #alert[For our purposes, a script should not be used as a module.]
  ```python
  import mymodule
  # mymodule is a module
  # access code from it using `.`
  mymodule.f()
  # runs f from mymodule
  ```
]

== `pflib/ana`
#slide[
#tblock(title: [For Now])[
  Right now, this directory is just a temporary dumping ground to share Python scripts.
]
Still can share code with modules
- see `pflib/ana/charge/update_path.py` for allowing a script to see the modules in `pflib/ana`
- after `import update_path` (or copying its code), you can then `import` modules
][
  === Future...
  I'm not sure! \
  There are a lot of options
  + Single Entry
    - can be slow to run commands \
      (entire module loaded every time)
    - maybe easier to use?
  + Module Share and Many Script
    - need to define how to package it \
      (hard)
    - can be faster \
      (scripts pick imports)
    - more complicated to use?
]

#show: appendix
= Questions

== In Scope
```cpp
void f() {
  // a is in scope
  int a;
  for (int i{0}; i < 2; i++) {
    // a and b are in scope
    int b;
  } // b is destructed when it goes out of scope here
  // a is in scope
}
```
Overly simplistic, but just think about curly braces.
