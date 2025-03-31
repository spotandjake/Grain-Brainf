# Planning documentation for the neurotic brainF compiler
This document contains the wat, and compilation mechanism keep in mind 
we are not producing wat but wasm so these are more about logic then actual output.

### Templates

#### Overall template

```wat
(module
  ;; Type section - Wasm Types
  ;; Import Section - Wasm Imports
  ;; Function Section - Wasm Function Headers
  ;; Memory Section - Memory defintion
  ;; Start Section - Start Section
  ;; Code Section - Actual Function content
  ;; grow function
  ;; _start section
)
```

Compiled looks like:

```wasm
0x00 0x61 0x73 0x6D # Magic header
0x01 0x00 0x00 0x00 # Wasm Version Number
# Type Section
# Import Section
# Function Section
# Memory Section
# Start Section
# Code Section
```

### Type Section

```wat
(type (;0;) (func)) ;; _start type
(type (;1;) (func (param i32 i32) (result i32))) ;; grow type
(type (;2;) (func (param i32 i32 i32 i32) (result i32))) ;; fd_write type
```

Compiles to:

```wasm
0x01 # Type section id
0x12 # Type Section length encoded as uleb128 - 18 bytes
0x03us # Type count
# _start type
0x60 # function type
0x00 # 0 params
0x00 # 0 returns
# grow type
0x60 # function type
0x02 # 2 params
0x7F # i32
0x7F # i32
0x01 # 1 returns
0x7F # i32
# fd_write type
0x60 # function type
0x02 # 4 params
0x7F # i32
0x7F # i32
0x7F # i32
0x7F # i32
0x01 # 1 returns
0x7F # i32
```

#### Import Section

```wat
(import "wasi_snapshot_preview1" "fd_write" (func (;0;) (type 2))) # for printing to stdout
;; TODO: Import utilities for fd_read and stuff
```

Compiles to:

```wasm
0x02 # Import section ID
0x23 # Import Section length encoded as uleb128 - 35 bytes
0x01 # 1 Import
# Module Name encoding
0x16 # The module name is 22 bytes
0x77 # w
0x61 # a
0x73 # s
0x69 # i
0x5f # _
0x73 # s
0x6e # n
0x61 # a
0x70 # p
0x73 # s
0x68 # h
0x6f # o
0x74 # t
0x5f # _
0x70 # p
0x72 # r
0x65 # e
0x76 # v
0x69 # i
0x65 # e
0x77 # w
0x31 # 1
# Import name encoding
0x08 # the import name is 8 bytes
66 # f
64 # d
5f # _
77 # w
72 # r
69 # i
74 # t
65 # e
# Import description
0x00 # Function import
0x02 # Function type idx
```

#### Memory Section

```wat
(memory (;0;) 0)
```

compiles to:

```wasm
0x05 # Memory section id
0x03 # Memory section size - 3 bytes
0x01 # 1 memory
0x00 # Only min limits
0x01 # min size of 1 pages
```

#### Start Section

```wat
(start $_start)
```

compiles to:

```
0x08 # Start section header
0x01 # start section index - 1 bytes
0x02 # TODO: Figure out the index depends on other functions, i'm pretty sure it will be 2
```

#### Function Section

This doesn't have a wat equivelent but bassically it just says hey this function index has this type.

```wasm
0x03 # Function section id
0x02 # Section length - 2 bytes
0x02 # Function section count
# grow entry
0x01 # type index 1 (i32, i32) -> i32
# _start entry
0x00 # type index 0 () -> void
```

#### Code Section

This section comes from the compiled functions + some headers:

```
0x0A # code section ID
# Variable length goes here (unknown because _start is determined by program size)
0x02 # 2 functions
# grow entry
# _start entry
```

#### Functions

##### Grow

This function is responsible for safely ensuring that there is enough room for the read or write in memory.

```wat
(func $grow (type 1) ;; Returns (dataPtr: i32, heapEnd: i32) -> (heapEnd: i32)
  (if (i32.ge_u (local.get $0) (local.get $1)) ;; If dataPtr >= heapEnd
    (then
      (memory.grow (i32.const 1)) ;; Grow memory by 1 page (64KiB)
      (return
        (call $grow
          (local.get $0) 
          (i32.add (local.get $1) (i32.const 65536)) ;; Recursive call with new heapEnd
        )
      )
    )
    (else
      (local.get $1) ;; Return heapEnd if condition is not met
    )
  )
)
```

I'm going to omit the wasm for this it's just the compiled wat above, 
combined with the specific offset and type indexs for the program dependent 
on the above templates.

##### Start

The start section gets compiled first at the offset of the maximum possible length of the template as we don't know the size of the code section or _start section doto uleb128 being vlq we can't just perform a writeback.
```wat
(func $_start (type 0)
  (local i32 i32) ;; dataPtr, heapPtr
  ;; Code goes here
)
```

Compiled to:

