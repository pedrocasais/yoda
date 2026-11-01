# Test cases and oracles

A problem is evaluated by running a submission against its test cases. Each test case supplies an input and an expected output. A test case can also use an *oracle*, a checker program that validates the submission's output instead of requiring the exact expected output to be produced by the program itself.

## Test case fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | assigned by Yoda | Test case identifier. It is generated when the test case is created. |
| `input` | yes | Text sent to the submission's standard input. |
| `output` | yes | Expected standard output. |
| `is_sample` | yes | Flag that marks the test case as a sample. Yoda stores and returns it; it does not change how the test case is evaluated. |
| `oracle` | no | Oracle configuration. See [Oracles](#oracles). |

Test case management is restricted to administrators.

Problems can be marked with `is_draft` while they are being configured. Drafts are visible to administrators and judges, but hidden from participants. Participant submissions are rejected while a problem is a draft or has `is_force_closed` set to `true`; administrators and judges can still submit in either state. No submissions are allowed for any role once `close_at` has passed. Omit `is_draft` when creating a problem to keep the existing published-by-default behavior; set it to `false` when the problem is ready to publish.

## Managing test cases

| Action | Request |
|--------|---------|
| List the test cases of a problem | `GET /problems/{id}/testcases` |
| Add a test case to a problem | `POST /problems/{id}/testcases` |
| Update a test case | `PUT /testcases/{testcaseId}` |
| Delete a test case | `DELETE /testcases/{testcaseId}` |

Example request body for `POST /problems/{id}/testcases`:

```json
{
  "input": "3\n1 2 3\n",
  "output": "6\n",
  "is_sample": true
}
```

A problem needs at least one test case to be evaluated. `PUT` replaces `input`, `output`, and `is_sample`, and also replaces the oracle when the request includes one. See the [OpenAPI specification](../schemas/openapi.yaml) for the complete request and response formats.

## How a test case is evaluated

For each test case, YodaC runs the submission in a fresh container, as configured for its [language](languages.md), and sends `input` to its standard input. The container has no network access, uses the problem's memory limit, and has its working directory mounted read-only. The time limit is the problem's `time_limit_ms` converted to whole seconds (fractions are dropped), plus one second.

The result is chosen from the exit status and the output:

| Result | Condition |
|--------|-----------|
| `accepted` | The process exits with status `0` and its standard output equals `output` after removing leading and trailing whitespace. |
| `wrong_answer` | The process exits with status `0` but the output differs. |
| `time_limit_exceeded` | The time limit is reached. |
| `memory_limit_exceeded` | The process is killed with status `137`, typically because it exceeded the memory limit. |
| `segmentation_fault` | The process exits with status `139`. |
| `runtime_error` | The process exits with any other non-zero status. |

Comparison ignores whitespace only at the start and end of the output. Differences inside the output, such as spacing between values, still count as a mismatch.

The submission's result is `accepted` only if every test case is accepted. Otherwise it takes the status of the first failing test case. The score is the percentage of accepted test cases. If compilation fails, the result is `compile_error` and no test case is run.

Each test case result also reports its running time, the captured standard output and standard error, and the exit code.

### Protecting test case inputs

A submission could print the test input to its standard error to learn the data. To prevent this, when the standard error is at least 90% similar to the test case input, it is replaced with `*** Secret ***`. The result includes the similarity as `stderr_score`.

## Oracles

By default, the program's output must match `output`. This does not work when a problem accepts several correct answers, such as any valid ordering or a floating-point value within a tolerance. For those problems, a test case can use an oracle: an executable provided by the problem that checks the submission's output.

### How an oracle runs

The oracle runs in the same container as the submission, as the next step of a pipeline:

```text
<run command> < input | '<entrypoint>' '<arg1>' '<arg2>'
```

- The submission reads the test case `input` from standard input.
- The submission's standard output is piped to the oracle's standard input.
- The oracle's standard output and exit status become the test case's output and exit status, so the usual rules apply: the oracle should exit with status `0` and print what `output` expects (for example, `OK`) when the answer is valid, and fail otherwise.

Because the oracle does not receive the test case `input`, pass any data it needs through its `args`, or compare against values stored in the oracle itself.

### Oracle configuration

| Field | Required | Description |
|-------|----------|-------------|
| `entrypoint` | yes | File name of the oracle executable, as uploaded in the problem's object artifacts. |
| `args` | no | List of arguments passed to the oracle. |

```json
{
  "input": "5\n",
  "output": "OK",
  "is_sample": false,
  "oracle": {
    "entrypoint": "check_sum",
    "args": ["--tolerance", "0.001"]
  }
}
```

In this example the submission is accepted if `check_sum --tolerance 0.001`, reading the submission's output, exits with `0` and prints `OK`.

### Providing the oracle executable

The oracle is uploaded as an *object artifact* of the problem.

1. Base64-encode the executable.
2. Add it to the problem's `object_artifacts` with `PUT /admin/problems/{id}`. The `filename` must match the oracle's `entrypoint`:

   ```json
   {
     "object_artifacts": [
       {
         "filename": "check_sum",
         "content": "<base64-encoded executable>"
       }
     ]
   }
   ```

3. Add test cases that reference it in their `oracle` field.

Yoda stores each artifact by its SHA-256 hash, and returns the hash and size instead of the content. When a test case runs, the artifacts are mounted read-only in `/usr/local/bin`, so the `entrypoint` can be invoked by its file name.

### Requirements and limitations

- The oracle runs inside the language's container image, so it must be able to run there. A statically linked binary works in any image; a script needs its interpreter (for example, Python in a Python image).
- The `entrypoint` and each argument are wrapped in single quotes in the command, so they must not contain single quote characters.
- The oracle is the last step of the pipeline, and the exit status that decides the result is the oracle's, not the submission's. A submission that crashes after printing output may still be accepted if the oracle accepts that output. Make the oracle reject incomplete or invalid output.
- The oracle runs under the same time and memory limits as the submission.

## Writing a good set of test cases

- Include small samples and edge cases, such as minimum and maximum input sizes, empty or single-element inputs, and repeated values.
- Include tests that stress the time and memory limits.
- Make the expected `output` match the output format described by the problem, ending with a newline if the problem requires it.
- Use an oracle whenever the answer is not unique.
