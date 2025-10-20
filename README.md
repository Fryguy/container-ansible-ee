With ansible-runner:

```sh
ansible-runner run ~/dev/test/ansible-ee/dir --ident result --playbook subdir/test_localhost.yml
```

With ansible-navigator:

```sh
cd dir/project
ansible-navigator run subdir/test_localhost.yml --execution-environment-image ghcr.io/ansible-community/community-ee-base:latest --mode stdout --pull-policy missing
```

With ansible-runner via an execution environment:

```sh
docker run --rm -it -v./dir:/workspace ghcr.io/ansible-community/community-ee-base:latest ansible-runner run /workspace --ident result --playbook subdir/test_localhost.yml
```
