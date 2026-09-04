## Building

```sh
ansible-builder build --tag manageiq-ansible-ee
```

This will build `localhost/manageiq-ansible-ee:latest`

## Execution

With ansible-runner running the project directly:

```sh
ansible-runner run ./test/dir --ident result --playbook subdir/test_localhost.yml
```

With ansible-navigator running the project directly:

```sh
cd test/dir/project
ansible-navigator run subdir/test_localhost.yml --execution-environment-image localhost/manageiq-ansible-ee:latest --mode stdout --pull-policy missing
```

With ansible-runner via an execution environment:

```sh
docker run --rm -it -v./test/dir:/workspace localhost/manageiq-ansible-ee:latest ansible-runner run /workspace --ident result --playbook subdir/test_localhost.yml
```
