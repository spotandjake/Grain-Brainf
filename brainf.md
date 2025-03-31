---
title: BrainF
---

Grain implementation of Brainf.

This implementation is not optimized for speed but rather written in a functional style.

## Types

Type declarations included in the BrainF module.

### BrainF.**Instruction**

```grain
enum Instruction {
  Loop(List<Instruction>),
  IncrPtr,
  DecrPtr,
  IncrVal,
  DecVal,
  OutputVal,
  InputVal,
}
```

Represents a Brainf instruction.

Variants:

```grain
Loop(List<Instruction>)
```

Represents a brainf loop, [<instructions>]

```grain
IncrPtr
```

Represents a brainf pointer increment, >

```grain
DecrPtr
```

Represents a brainf pointer decrement, <

```grain
IncrVal
```

Represents a brainf value increment, +

```grain
DecVal
```

Represents a brainf value decrement, -

```grain
OutputVal
```

Represents a brainf output, .

```grain
InputVal
```

Represents a brainf input, ,

## Values

Functions and constants included in the BrainF module.

### BrainF.**fromString**

```grain
fromString : (str: String) => List<Instruction>
```

Converts a string to a Brainf program.

Parameters:

|param|type|description|
|-----|----|-----------|
|`str`|`String`|The string to convert|

Returns:

|type|description|
|----|-----------|
|`List<Instruction>`|The Brainf program|

### BrainF.**toString**

```grain
toString : (program: List<Instruction>) => String
```

Converts a Brainf program to a string.

Parameters:

|param|type|description|
|-----|----|-----------|
|`program`|`List<Instruction>`|The Brainf program to convert|

Returns:

|type|description|
|----|-----------|
|`String`|The string representation of the program|

### BrainF.**interpret**

```grain
interpret : (program: List<Instruction>) => (Buffer.Buffer, Number)
```

Interprets a Brainf program.

Note: Currently does not support input instructions.

This function will print the output of the program to the console.

Parameters:

|param|type|description|
|-----|----|-----------|
|`program`|`List<Instruction>`|The Brainf program to interpret|

Returns:

|type|description|
|----|-----------|
|`(Buffer.Buffer, Number)`|The final state of the program, in the form of `(memory, dataPointer)`|

