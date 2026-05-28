# Single-file maintainer playground — delegates to examples/quickstart.exs.
quickstart = Path.expand("../examples/quickstart.exs", __DIR__)
Code.eval_file(quickstart)
