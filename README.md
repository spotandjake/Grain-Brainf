# Grain-brainf

A brainf parser and interpreter written in grain using a mostly functional style.

To run the hello world use:
```bash
grain test.gr
```


## Dependencies
Currently this works with any version of grain between `v0.6.6` and `v0.7.0` preview releases.

If you would like to be able to use the task system install [taskfile](https://taskfile.dev/) 
however this isn't a neccessaity you can run the bash commands manually.

## Development

* `task` - Runs the `test.gr` file
* `task doc` - Generates the graindoc
* `task format` - Runs the formatter
* `task clean` - Cleans all output files