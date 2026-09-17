# container-ansible-ee

Container for the ManageIQ Ansible Execution Environment for use by Embedded Ansible.

## Building

```sh
bin/build
```

This will build a container tagged `docker.io/manageiq/ansible-ee` by default.

To override the tag, set the `TAG` env var:

```sh
TAG=localhost/my-ansible-ee bin/build
```

By default, this will build using the local architecture. To target a different architecture, use the `ARCH` env var:

```sh
ARCH=amd64 bin/build
```

## Usage

The container uses `/runner` as the ansible-runner [private data directory](https://ansible-runner.readthedocs.io/en/stable/intro/#runner-input-directory-hierarchy).
Its layout is:

```
/runner/
├── project/    ← playbooks, roles, vars  (mount your payload here)
├── inventory/  ← inventory files
├── env/        ← envvars, extravars, ssh_key, passwords, settings
├── artifacts/  ← job output written at runtime
└── .ansible/   ← Ansible controller scratch space (pre-created in the image)
```

Mount just the playbook directory to `/runner/project` and let ansible-runner manage the rest of
`/runner` at runtime:

```sh
docker run --rm -it --platform=linux/amd64 \
  -v /path/to/your/playbooks:/runner/project \
  docker.io/manageiq/ansible-ee:latest \
  ansible-runner run /runner --ident result --playbook subdir/playbook.yml
```

The `--playbook` path is relative to `/runner/project`. If the playbook is at the root of the
project directory, omit the subdirectory prefix.

To also capture artifacts (job events, stdout, rc, etc.) on the host, mount a full private data
directory (containing a `project/` subdirectory) to `/runner` instead:

```sh
docker run --rm -it --platform=linux/amd64 \
  -v /path/to/your/private-data-dir:/runner \
  docker.io/manageiq/ansible-ee:latest \
  ansible-runner run /runner --ident result --playbook subdir/playbook.yml
```

Artifacts will be written to `/path/to/your/private-data-dir/artifacts/result/` on the host.

## Testing

The `test/dir` directory is a ready-made ansible-runner private data directory. Its `project/`
subdirectory contains a test playbook nested under `subdir/` to exercise non-root playbook paths.

Mount only the project directory (no artifact capture):

```sh
docker run --rm -it --platform=linux/amd64 \
  -v ./test/dir/project:/runner/project \
  docker.io/manageiq/ansible-ee:latest \
  ansible-runner run /runner --ident result --playbook subdir/test_localhost.yml
```

Mount the full private data directory to capture artifacts under `test/dir/artifacts/`:

```sh
docker run --rm -it --platform=linux/amd64 \
  -v ./test/dir:/runner \
  docker.io/manageiq/ansible-ee:latest \
  ansible-runner run /runner --ident result --playbook subdir/test_localhost.yml
```

Without a container, using a local ansible-runner installation:

```sh
ansible-runner run ./test/dir --ident result --playbook subdir/test_localhost.yml
```

With ansible-navigator using the execution environment:

```sh
cd test/dir/project
ansible-navigator run subdir/test_localhost.yml \
  --execution-environment-image docker.io/manageiq/ansible-ee:latest \
  --mode stdout --pull-policy missing
```

## License

This project is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