```wasm
# Variable length goes here (unknown because _start is determined by program size)
0x01 # 1 type of local i32
0x02 # 2 i32 locals, dataPointer, heapEnd
0x7f # i32 type
# Function body goes here
0x0B # end opcode
```

### Instructions

Before incrementing or decrementing values we need to ensure the heap is the correct size with the below:
```wat
(local.set 2 (call $grow (local.get 0) (local.get 1)))
```

compiles to:
```wasm
# (local.set 2 (call $grow (local.get 0) (local.get 1)))
# local.get 0
0x20 # local.get opcode
0x00 # dataPtr index
# local.get 1
0x20 # local.get opcode
0x01 # heapEnd index
# call $grow
0x10 # call opcode
0x01 # grow index (TODO: this might move)
# local.set 2
0x21 # local.set opcode
0x01 # heapEnd index
```

#### Increment Value (+)

```wat
;; Insert grow here
(i32.store (local.get 0) (i32.add (i32.load (local.get 0)) (i32.const 1)))
```

Compiles to:

```wasm
# local.tee 0 - not sure about this vs a double local.get
0x22 # local.tee opcode
0x00 # dataPtr index
# i32.load
0x28 # i32.load opcode
0x00 # 0 align
0x00 # 0 offset
# i32.const 1
0x41 # i32.const
0x01 # value 1
# i32.add
0x6A # i32.add opcode
# i32.store
0x36 # i32.store opcode
0x00 # 0 align
0x00 # 0 offset
```



#### Decrement Value (-)

```wat
;; Insert grow here
(i32.store (local.get 0) (i32.sub (i32.load (local.get 0)) (i32.const 1)))
```

Compiles to:

```wasm
# local.tee 0 - not sure about this vs a double local.get
0x22 # local.tee opcode
0x00 # dataPtr index
# i32.load
0x28 # i32.load opcode
0x00 # 0 align
0x00 # 0 offset
# i32.const 1
0x41 # i32.const
0x01 # value 1
# i32.sub
0x6B # i32.sub opcode
# i32.store
0x36 # i32.store opcode
0x00 # 0 align
0x00 # 0 offset
```

#### Increment Pointer (>)

```wat
(local.set 0 (i32.add (local.get 0) (i32.const 1)))
```

compiles to:

```wasm
0x20 # local.get opcode
0x00 # dataPtr index
# i32.const 1
0x41 # i32.const
0x01 # value 1
# i32.add
0x6A # i32.add opcode
# i32.store
0x21 # local.set opcode
0x00 # dataPtr index
```

#### Decrement Pointer (<)

```wat
(local.sub 0 (i32.add (local.get 0) (i32.const 1)))
```

compiles to:

```wasm
0x22 # local.get opcode
0x00 # dataPtr index
# i32.const 1
0x41 # i32.const
0x01 # value 1
# i32.sub
0x6B # i32.sub opcode
# i32.store
0x21 # local.set opcode
0x00 # dataPtr index
```

#### Output

```wat
TODO: Using fd_write (i think we want to wrap in a function)
```

#### Input

```wat
TODO: Using fd_read (i think we want to wrap in a function)
```


### Loop

```wat
(loop # I still need to think through this one a little more, i.e not 100% sure no this just yet
  (call $grow (local.get 0) (local.get 1))
  (if (i32.neqz (i23.load (local.get 0))) ;; If data at dataPtr is not 0 run
    (then
      # loop body
      (br 0) # Jump back to loop
    )
  )
)
```

## Compilation Strategy
Compilation here is hard because I want todo it in brainf, I'll explain my current plan by showing a memory layout and operation order:

### Memory
```
# Program Counters
# TODO: What counters do I need????
# Input Program
# Code Section
```

### Order Of Operations
+ Setup program counters
  + instrTypeCount: i32 - This is for merging similar instructions
  + instrType: i32 - The last instruction we saw
  + outputPosition: I32 - Current position on the output stack
  + outputCodeSize: i32 - The size of the output function for write back
  + inputPosition: i32 - Current position in input
  + inputCount: i32 - The remaining count of input
+ Load raw program
+ Begin compilation
  + While parsing
    + When `instrType` doesn't equal current instr write instruction + the desired ammount
    + If it is equal increment the `instrType`
  + Write to code section at `TemplateMaxLength`
+ Write `_start` length before `_start` body
+ Write `_start` header
+ Write `grow`
+ Write `code` section length
+ Write template info

As we have limited memory we basically need to write the code section first and then write the 
headers back after otherwise we would have to shift all the code over which would not be a fun endeavour.


### Brainf Utilities

The plan for building the compiler will be to take advantage of my `brainf` 
grain toolkit combined with a generator that adds syntax sugar on top, 
we can then use `toString` to convert it over to brainf.

#### Parsing Logic

#### Writing Logic

#### Jumping Logic / goto mechanism

#### Conditional Logic

### Design

#### Utilities

##### LEB128

#### Parsing