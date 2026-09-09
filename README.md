# container-ansible-ee

Container for the ManageIQ Ansible Execution Environment for use by Embedded Ansible.

## Building

```sh
bin/build
```

This will build a local container under `localhost/manageiq-ansible-ee:latest`

By default, this will build using the local architecture, but if you want to build for a different architecture, use the ARCH env var.

```sh
ARCH=amd64 bin/build
```

## Execution

With ansible-runner running the test project directly:

```sh
ansible-runner run ./test/dir --ident result --playbook subdir/test_localhost.yml
```

With ansible-navigator running the test project directly using the execution environment:

```sh
cd test/dir/project
ansible-navigator run subdir/test_localhost.yml --execution-environment-image localhost/manageiq-ansible-ee:latest --mode stdout --pull-policy missing
```

With the execution environment running the test project directly:

```sh
docker run --rm -it --platform=linux/amd64 -v./test/dir:/runner localhost/manageiq-ansible-ee:latest ansible-runner run /runner --ident result --playbook subdir/test_localhost.yml
```

## License

This project is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
